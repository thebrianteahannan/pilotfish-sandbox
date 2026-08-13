package com.pilotfish.eip.modules.fhir;

import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.context.support.DefaultProfileValidationSupport;
import ca.uhn.fhir.parser.IParser;
import ca.uhn.fhir.validation.FhirValidator;
import ca.uhn.fhir.validation.ResultSeverityEnum;
import ca.uhn.fhir.validation.SingleValidationMessage;
import ca.uhn.fhir.validation.ValidationResult;
import com.pilotfish.eip.EIPException;
import com.pilotfish.eip.TransactionAttributesMetadata;
import com.pilotfish.eip.TransactionData;
import com.pilotfish.eip.extend.AbstractProcessor;
import com.pilotfish.eip.extend.Category;
import com.pilotfish.utils.ccp.BooleanConfigurationItem;
import com.pilotfish.utils.ccp.ConfigurationDescriptor;
import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.StringUtils;
import org.hl7.fhir.common.hapi.validation.support.CommonCodeSystemsTerminologyService;
import org.hl7.fhir.common.hapi.validation.support.InMemoryTerminologyServerValidationSupport;
import org.hl7.fhir.common.hapi.validation.support.SnapshotGeneratingValidationSupport;
import org.hl7.fhir.common.hapi.validation.support.ValidationSupportChain;
import org.hl7.fhir.common.hapi.validation.validator.FhirInstanceValidator;
import org.hl7.fhir.instance.model.api.IBaseResource;
import org.hl7.fhir.r4.model.CodeableConcept;
import org.hl7.fhir.r4.model.OperationOutcome;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * Phase 4: HAPI FHIR instance validator for FHIR R4 create/update (and Bundle) payloads.
 * Soft validation — sets attributes and lets the route return HTTP 400 OperationOutcome.
 */
public class FhirProfileValidationProcessor extends AbstractProcessor {

    public static final String ATTR_PROFILE_STATUS = "fhir.ProfileValidationStatus";
    public static final String ATTR_VALIDATION_OUTCOME = "fhir.ValidationOutcome";
    public static final String ATTR_VALIDATION_STATUS = "fhir.ValidationStatus";
    public static final String ATTR_RAW_BODY = "fhir.RawBody";

    private static final Object LOCK = new Object();
    private static volatile FhirContext FHIR_CTX;
    private static volatile FhirValidator VALIDATOR;
    private static volatile IParser JSON_PARSER;

    @Override
    public String getType() {
        return "FHIR Profile Validation";
    }

    @Override
    public String getDescription() {
        return "Validate FHIR R4 JSON against base StructureDefinitions via HAPI FHIR (errors/fatal fail).";
    }

    @Override
    public List<Category> getCategories() {
        List<Category> categories = new ArrayList<>();
        categories.add(Category.HEALTHCARE);
        categories.add(Category.VALIDATION);
        categories.add(Category.TRANSFORMATION);
        return categories;
    }

    @Override
    protected ConfigurationDescriptor getConfigurationDescriptor() {
        ConfigurationDescriptor d = new ConfigurationDescriptor(true);
        d.addConfigurationItem(new BooleanConfigurationItem(
                "Execute Processor", "ExecuteProcessor", true,
                "Run HAPI FHIR profile validation for POST/PUT bodies"));
        registerTransactionAttribute(ATTR_PROFILE_STATUS, "PASS / FAIL / SKIP", String.class,
                TransactionAttributesMetadata.PROCESSOR);
        registerTransactionAttribute(ATTR_VALIDATION_OUTCOME, "OperationOutcome JSON on failure", String.class,
                TransactionAttributesMetadata.PROCESSOR);
        return d;
    }

    @Override
    public void systemStartup() {
        // Eager warm to avoid first-request multi-second hit.
        try {
            ensureValidator();
        } catch (Exception ignored) {
            // Lazy init on first processData if startup warm fails.
        }
    }

