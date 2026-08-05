package com.pilotfish.eip.modules.fhir;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.jwk.source.RemoteJWKSet;
import com.nimbusds.jose.proc.JWSKeySelector;
import com.nimbusds.jose.proc.JWSVerificationKeySelector;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.proc.ConfigurableJWTProcessor;
import com.nimbusds.jwt.proc.DefaultJWTProcessor;
import com.pilotfish.eip.EIPException;
import com.pilotfish.eip.TransactionAttributesMetadata;
import com.pilotfish.eip.TransactionData;
import com.pilotfish.eip.extend.AbstractProcessor;
import com.pilotfish.eip.extend.Category;
import com.pilotfish.utils.ccp.BooleanConfigurationItem;
import com.pilotfish.utils.ccp.ConfigurationDescriptor;
import com.pilotfish.utils.ccp.StringConfigurationItem;
import org.apache.commons.lang3.StringUtils;

import java.net.URL;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Phase 5: validate OAuth2 Bearer JWTs (Keycloak) for FHIR write methods.
 * Soft enforcement via attributes; route returns HTTP 401 OperationOutcome on FAIL.
 */
public class FhirJwtAuthProcessor extends AbstractProcessor {

    public static final String ATTR_AUTH_STATUS = "fhir.AuthStatus";
    public static final String ATTR_AUTH_SUBJECT = "fhir.AuthSubject";
    public static final String ATTR_AUTH_ERROR = "fhir.AuthError";
    public static final String ATTR_AUTH_OUTCOME = "fhir.AuthOutcome";

    public static final String JWKS_URL_TAG = "JwksUrl";
    public static final String ISSUER_TAG = "ExpectedIssuer";
    public static final String AUDIENCE_TAG = "ExpectedAudience";
    public static final String REQUIRE_WRITES_TAG = "RequireOnWrites";

    private static final Object LOCK = new Object();
    private static volatile ConfigurableJWTProcessor<SecurityContext> PROCESSOR;
    private static volatile String CACHED_JWKS;
    private static volatile String CACHED_ISSUER;

    @Override
    public String getType() {
        return "FHIR JWT Auth";
    }

    @Override
    public String getDescription() {
        return "Validate Authorization Bearer JWT against Keycloak JWKS for POST/PUT/DELETE.";
    }

    @Override
    public List<Category> getCategories() {
        List<Category> categories = new ArrayList<>();
        categories.add(Category.HEALTHCARE);
        categories.add(Category.ENCRYPTION);
        categories.add(Category.WEB);
        return categories;
    }

    @Override
    protected ConfigurationDescriptor getConfigurationDescriptor() {
        ConfigurationDescriptor d = new ConfigurationDescriptor(true);
        d.addConfigurationItem(new BooleanConfigurationItem(
                "Execute Processor", "ExecuteProcessor", true, "Validate JWT on write methods"));
        d.addConfigurationItem(new StringConfigurationItem(
                "JWKS URL", JWKS_URL_TAG,
                "http://keycloak:8080/realms/fhir-demo/protocol/openid-connect/certs",
                "Keycloak JWKS endpoint (Docker service DNS)"));
        d.addConfigurationItem(new StringConfigurationItem(
                "Expected Issuer", ISSUER_TAG,
                "http://localhost:8112/realms/fhir-demo",
                "iss claim (public hostname/port users receive)"));
        d.addConfigurationItem(new StringConfigurationItem(
                "Expected Audience (optional)", AUDIENCE_TAG, "account",
                "Optional aud claim; Keycloak often uses 'account'. Leave blank to skip."));
        d.addConfigurationItem(new BooleanConfigurationItem(
                "Require On Writes", REQUIRE_WRITES_TAG, true,
                "When true, POST/PUT/DELETE require a valid Bearer token"));
        registerTransactionAttribute(ATTR_AUTH_STATUS, "PASS / FAIL / SKIP", String.class,
                TransactionAttributesMetadata.PROCESSOR);
        registerTransactionAttribute(ATTR_AUTH_SUBJECT, "JWT subject", String.class,
                TransactionAttributesMetadata.PROCESSOR);
        registerTransactionAttribute(ATTR_AUTH_ERROR, "Auth failure reason", String.class,
                TransactionAttributesMetadata.PROCESSOR);
        registerTransactionAttribute(ATTR_AUTH_OUTCOME, "OperationOutcome JSON for 401", String.class,
                TransactionAttributesMetadata.PROCESSOR);
        return d;
    }

    @Override
    public TransactionData processData(TransactionData data) throws EIPException {
        try {
            String method = str(data, "com.pilotfish.HttpMethodName");
            boolean requireWrites = boolCfg(data, REQUIRE_WRITES_TAG, true);
            boolean isWrite = "POST".equalsIgnoreCase(method)
                    || "PUT".equalsIgnoreCase(method)
                    || "DELETE".equalsIgnoreCase(method);

            if (!requireWrites || !isWrite) {
                data.getAttributes().setAttribute(ATTR_AUTH_STATUS, "SKIP");
                return data;
            }

            String auth = str(data, "com.pilotfish.authorization");
            if (StringUtils.isBlank(auth) || !auth.regionMatches(true, 0, "Bearer ", 0, 7)) {
                fail(data, "Missing or invalid Authorization Bearer token for FHIR write.");
                return data;
            }
            String token = auth.substring(7).trim();
            if (token.isEmpty()) {
                fail(data, "Empty Bearer token.");
                return data;
            }

            String jwks = cfg(data, JWKS_URL_TAG,
                    "http://keycloak:8080/realms/fhir-demo/protocol/openid-connect/certs");
            String issuer = cfg(data, ISSUER_TAG, "http://localhost:8112/realms/fhir-demo");
            String audience = cfg(data, AUDIENCE_TAG, "account");

            JWTClaimsSet claims = validate(token, jwks, issuer, audience);
            data.getAttributes().setAttribute(ATTR_AUTH_STATUS, "PASS");
            Object preferred = claims.getClaim("preferred_username");
            String subject = StringUtils.defaultIfBlank(claims.getSubject(),
                    preferred == null ? "" : String.valueOf(preferred));
            data.getAttributes().setAttribute(ATTR_AUTH_SUBJECT, subject);
            data.getAttributes().removeAttribute(ATTR_AUTH_ERROR);
            return data;
        } catch (Exception e) {
            fail(data, "JWT validation failed: " + shortMsg(e));
            return data;
        }
    }

