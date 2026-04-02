import api from './axios'

export const getLatestTemperature = (zone) =>
  api.get(`/temperature/${zone}/latest`).then(r => r.data)

export const getTemperatureSparkline = (zone) =>
  api.get(`/temperature/${zone}/sparkline`).then(r => r.data)

export const getTemperatureRange = (zone, from, to) =>
  api.get(`/temperature/${zone}/range`, { params: { from, to } }).then(r => r.data)

export const getTemperatureRecent = (zone, hours = 24) =>
  api.get(`/temperature/${zone}/recent`, { params: { hours } }).then(r => r.data)

export const getTemperatureAlerts = (zone) =>
  api.get(`/temperature/${zone}/alerts`).then(r => r.data)