    @Override
    public TransactionData processData(TransactionData data) throws EIPException {
        try {
            byte[] bytes = IOUtils.toByteArray(data.getDataStream());
            data.setDataStream(new ByteArrayInputStream(bytes));

            String method = attrString(data, "com.pilotfish.HttpMethodName");
            String resourceName = attrString(data, "com.pilotfish.ResourceName");
            if (!"POST".equalsIgnoreCase(method) && !"PUT".equalsIgnoreCase(method)) {
                data.getAttributes().setAttribute(ATTR_PROFILE_STATUS, "SKIP");
                return data;
            }
            if ("metadata".equalsIgnoreCase(resourceName)) {
                data.getAttributes().setAttribute(ATTR_PROFILE_STATUS, "SKIP");
                return data;
            }

            String structural = attrString(data, ATTR_VALIDATION_STATUS);
            String bundleInteraction = attrString(data, "fhir.BundleInteraction");
            boolean isTxnBundle = "Bundle".equalsIgnoreCase(resourceName)
                    && StringUtils.isNotBlank(bundleInteraction);

            // Prefer fhir.RawBody (saved before transforms); fall back to current stream.
            String json = attrString(data, ATTR_RAW_BODY);
            if (StringUtils.isBlank(json)) {
                json = new String(bytes, StandardCharsets.UTF_8);
            }
            if (StringUtils.isBlank(json)) {
                fail(data, structuralOutcome("Empty request body for FHIR create/update."));
                return data;
            }

            if (!isTxnBundle && !"PASS".equalsIgnoreCase(structural)) {
                fail(data, structuralOutcome(
                        "Invalid FHIR JSON create/update. Require matching resourceType and non-empty id."));
                return data;
            }

            ensureValidator();
            IBaseResource resource;
            try {
                resource = JSON_PARSER.parseResource(json);
            } catch (Exception parseEx) {
                fail(data, structuralOutcome("Unable to parse FHIR JSON: " + shortMsg(parseEx)));
                return data;
            }

            ValidationResult result = VALIDATOR.validateWithResult(resource);
            List<SingleValidationMessage> errors = new ArrayList<>();
            for (SingleValidationMessage msg : result.getMessages()) {
                if (msg.getSeverity() == ResultSeverityEnum.ERROR
                        || msg.getSeverity() == ResultSeverityEnum.FATAL) {
                    errors.add(msg);
                }
            }

            if (errors.isEmpty()) {
                data.getAttributes().setAttribute(ATTR_PROFILE_STATUS, "PASS");
                return data;
            }

            OperationOutcome oo = toOperationOutcome(errors);
            String ooJson = JSON_PARSER.encodeResourceToString(oo);
            fail(data, ooJson);
            return data;
        } catch (Exception e) {
            throw new EIPException("FHIR profile validation failed: " + shortMsg(e), e);
        }
    }

    private static void fail(TransactionData data, String outcomeJson) {
        data.getAttributes().setAttribute(ATTR_PROFILE_STATUS, "FAIL");
        data.getAttributes().setAttribute(ATTR_VALIDATION_OUTCOME, outcomeJson);
        data.getAttributes().setAttribute(ATTR_VALIDATION_STATUS, "FAIL");
    }

    private static String structuralOutcome(String diagnostics) {
        OperationOutcome oo = new OperationOutcome();
        OperationOutcome.OperationOutcomeIssueComponent issue = oo.addIssue();
        issue.setSeverity(OperationOutcome.IssueSeverity.ERROR);
        issue.setCode(OperationOutcome.IssueType.INVALID);
        issue.setDiagnostics(diagnostics);
        try {
            ensureValidator();
            return JSON_PARSER.encodeResourceToString(oo);
        } catch (Exception e) {
            String esc = diagnostics.replace("\\", "\\\\").replace("\"", "\\\"");
            return "{\"resourceType\":\"OperationOutcome\",\"issue\":[{\"severity\":\"error\","
                    + "\"code\":\"invalid\",\"diagnostics\":\"" + esc + "\"}]}";
        }
    }

    private static OperationOutcome toOperationOutcome(List<SingleValidationMessage> errors) {
        OperationOutcome oo = new OperationOutcome();
        for (SingleValidationMessage msg : errors) {
            OperationOutcome.OperationOutcomeIssueComponent issue = oo.addIssue();
            if (msg.getSeverity() == ResultSeverityEnum.FATAL) {
                issue.setSeverity(OperationOutcome.IssueSeverity.FATAL);
            } else {
                issue.setSeverity(OperationOutcome.IssueSeverity.ERROR);
            }
            issue.setCode(OperationOutcome.IssueType.INVALID);
            issue.setDiagnostics(msg.getMessage());
            if (StringUtils.isNotBlank(msg.getLocationString())) {
                issue.addExpression(msg.getLocationString());
            }
            CodeableConcept details = new CodeableConcept();
            details.setText(msg.getSeverity() + (msg.getLocationString() != null
                    ? (" @ " + msg.getLocationString()) : ""));
            issue.setDetails(details);
        }
        return oo;
    }

    private static String attrString(TransactionData data, String name) {
        Object v = data.getAttributes().getAttribute(name);
        return v == null ? null : v.toString();
    }

    private static String shortMsg(Throwable t) {
        String m = t.getMessage();
        if (m == null || m.isBlank()) {
            return t.getClass().getSimpleName();
        }
        return m.length() > 400 ? m.substring(0, 400) + "…" : m;
    }

    private static void ensureValidator() {
        if (VALIDATOR != null) {
            return;
        }
        synchronized (LOCK) {
            if (VALIDATOR != null) {
                return;
            }
            FhirContext ctx = FhirContext.forR4();
            ValidationSupportChain chain = new ValidationSupportChain(
                    new DefaultProfileValidationSupport(ctx),
                    new InMemoryTerminologyServerValidationSupport(ctx),
                    new CommonCodeSystemsTerminologyService(ctx),
                    new SnapshotGeneratingValidationSupport(ctx)
            );
            ctx.setValidationSupport(chain);
            FhirInstanceValidator module = new FhirInstanceValidator(chain);
            module.setAnyExtensionsAllowed(true);
            module.setErrorForUnknownProfiles(false);
            module.setNoTerminologyChecks(true);
            FhirValidator validator = ctx.newValidator();
            validator.setValidateAgainstStandardSchema(false);
            validator.setValidateAgainstStandardSchematron(false);
            validator.registerValidatorModule(module);
            FHIR_CTX = ctx;
            VALIDATOR = validator;
            JSON_PARSER = ctx.newJsonParser().setPrettyPrint(false);
        }
    }
}
