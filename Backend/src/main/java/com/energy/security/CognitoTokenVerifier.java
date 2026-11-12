package com.energy.security;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtDecoders;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.UUID;

/**
 * CognitoTokenVerifier - checks access tokens issued by Amazon Cognito and
 * finds which organization the user belongs to.
 *
 * Verification (done by Spring Security's JwtDecoder):
 *   - signature: Cognito signs tokens with its private key (RS256); the
 *     matching public keys are downloaded from the issuer's JWKS URL
 *   - expiry:    the token must not be expired
 *   - issuer:    "iss" must be exactly our user pool
 * Extra checks done here:
 *   - token_use must be "access" (not an ID token)
 *   - client_id must be OUR app client
 *
 * Configured by two environment variables. If either is empty, Cognito
 * login is simply switched off (the built-in admin login keeps working).
 *   COGNITO_ISSUER     e.g. https://cognito-idp.us-east-1.amazonaws.com/us-east-1_AbC123
 *   COGNITO_CLIENT_ID  the app client ID from Terraform
 */
@Component
public class CognitoTokenVerifier {

    private final String issuer;
    private final String clientId;
    private final JdbcTemplate jdbc;

    /** Created on first use, so the backend still starts if Cognito is unreachable. */
    private volatile JwtDecoder decoder;

    private final HttpClient http = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(5))
        .build();
    private final ObjectMapper json = new ObjectMapper();

    public CognitoTokenVerifier(
        @Value("${COGNITO_ISSUER:}") String issuer,
        @Value("${COGNITO_CLIENT_ID:}") String clientId,
        JdbcTemplate jdbc
    ) {
        this.issuer = issuer;
        this.clientId = clientId;
        this.jdbc = jdbc;
    }

    public boolean isEnabled() {
        return !issuer.isBlank() && !clientId.isBlank();
    }

    /**
     * Returns the verified token, or null if it is not a valid Cognito
     * access token for our app.
     */
    public Jwt verify(String token) {
        if (!isEnabled()) {
            return null;
        }
        try {
            Jwt jwt = decoder().decode(token);          // signature + expiry + issuer
            if (!"access".equals(jwt.getClaimAsString("token_use"))) {
                return null;
            }
            if (!clientId.equals(jwt.getClaimAsString("client_id"))) {
                return null;
            }
            return jwt;
        } catch (JwtException | IllegalArgumentException | IllegalStateException e) {
            return null;
        }
    }

    /**
     * The organization a user belongs to (their oldest membership), or null
     * if they belong to none. memberships has no row-level security, so this
     * works before the request's organization is known.
     */
    public UUID findOrgId(String userSub) {
        List<UUID> ids = jdbc.query(
            "SELECT org_id FROM memberships WHERE user_id = ?::uuid ORDER BY created_at LIMIT 1",
            (rs, rowNum) -> rs.getObject(1, UUID.class),
            userSub
        );
        return ids.isEmpty() ? null : ids.get(0);
    }

    /**
     * The user's email address, asked from Cognito with the user's own access
     * token (Cognito's GetUser API). Access tokens don't contain the email,
     * and we must not trust an email address sent by the browser.
     * Needs no AWS credentials: the access token itself is the permission.
     * Returns null if Cognito can't be reached or refuses the token.
     */
    public String fetchEmail(String accessToken) {
        try {
            URI issuerUri = URI.create(issuer);
            URI endpoint = URI.create(issuerUri.getScheme() + "://" + issuerUri.getHost() + "/");
            String body = json.writeValueAsString(java.util.Map.of("AccessToken", accessToken));

            HttpRequest request = HttpRequest.newBuilder(endpoint)
                .timeout(Duration.ofSeconds(5))
                .header("Content-Type", "application/x-amz-json-1.1")
                .header("X-Amz-Target", "AWSCognitoIdentityProviderService.GetUser")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build();

            HttpResponse<String> response = http.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                return null;
            }
            for (JsonNode attr : json.readTree(response.body()).path("UserAttributes")) {
                if ("email".equals(attr.path("Name").asText())) {
                    return attr.path("Value").asText();
                }
            }
            return null;
        } catch (Exception e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            return null;
        }
    }

    private JwtDecoder decoder() {
        JwtDecoder d = decoder;
        if (d == null) {
            synchronized (this) {
                d = decoder;
                if (d == null) {
                    // Reads <issuer>/.well-known/openid-configuration to find the public keys
                    d = JwtDecoders.fromIssuerLocation(issuer);
                    decoder = d;
                }
            }
        }
        return d;
    }
}