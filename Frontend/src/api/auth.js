import api from './axios'

// ------------------------------------------------------------------
// Login
//
// If VITE_COGNITO_CLIENT_ID is set (Frontend/.env.local), users sign in
// with Amazon Cognito: email + password go straight to Cognito over HTTPS,
// and Cognito returns signed tokens. The backend never sees the password.
//
// If it is not set, the old built-in login (/api/auth/login) is used.
//
// Both return the same shape: { token, username, refreshToken? }
// ------------------------------------------------------------------

const COGNITO_CLIENT_ID = import.meta.env.VITE_COGNITO_CLIENT_ID
const COGNITO_REGION = import.meta.env.VITE_COGNITO_REGION || 'us-east-1'

export const usingCognito = Boolean(COGNITO_CLIENT_ID)

/** An error with a message that is safe to show on the login page. */
export class LoginError extends Error {
  constructor(code, message) {
    super(message)
    this.code = code
  }
}

async function cognitoLogin(email, password) {
  let res
  try {
    res = await fetch(`https://cognito-idp.${COGNITO_REGION}.amazonaws.com/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
      },
      body: JSON.stringify({
        AuthFlow: 'USER_PASSWORD_AUTH',
        ClientId: COGNITO_CLIENT_ID,
        AuthParameters: { USERNAME: email, PASSWORD: password },
      }),
    })
  } catch {
    throw new LoginError('NETWORK', 'Service unavailable — please try again in a moment')
  }

  const body = await res.json().catch(() => ({}))

  if (!res.ok) {
    // Cognito reports errors as e.g. { "__type": "NotAuthorizedException", ... }
    const type = (body.__type || '').split('#').pop()
    if (type === 'NotAuthorizedException' || type === 'UserNotFoundException') {
      throw new LoginError(type, 'Invalid email or password')
    }
    if (type === 'UserNotConfirmedException') {
      throw new LoginError(type, 'Please verify your email address first')
    }
    if (type === 'PasswordResetRequiredException') {
      throw new LoginError(type, 'A password reset is required for this account')
    }
    throw new LoginError(type || 'UNKNOWN', 'Login failed — please try again')
  }

  // e.g. NEW_PASSWORD_REQUIRED for accounts created with a temporary password
  if (body.ChallengeName) {
    throw new LoginError(body.ChallengeName, 'This account needs an extra sign-in step that is not supported yet')
  }

  const result = body.AuthenticationResult
  return {
    token: result.AccessToken,          // sent to OUR API on every request
    refreshToken: result.RefreshToken,  // used later to get new tokens silently
    username: email,
  }
}

async function legacyLogin(username, password) {
  try {
    const response = await api.post('/auth/login', { username, password })
    return { token: response.data.token, username: response.data.username }
  } catch (err) {
    if (err.response?.status === 401) {
      throw new LoginError('INVALID', 'Invalid username or password')
    }
    if (!err.response || err.response.status >= 500) {
      throw new LoginError('NETWORK', 'Service unavailable — please try again in a moment')
    }
    throw new LoginError('UNKNOWN', 'Login failed — please try again')
  }
}

export const login = (username, password) =>
  usingCognito ? cognitoLogin(username, password) : legacyLogin(username, password)