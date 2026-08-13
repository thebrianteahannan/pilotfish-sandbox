package com.pilotfish.eip.modules.fhir;

import com.pilotfish.eip.EIPException;
import com.pilotfish.eip.TransactionAttributesMetadata;
import com.pilotfish.eip.TransactionData;
import com.pilotfish.eip.extend.AbstractProcessor;
import com.pilotfish.eip.extend.Category;
import com.pilotfish.utils.ccp.ConfigurationDescriptor;
import com.pilotfish.utils.ccp.StringConfigurationItem;
import org.apache.commons.lang3.StringUtils;

import java.io.ByteArrayInputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Phase 6 demo Bulk Data Access: system-level async $export.
 * Modes based on com.pilotfish.ResourceName: $export | $export-status | $export-file.
 */
public class FhirBulkExportProcessor extends AbstractProcessor {

    public static final String JDBC_URL_TAG = "JdbcUrl";
    public static final String JDBC_USER_TAG = "JdbcUser";
    public static final String JDBC_PASSWORD_TAG = "JdbcPassword";
    public static final String EXPORT_DIR_TAG = "ExportDirectory";
    public static final String PUBLIC_BASE_TAG = "PublicFhirBase";

    private static final ExecutorService WORKERS = Executors.newCachedThreadPool(r -> {
        Thread t = new Thread(r, "fhir-bulk-export");
        t.setDaemon(true);
        return t;
    });

    @Override
    public String getType() {
        return "FHIR Bulk Export";
    }

    @Override
    public String getDescription() {
        return "System-level FHIR Bulk $export (async NDJSON) for the demo SQL store.";
    }

    @Override
    public List<Category> getCategories() {
        List<Category> c = new ArrayList<>();
        c.add(Category.HEALTHCARE);
        c.add(Category.DATABASE);
        return c;
    }

    @Override
    protected ConfigurationDescriptor getConfigurationDescriptor() {
        ConfigurationDescriptor d = new ConfigurationDescriptor(true);
        d.addConfigurationItem(new StringConfigurationItem(
                "JDBC URL", JDBC_URL_TAG, "$$sqlserver.url", "SQL Server JDBC URL"));
        d.addConfigurationItem(new StringConfigurationItem(
                "JDBC User", JDBC_USER_TAG, "$$sqlserver.username", "SQL user"));
        d.addConfigurationItem(new StringConfigurationItem(
                "JDBC Password", JDBC_PASSWORD_TAG, "$$sqlserver.password", "SQL password"));
        d.addConfigurationItem(new StringConfigurationItem(
                "Export Directory", EXPORT_DIR_TAG, "/opt/pilotfish/output/bulk-export",
                "Where NDJSON + status files are written"));
        d.addConfigurationItem(new StringConfigurationItem(
                "Public FHIR Base", PUBLIC_BASE_TAG, "http://localhost:8110/eip/rest/fhir",
                "Used for Content-Location and output URLs"));
        registerTransactionAttribute("fhir.BulkHttpStatus", "HTTP status for bulk response", String.class,
                TransactionAttributesMetadata.PROCESSOR);
        registerTransactionAttribute("fhir.BulkContentLocation", "Content-Location header value", String.class,
                TransactionAttributesMetadata.PROCESSOR);
        registerTransactionAttribute("fhir.BulkBody", "Response body JSON", String.class,
                TransactionAttributesMetadata.PROCESSOR);
        return d;
    }

    @Override
    public TransactionData processData(TransactionData data) throws EIPException {
        try {
            String resource = str(data, "com.pilotfish.ResourceName");
            if ("$export".equals(resource)) {
                return kickoff(data);
            }
            if ("$export-status".equals(resource)) {
                return status(data);
            }
            if ("$export-file".equals(resource)) {
                return download(data);
            }
            setBody(data, 400, null, oo("invalid", "Bulk processor invoked for unexpected resource: " + resource));
            return data;
        } catch (Exception e) {
            throw new EIPException("Bulk export failed: " + e.getMessage(), e);
        }
    }