    private JWTClaimsSet validate(String token, String jwksUrl, String issuer, String audience) throws Exception {
        ConfigurableJWTProcessor<SecurityContext> processor = processorFor(jwksUrl, issuer);
        JWTClaimsSet claims = processor.process(token, null);
        if (StringUtils.isNotBlank(audience)) {
            List<String> aud = claims.getAudience();
            boolean ok = false;
            if (aud != null) {
                for (String a : aud) {
                    if (audience.equals(a)) {
                        ok = true;
                        break;
                    }
                }
            }
            // Keycloak client credentials tokens sometimes omit expected aud; also accept client_id azp.
            Object azp = claims.getClaim("azp");
            if (!ok && azp != null && "fhir-r4-platform".equals(String.valueOf(azp))) {
                ok = true;
            }
            if (!ok && (aud == null || aud.isEmpty())) {
                ok = true; // demo soft: no aud claim
            }
            if (!ok) {
                throw new IllegalArgumentException("Unexpected token audience: " + aud);
            }
        }
        return claims;
    }

    private ConfigurableJWTProcessor<SecurityContext> processorFor(String jwksUrl, String issuer) throws Exception {
        if (PROCESSOR != null && jwksUrl.equals(CACHED_JWKS) && issuer.equals(CACHED_ISSUER)) {
            return PROCESSOR;
        }
        synchronized (LOCK) {
            if (PROCESSOR != null && jwksUrl.equals(CACHED_JWKS) && issuer.equals(CACHED_ISSUER)) {
                return PROCESSOR;
            }
            JWKSource<SecurityContext> keySource = new RemoteJWKSet<>(new URL(jwksUrl));
            ConfigurableJWTProcessor<SecurityContext> p = new DefaultJWTProcessor<>();
            Set<JWSAlgorithm> algs = new HashSet<>();
            algs.add(JWSAlgorithm.RS256);
            algs.add(JWSAlgorithm.RS384);
            algs.add(JWSAlgorithm.RS512);
            JWSKeySelector<SecurityContext> keySelector = new JWSVerificationKeySelector<>(algs, keySource);
            p.setJWSKeySelector(keySelector);
            p.setJWTClaimsSetVerifier((claims, ctx) -> {
                if (StringUtils.isNotBlank(issuer)) {
                    String iss = claims.getIssuer();
                    if (iss == null || !issuer.equals(iss)) {
                        throw new IllegalArgumentException("Unexpected issuer: " + iss);
                    }
                }
                if (claims.getExpirationTime() != null
                        && claims.getExpirationTime().getTime() < System.currentTimeMillis() - 30_000L) {
                    throw new IllegalArgumentException("Token expired");
                }
            });
            PROCESSOR = p;
            CACHED_JWKS = jwksUrl;
            CACHED_ISSUER = issuer;
            return PROCESSOR;
        }
    }

    private void fail(TransactionData data, String msg) {
        data.getAttributes().setAttribute(ATTR_AUTH_STATUS, "FAIL");
        data.getAttributes().setAttribute(ATTR_AUTH_ERROR, msg);
        String esc = msg.replace("\\", "\\\\").replace("\"", "\\\"");
        String oo = "{\"resourceType\":\"OperationOutcome\",\"issue\":[{\"severity\":\"error\","
                + "\"code\":\"login\",\"diagnostics\":\"" + esc + "\"}]}";
        data.getAttributes().setAttribute(ATTR_AUTH_OUTCOME, oo);
        // Prefer AuthOutcome in Unauthorized target restore
        data.getAttributes().setAttribute("fhir.ValidationOutcome", oo);
    }

    private String cfg(TransactionData data, String tag, String def) {
        try {
            String s = getConfigurationManager().getStringValue(tag, data);
            if (s == null || s.trim().isEmpty()) {
                return def;
            }
            return s.trim();
        } catch (Exception e) {
            return def;
        }
    }

    private boolean boolCfg(TransactionData data, String tag, boolean def) {
        try {
            return getConfigurationManager().getBooleanValue(tag, data);
        } catch (Exception e) {
            return def;
        }
    }

    private static String str(TransactionData data, String name) {
        Object v = data.getAttributes().getAttribute(name);
        return v == null ? null : v.toString();
    }

    private static String shortMsg(Throwable t) {
        String m = t.getMessage();
        if (m == null || m.isBlank()) {
            return t.getClass().getSimpleName();
        }
        return m.length() > 350 ? m.substring(0, 350) + "…" : m;
    }
}
