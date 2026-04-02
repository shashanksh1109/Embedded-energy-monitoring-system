import api from './axios'

export const getAllZones = () =>
  api.get('/zones').then(r => r.data)

export const getZoneByName = (name) =>
  api.get(`/zones/${name}`).then(r => r.data)