    private TransactionData kickoff(TransactionData data) throws Exception {
        String method = str(data, "com.pilotfish.HttpMethodName");
        if (!"GET".equalsIgnoreCase(method) && !"POST".equalsIgnoreCase(method)) {
            setBody(data, 405, null, oo("not-supported", "Use GET or POST for $export."));
            return data;
        }
        String typesParam = firstNonBlank(
                str(data, "com.pilotfish.http.parameter._type"),
                str(data, "com.pilotfish.http.parameter.type"));
        Set<String> types = parseTypes(typesParam);
        String jobId = UUID.randomUUID().toString();
        Path jobDir = Path.of(cfg(data, EXPORT_DIR_TAG, "/opt/pilotfish/output/bulk-export"), jobId);
        Files.createDirectories(jobDir);
        String publicBase = cfg(data, PUBLIC_BASE_TAG, "http://localhost:8110/eip/rest/fhir").replaceAll("/+$", "");
        String requestUrl = publicBase + "/$export" + (StringUtils.isNotBlank(typesParam) ? "?_type=" + typesParam : "");
        String contentLocation = publicBase + "/$export-status/" + jobId;

        try (Connection c = connect(data)) {
            try (PreparedStatement ps = c.prepareStatement(
                    "INSERT INTO dbo.FhirExportJobs (JobId, Status, RequestUrl, TypesCsv) VALUES (?,?,?,?)")) {
                ps.setString(1, jobId);
                ps.setString(2, "accepted");
                ps.setString(3, requestUrl);
                ps.setString(4, types.isEmpty() ? null : String.join(",", types));
                ps.executeUpdate();
            }
        }

        writeStatusFile(jobDir, "accepted", requestUrl, Instant.now().toString(), null, null);

        String jdbcUrl = cfg(data, JDBC_URL_TAG, "");
        String user = cfg(data, JDBC_USER_TAG, "");
        String pass = cfg(data, JDBC_PASSWORD_TAG, "");
        WORKERS.submit(() -> runExport(jobId, jobDir, types, requestUrl, publicBase, jdbcUrl, user, pass));

        data.getAttributes().setAttribute("fhir.BulkHttpStatus", "202");
        data.getAttributes().setAttribute("fhir.BulkContentLocation", contentLocation);
        data.getAttributes().setAttribute("com.pilotfish.HTTPResponseCode", "202");
        // Empty body for 202 Accepted is OK; some clients want a small JSON.
        String body = "{\"resourceType\":\"OperationOutcome\",\"issue\":[{\"severity\":\"information\","
                + "\"code\":\"informational\",\"diagnostics\":\"Bulk export accepted. Poll Content-Location.\"}]}";
        data.getAttributes().setAttribute("fhir.BulkBody", body);
        setBody(data, 202, contentLocation, body);
        return data;
    }

