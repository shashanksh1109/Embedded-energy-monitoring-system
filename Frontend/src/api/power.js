import api from './axios'

export const getLatestPower = (zone) =>
  api.get(`/power/${zone}/latest`).then(r => r.data)

export const getPowerSparkline = (zone) =>
  api.get(`/power/${zone}/sparkline`).then(r => r.data)

export const getPowerRecent = (zone, hours = 24) =>
  api.get(`/power/${zone}/recent`, { params: { hours } }).then(r => r.data)

export const getEnergySummary = (zone, from, to) =>
  api.get(`/power/${zone}/summary`, { params: { from, to } }).then(r => r.data)
