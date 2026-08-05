package com.pilotfish.eip.modules.oci;

import com.oracle.bmc.Region;
import com.oracle.bmc.auth.SimpleAuthenticationDetailsProvider;
import com.oracle.bmc.auth.StringPrivateKeySupplier;
import com.oracle.bmc.model.BmcException;
import com.oracle.bmc.objectstorage.ObjectStorageClient;
import com.oracle.bmc.objectstorage.requests.PutObjectRequest;
import com.oracle.bmc.objectstorage.responses.PutObjectResponse;
import com.pilotfish.eip.EIPException;
import com.pilotfish.eip.TransactionAttributesMetadata;
import com.pilotfish.eip.TransactionData;
import com.pilotfish.eip.extend.AbstractTransport;
import com.pilotfish.eip.extend.Category;
import com.pilotfish.eip.extend.ConfigurationTab;
import com.pilotfish.utils.ccp.ConfigurationDescriptor;
import com.pilotfish.utils.ccp.MultipleChoiceConfigurationItem;
import com.pilotfish.utils.ccp.PathConfigurationItem;
import com.pilotfish.utils.ccp.StringConfigurationItem;
import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.StringUtils;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Custom PilotFish eiPlatform Transport that performs OCI Object Storage PutObject
 * via the official OCI Java SDK. Set {@code OciEndpoint} to {@code http://floci-oci:4599}
 * for the local floci-oci emulator.
 */
public class OciObjectStorageTransport extends AbstractTransport {

    public static final String REGION_TAG = "OciRegion";
    public static final String NAMESPACE_TAG = "OciNamespace";
    public static final String BUCKET_TAG = "OciBucket";
    public static final String OBJECT_NAME_TAG = "OciObjectName";
    public static final String CONTENT_TYPE_TAG = "OciContentType";
    public static final String ENDPOINT_TAG = "OciEndpoint";
    public static final String AUTH_MODE_TAG = "OciAuthMode";
    public static final String TENANCY_TAG = "OciTenancyOcid";
    public static final String USER_TAG = "OciUserOcid";
    public static final String FINGERPRINT_TAG = "OciFingerprint";
    public static final String PRIVATE_KEY_PATH_TAG = "OciPrivateKeyPath";
    public static final String PRIVATE_KEY_PEM_TAG = "OciPrivateKeyPem";

    public static final String ATTR_REQUEST_ID = "com.pilotfish.oci.requestId";
    public static final String ATTR_ETAG = "com.pilotfish.oci.eTag";
    public static final String ATTR_OBJECT_NAME = "com.pilotfish.oci.objectName";
    public static final String ATTR_BUCKET = "com.pilotfish.oci.bucket";
    public static final String ATTR_NAMESPACE = "com.pilotfish.oci.namespace";

    @Override
    public String getType() {
        return "OCI Object Storage";
    }

    @Override
    public String getDescription() {
        return "Put objects to Oracle Cloud Infrastructure Object Storage (signed PutObject via OCI Java SDK).";
    }

    @Override
    public List<Category> getCategories() {
        List<Category> categories = new ArrayList<>();
        categories.add(Category.WEB);
        categories.add(Category.SPECIAL_PROTOCOL);
        return categories;
    }

    @Override
    protected ConfigurationDescriptor getConfigurationDescriptor() {
        ConfigurationDescriptor d = new ConfigurationDescriptor(true);
        d.addConfigurationItem(new StringConfigurationItem(
                "Region", REGION_TAG, "us-ashburn-1", "OCI region identifier (e.g. us-ashburn-1)", true));
        d.addConfigurationItem(new StringConfigurationItem(
                "Namespace", NAMESPACE_TAG, "", "Object Storage namespace", true));
        d.addConfigurationItem(new StringConfigurationItem(
                "Bucket", BUCKET_TAG, "", "Target bucket name", true));
        d.addConfigurationItem(new StringConfigurationItem(
                "Object Name", OBJECT_NAME_TAG, "", "Object name (OGNL supported)", true));
        d.addConfigurationItem(new StringConfigurationItem(
                "Content Type", CONTENT_TYPE_TAG, "application/json",
                "MIME type for PutObject", ConfigurationTab.ADVANCED));
        d.addConfigurationItem(new StringConfigurationItem(
                "Service Endpoint Override", ENDPOINT_TAG, "",
                "Optional endpoint override for emulators (e.g. http://floci-oci:4599). Leave blank for real OCI.",
                ConfigurationTab.ADVANCED));

        d.addConfigurationItem(new MultipleChoiceConfigurationItem(
                "Auth Mode", AUTH_MODE_TAG, Arrays.asList("API Key"), "API Key",
                "Authentication mode (API Key supported in this demo module)", ConfigurationTab.CREDENTIALS));
        d.addConfigurationItem(new StringConfigurationItem(
                "Tenancy OCID", TENANCY_TAG, "", "Tenancy OCID used to sign requests",
                ConfigurationTab.CREDENTIALS, true));
        d.addConfigurationItem(new StringConfigurationItem(
                "User OCID", USER_TAG, "", "User OCID used to sign requests",
                ConfigurationTab.CREDENTIALS, true));
        d.addConfigurationItem(new StringConfigurationItem(
                "Fingerprint", FINGERPRINT_TAG, "", "API key fingerprint",
                ConfigurationTab.CREDENTIALS, true));
        d.addConfigurationItem(new PathConfigurationItem(
                this, "Private Key File", PRIVATE_KEY_PATH_TAG, "",
                "Path to PEM private key file (preferred over inline PEM)",
                ConfigurationTab.CREDENTIALS, false));
        d.addConfigurationItem(new StringConfigurationItem(
                "Private Key PEM (inline)", PRIVATE_KEY_PEM_TAG, "",
                "Optional inline PEM if Private Key File is empty (demo/dev only)",
                ConfigurationTab.CREDENTIALS));

        registerTransactionAttribute(ATTR_REQUEST_ID, "OCI opc-request-id from PutObject", String.class, TransactionAttributesMetadata.LISTENER);
        registerTransactionAttribute(ATTR_ETAG, "ETag from PutObject", String.class, TransactionAttributesMetadata.LISTENER);
        registerTransactionAttribute(ATTR_OBJECT_NAME, "Object name written", String.class, TransactionAttributesMetadata.LISTENER);
        registerTransactionAttribute(ATTR_BUCKET, "Bucket written", String.class, TransactionAttributesMetadata.LISTENER);
        registerTransactionAttribute(ATTR_NAMESPACE, "Namespace written", String.class, TransactionAttributesMetadata.LISTENER);

        return d;
    }

    @Override
    protected void executeTransport(TransactionData data) throws EIPException {
        String regionId = required(manager.getStringValue(REGION_TAG, data), "Region");
        String namespace = required(manager.getStringValue(NAMESPACE_TAG, data), "Namespace");
        String bucket = required(manager.getStringValue(BUCKET_TAG, data), "Bucket");
        String objectName = required(manager.getStringValue(OBJECT_NAME_TAG, data), "Object Name");
        String contentType = manager.getStringValue(CONTENT_TYPE_TAG, data);
        if (StringUtils.isBlank(contentType)) {
            contentType = "application/octet-stream";
        }
        String endpoint = manager.getStringValue(ENDPOINT_TAG, data);

        String tenancy = required(manager.getStringValue(TENANCY_TAG, data), "Tenancy OCID");
        String user = required(manager.getStringValue(USER_TAG, data), "User OCID");
        String fingerprint = required(manager.getStringValue(FINGERPRINT_TAG, data), "Fingerprint");
        String pem = resolvePrivateKeyPem(data);

        byte[] body;
        try {
            body = IOUtils.toByteArray(data.getDataStream());
        } catch (IOException e) {
            throw new EIPException("Unable to read transaction data for OCI PutObject", e);
        }

        SimpleAuthenticationDetailsProvider auth = SimpleAuthenticationDetailsProvider.builder()
                .tenantId(tenancy)
                .userId(user)
                .fingerprint(fingerprint)
                .privateKeySupplier(new StringPrivateKeySupplier(pem))
                .region(Region.fromRegionId(regionId))
                .build();

        ObjectStorageClient client = ObjectStorageClient.builder().build(auth);
        if (StringUtils.isNotBlank(endpoint)) {
            client.setEndpoint(endpoint.trim());
        }

        try (InputStream in = new ByteArrayInputStream(body)) {
            PutObjectRequest request = PutObjectRequest.builder()
                    .namespaceName(namespace)
                    .bucketName(bucket)
                    .objectName(objectName)
                    .contentLength((long) body.length)
                    .contentType(contentType)
                    .putObjectBody(in)
                    .build();

            PutObjectResponse response = client.putObject(request);
            data.getAttributes().setAttribute(ATTR_REQUEST_ID, response.getOpcRequestId());
            data.getAttributes().setAttribute(ATTR_ETAG, response.getETag());
            data.getAttributes().setAttribute(ATTR_OBJECT_NAME, objectName);
            data.getAttributes().setAttribute(ATTR_BUCKET, bucket);
            data.getAttributes().setAttribute(ATTR_NAMESPACE, namespace);
        } catch (BmcException e) {
            throw new EIPException(
                    "OCI PutObject failed (" + e.getStatusCode() + "): " + e.getMessage(), e);
        } catch (Exception e) {
            throw new EIPException("OCI PutObject failed", e);
        } finally {
            try {
                client.close();
            } catch (Exception ignored) {
                // ignore close failures
            }
        }
    }

    private String resolvePrivateKeyPem(TransactionData data) throws EIPException {
        String inline = manager.getStringValue(PRIVATE_KEY_PEM_TAG, data);
        if (StringUtils.isNotBlank(inline)) {
            return inline.replace("\\n", "\n");
        }
        String path = manager.getStringValue(PRIVATE_KEY_PATH_TAG, data);
        if (StringUtils.isBlank(path)) {
            throw new EIPException("Configure Private Key File or Private Key PEM (inline)");
        }
        try {
            return Files.readString(Path.of(path), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new EIPException("Unable to read OCI private key file: " + path, e);
        }
    }

    private static String required(String value, String label) throws EIPException {
        if (StringUtils.isBlank(value)) {
            throw new EIPException(label + " is required for OciObjectStorageTransport");
        }
        return value.trim();
    }
}
