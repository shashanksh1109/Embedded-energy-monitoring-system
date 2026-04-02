import api from './axios'

export const getLatestHvac = (zone) =>
  api.get(`/hvac/${zone}/latest`).then(r => r.data)

export const getHvacMode = (zone) =>
  api.get(`/hvac/${zone}/mode`).then(r => r.data)

export const getHvacSparkline = (zone) =>
  api.get(`/hvac/${zone}/sparkline`).then(r => r.data)

export const getHvacRecent = (zone, hours = 24) =>
  api.get(`/hvac/${zone}/recent`, { params: { hours } }).then(r => r.data)

export const getHvacSummary = (zone, from, to) =>
  api.get(`/hvac/${zone}/summary`, { params: { from, to } }).then(r => r.data)
