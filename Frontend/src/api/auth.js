import api from './axios'

// ------------------------------------------------------------------
// Accounts and login
//
// If VITE_COGNITO_CLIENT_ID is set (Frontend/.env.local), users sign up and
// sign in with Amazon Cognito. Email, password and verification codes go
// straight to Cognito over HTTPS; our backend never sees a password.
//
// If it is not set, the old built-in login (/api/auth/login) is used.
// ------------------------------------------------------------------

const COGNITO_CLIENT_ID = import.meta.env.VITE_COGNITO_CLIENT_ID
const COGNITO_REGION = import.meta.env.VITE_COGNITO_REGION || 'us-east-1'

export const usingCognito = Boolean(COGNITO_CLIENT_ID)

/** An error with a message that is safe to show to the user. */
export class LoginError extends Error {
  constructor(code, message) {
    super(message)
    this.code = code
  }
}

// Cognito error type -> message for the user
const FRIENDLY = {
  NotAuthorizedException: 'Invalid email or password',
  UserNotFoundException: 'Invalid email or password',
  UserNotConfirmedException: 'Please verify your email address first',
  PasswordResetRequiredException: 'A password reset is required for this account',
  UsernameExistsException: 'An account with this email already exists — try signing in',
  CodeMismatchException: 'That code is not correct',
  ExpiredCodeException: 'That code has expired — request a new one',
  LimitExceededException: 'Too many attempts — please wait a little and try again',
  TooManyRequestsException: 'Too many attempts — please wait a little and try again',
}

/** Call one Cognito API action, e.g. "InitiateAuth" or "SignUp". */
async function cognitoCall(action, payload) {
  let res
  try {
    res = await fetch(`https://cognito-idp.${COGNITO_REGION}.amazonaws.com/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target': `AWSCognitoIdentityProviderService.${action}`,
      },
      body: JSON.stringify(payload),
    })
  } catch {
    throw new LoginError('NETWORK', 'Service unavailable — please try again in a moment')
  }

  const body = await res.json().catch(() => ({}))
  if (!res.ok) {
    // Cognito reports errors as e.g. { "__type": "NotAuthorizedException", "message": "..." }
    const type = (body.__type || '').split('#').pop()
    if (FRIENDLY[type]) {
      throw new LoginError(type, FRIENDLY[type])
    }
    // e.g. InvalidPasswordException: Cognito's own message explains the rule
    if (type === 'InvalidPasswordException' || type === 'InvalidParameterException') {
      throw new LoginError(type, body.message || 'Please check what you entered')
    }
    throw new LoginError(type || 'UNKNOWN', 'Something went wrong — please try again')
  }
  return body
}

async function cognitoLogin(email, password) {
  const body = await cognitoCall('InitiateAuth', {
    AuthFlow: 'USER_PASSWORD_AUTH',
    ClientId: COGNITO_CLIENT_ID,
    AuthParameters: { USERNAME: email, PASSWORD: password },
  })

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

// ------------------------------------------------------------------
// Sign-up (Cognito only)
// ------------------------------------------------------------------

/** Create an account. Cognito then emails a 6-digit verification code. */
export const signUp = (email, password) =>
  cognitoCall('SignUp', {
    ClientId: COGNITO_CLIENT_ID,
    Username: email,
    Password: password,
    UserAttributes: [{ Name: 'email', Value: email }],
  })

/** Confirm the account with the code from the email. */
export const confirmSignUp = (email, code) =>
  cognitoCall('ConfirmSignUp', {
    ClientId: COGNITO_CLIENT_ID,
    Username: email,
    ConfirmationCode: code.trim(),
  })

/** Send the verification code again. */
export const resendCode = (email) =>
  cognitoCall('ResendConfirmationCode', {
    ClientId: COGNITO_CLIENT_ID,
    Username: email,
  })