    private TransactionData status(TransactionData data) throws Exception {
        String jobId = str(data, "com.pilotfish.ResourceID");
        if (StringUtils.isBlank(jobId)) {
            setBody(data, 400, null, oo("required", "Missing job id in /$export-status/{jobId}."));
            return data;
        }
        Path statusFile = Path.of(cfg(data, EXPORT_DIR_TAG, "/opt/pilotfish/output/bulk-export"), jobId, "status.json");
        if (!Files.isRegularFile(statusFile)) {
            // fallback SQL
            try (Connection c = connect(data);
                 PreparedStatement ps = c.prepareStatement(
                         "SELECT Status, OutputManifest, ErrorText FROM dbo.FhirExportJobs WHERE JobId=?")) {
                ps.setString(1, jobId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        setBody(data, 404, null, oo("not-found", "Unknown export job."));
                        return data;
                    }
                    String st = rs.getString(1);
                    if ("completed".equalsIgnoreCase(st)) {
                        setBody(data, 200, null, rs.getString(2));
                    } else if ("error".equalsIgnoreCase(st)) {
                        setBody(data, 500, null, oo("exception", StringUtils.defaultString(rs.getString(3), "export failed")));
                    } else {
                        data.getAttributes().setAttribute("com.pilotfish.HTTPResponseCode", "202");
                        data.getAttributes().setAttribute("fhir.BulkHttpStatus", "202");
                        setBody(data, 202, null, "{\"status\":\"" + st + "\"}");
                    }
                    return data;
                }
            }
        }
        String json = Files.readString(statusFile, StandardCharsets.UTF_8);
        if (json.contains("\"status\":\"completed\"") || json.contains("\"output\"")) {
            // completed manifest has output array
            if (json.contains("\"output\"")) {
                setBody(data, 200, null, json);
            } else {
                data.getAttributes().setAttribute("com.pilotfish.HTTPResponseCode", "202");
                setBody(data, 202, null, json);
            }
        } else if (json.contains("\"status\":\"error\"")) {
            setBody(data, 500, null, json);
        } else {
            data.getAttributes().setAttribute("com.pilotfish.HTTPResponseCode", "202");
            setBody(data, 202, null, json);
        }
        return data;
    }

    private TransactionData download(TransactionData data) throws Exception {
        String jobId = str(data, "com.pilotfish.ResourceID");
        String type = firstNonBlank(
                str(data, "com.pilotfish.http.parameter._type"),
                str(data, "com.pilotfish.http.parameter.type"),
                "Patient");
        if (StringUtils.isBlank(jobId)) {
            setBody(data, 400, null, oo("required", "Missing job id."));
            return data;
        }
        Path file = Path.of(cfg(data, EXPORT_DIR_TAG, "/opt/pilotfish/output/bulk-export"),
                jobId, type + ".ndjson");
        if (!Files.isRegularFile(file)) {
            setBody(data, 404, null, oo("not-found", "Export file not found for type " + type));
            return data;
        }
        byte[] bytes = Files.readAllBytes(file);
        data.setDataStream(new ByteArrayInputStream(bytes));
        data.getAttributes().setAttribute("com.pilotfish.HTTPResponseCode", "200");
        data.getAttributes().setAttribute("fhir.BulkHttpStatus", "200");
        data.getAttributes().setAttribute("fhir.BulkBody", new String(bytes, StandardCharsets.UTF_8));
        return data;
    }

    private void runExport(String jobId, Path jobDir, Set<String> types, String requestUrl,
                           String publicBase, String jdbcUrl, String user, String pass) {
        try {
            updateJob(jdbcUrl, user, pass, jobId, "in-progress", null, null);
            writeStatusFile(jobDir, "in-progress", requestUrl, Instant.now().toString(), null, null);

            Map<String, Integer> counts = new LinkedHashMap<>();
            try (Connection c = DriverManager.getConnection(jdbcUrl, user, pass)) {
                String sql = "SELECT ResourceType, RawFhir FROM dbo.FhirResources WHERE DeletedAt IS NULL";
                if (!types.isEmpty()) {
                    sql += " AND ResourceType IN (" + placeholders(types.size()) + ")";
                }
                sql += " ORDER BY ResourceType, ResourceId";
                try (PreparedStatement ps = c.prepareStatement(sql)) {
                    int i = 1;
                    for (String t : types) {
                        ps.setString(i++, t);
                    }
                    Map<String, Writer> writers = new LinkedHashMap<>();
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            String type = rs.getString(1);
                            String raw = rs.getString(2);
                            if (raw == null || raw.isBlank()) {
                                continue;
                            }
                            Writer w = writers.get(type);
                            if (w == null) {
                                Path out = jobDir.resolve(type + ".ndjson");
                                w = new OutputStreamWriter(Files.newOutputStream(out), StandardCharsets.UTF_8);
                                writers.put(type, w);
                                counts.put(type, 0);
                            }
                            String line = raw.replace("\r", " ").replace("\n", " ").trim();
                            w.write(line);
                            w.write('\n');
                            counts.put(type, counts.get(type) + 1);
                        }
                    } finally {
                        for (Writer w : writers.values()) {
                            w.close();
                        }
                    }
                }
            }

            List<String> outputEntries = new ArrayList<>();
            for (Map.Entry<String, Integer> e : counts.entrySet()) {
                String url = publicBase + "/$export-file/" + jobId + "?_type=" + e.getKey();
                outputEntries.add("{\"type\":\"" + e.getKey() + "\",\"url\":\"" + url + "\",\"count\":" + e.getValue() + "}");
            }
            String transactionTime = Instant.now().toString();
            String manifest = "{"
                    + "\"transactionTime\":\"" + transactionTime + "\","
                    + "\"request\":\"" + escape(requestUrl) + "\","
                    + "\"requiresAccessToken\":true,"
                    + "\"output\":[" + String.join(",", outputEntries) + "],"
                    + "\"error\":[]"
                    + "}";
            Files.writeString(jobDir.resolve("manifest.json"), manifest, StandardCharsets.UTF_8);
            writeStatusFile(jobDir, "completed", requestUrl, transactionTime, manifest, null);
            updateJob(jdbcUrl, user, pass, jobId, "completed", manifest, null);
        } catch (Exception ex) {
            try {
                writeStatusFile(jobDir, "error", requestUrl, Instant.now().toString(), null, ex.getMessage());
                updateJob(jdbcUrl, user, pass, jobId, "error", null, ex.getMessage());
            } catch (Exception ignored) {
                // best effort
            }
        }
    }

    private static void writeStatusFile(Path jobDir, String status, String requestUrl, String txTime,
                                        String manifestOrNull, String error) throws Exception {
        if (manifestOrNull != null && "completed".equals(status)) {
            Files.writeString(jobDir.resolve("status.json"), manifestOrNull, StandardCharsets.UTF_8);
            return;
        }
        StringBuilder sb = new StringBuilder();
        sb.append("{\"status\":\"").append(status).append("\"");
        sb.append(",\"request\":\"").append(escape(requestUrl)).append("\"");
        sb.append(",\"transactionTime\":\"").append(txTime).append("\"");
        if (error != null) {
            sb.append(",\"error\":\"").append(escape(error)).append("\"");
        }
        sb.append("}");
        Files.writeString(jobDir.resolve("status.json"), sb.toString(), StandardCharsets.UTF_8);
    }

    private static void updateJob(String jdbcUrl, String user, String pass, String jobId,
                                  String status, String manifest, String error) throws Exception {
        try (Connection c = DriverManager.getConnection(jdbcUrl, user, pass);
             PreparedStatement ps = c.prepareStatement(
                     "UPDATE dbo.FhirExportJobs SET Status=?, OutputManifest=?, ErrorText=?, UpdatedAt=SYSUTCDATETIME(), "
                             + "CompletedAt=CASE WHEN ? IN ('completed','error') THEN SYSUTCDATETIME() ELSE CompletedAt END WHERE JobId=?")) {
            ps.setString(1, status);
            ps.setString(2, manifest);
            ps.setString(3, error);
            ps.setString(4, status);
            ps.setString(5, jobId);
            ps.executeUpdate();
        }
    }

    private Connection connect(TransactionData data) throws Exception {
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        return DriverManager.getConnection(
                cfg(data, JDBC_URL_TAG, ""),
                cfg(data, JDBC_USER_TAG, ""),
                cfg(data, JDBC_PASSWORD_TAG, ""));
    }

    private void setBody(TransactionData data, int status, String contentLocation, String body) {
        data.getAttributes().setAttribute("fhir.BulkHttpStatus", Integer.toString(status));
        data.getAttributes().setAttribute("com.pilotfish.HTTPResponseCode", Integer.toString(status));
        if (contentLocation != null) {
            data.getAttributes().setAttribute("fhir.BulkContentLocation", contentLocation);
        }
        data.getAttributes().setAttribute("fhir.BulkBody", body);
        data.setDataStream(new ByteArrayInputStream(body.getBytes(StandardCharsets.UTF_8)));
    }

    private static String oo(String code, String diagnostics) {
        return "{\"resourceType\":\"OperationOutcome\",\"issue\":[{\"severity\":\"error\",\"code\":\""
                + code + "\",\"diagnostics\":\"" + escape(diagnostics) + "\"}]}";
    }

    private static Set<String> parseTypes(String csv) {
        Set<String> out = new LinkedHashSet<>();
        if (StringUtils.isBlank(csv)) {
            return out;
        }
        for (String p : csv.split(",")) {
            String t = p.trim();
            if (!t.isEmpty()) {
                out.add(t);
            }
        }
        return out;
    }

    private static String placeholders(int n) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < n; i++) {
            if (i > 0) {
                sb.append(',');
            }
            sb.append('?');
        }
        return sb.toString();
    }

    private static String escape(String s) {
        if (s == null) {
            return "";
        }
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static String firstNonBlank(String... vals) {
        for (String v : vals) {
            if (StringUtils.isNotBlank(v)) {
                return v;
            }
        }
        return null;
    }

    private String cfg(TransactionData data, String tag, String def) {
        try {
            String s = getConfigurationManager().getStringValue(tag, data);
            return StringUtils.isBlank(s) ? def : s.trim();
        } catch (Exception e) {
            return def;
        }
    }

    private static String str(TransactionData data, String name) {
        Object v = data.getAttributes().getAttribute(name);
        return v == null ? null : v.toString();
    }
}
