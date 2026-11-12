import api from './axios'

/** { hasOrganization: true | false } for the signed-in Cognito user. */
export const getOnboardingStatus = () =>
  api.get('/onboarding/status').then(r => r.data)

/** Create the user's own organization; they become its OWNER. */
export const createOrganization = (organizationName, displayName) =>
  api.post('/onboarding', { organizationName, displayName }).then(r => r.data)