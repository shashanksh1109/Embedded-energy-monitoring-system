import api from './axios'

/** All devices of the current organization. */
export const getDevices = () =>
  api.get('/devices').then(r => r.data)

/**
 * Add a device to a zone (OWNER or ADMIN).
 * Returns { device, claimCode, claimExpiresAt } - the code is shown only once.
 */
export const registerDevice = ({ zoneId, deviceType, displayName }) =>
  api.post('/devices', { zoneId, deviceType, displayName }).then(r => r.data)