import api from './axios'

export const getAllZones = () =>
  api.get('/zones').then(r => r.data)

export const getZoneByName = (name) =>
  api.get(`/zones/${name}`).then(r => r.data)

/** Create a zone in the current organization (OWNER or ADMIN only). */
export const createZone = ({ name, description, capacity }) =>
  api.post('/zones', { name, description, capacity }).then(r => r.data)