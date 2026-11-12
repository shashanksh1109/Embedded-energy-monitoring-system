import api from './axios'

/** Hubs of the current organization, with sensors, output states and recent commands. */
export const listHubs = () =>
  api.get('/hubs').then(r => r.data)

/** Pair a hub by the code shown on its screen (OWNER or ADMIN). */
export const pairHub = (code) =>
  api.post('/hubs/pair', { code }).then(r => r.data)

/** Switch an output of a hub, e.g. sendCommand(id, 'fan', 'ON'). */
export const sendCommand = (hubDeviceId, target, action) =>
  api.post(`/hubs/${hubDeviceId}/commands`, { target, action }).then(r => r.data)

/** The hub's hardware setup (outputs and sensors with their pins). */
export const getHubConfig = (hubDeviceId) =>
  api.get(`/hubs/${hubDeviceId}/config`).then(r => r.data)

/** Save a new hardware setup version (OWNER or ADMIN). */
export const saveHubConfig = (hubDeviceId, config) =>
  api.put(`/hubs/${hubDeviceId}/config`, config).then(r => r.data)