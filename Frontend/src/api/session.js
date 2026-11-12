// ------------------------------------------------------------------
// Session refresh (Cognito)
//
// Access tokens expire after 60 minutes. Cognito also gave us a REFRESH
// token at sign-in (valid 30 days). Trading it for a new access token
// needs no password, so the user stays signed in.
//
// This file talks to Cognito with fetch() only. It must not import
// './axios', because axios.js imports this file (that would be a loop).
// ------------------------------------------------------------------

const COGNITO_CLIENT_ID = import.meta.env.VITE_COGNITO_CLIENT_ID
const COGNITO_REGION = import.meta.env.VITE_COGNITO_REGION || 'us-east-1'

/**
 * Returns a new access token, or null if there is no refresh token or
 * Cognito refused it (expired, revoked, or user disabled).
 */
export async function refreshAccessToken() {
  const refreshToken = localStorage.getItem('refreshToken')
  if (!COGNITO_CLIENT_ID || !refreshToken) {
    return null
  }
  try {
    const res = await fetch(`https://cognito-idp.${COGNITO_REGION}.amazonaws.com/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
      },
      body: JSON.stringify({
        AuthFlow: 'REFRESH_TOKEN_AUTH',
        ClientId: COGNITO_CLIENT_ID,
        AuthParameters: { REFRESH_TOKEN: refreshToken },
      }),
    })
    if (!res.ok) {
      return null
    }
    const body = await res.json()
    const token = body.AuthenticationResult?.AccessToken
    if (!token) {
      return null
    }
    localStorage.setItem('token', token)
    return token
  } catch {
    return null
  }
}