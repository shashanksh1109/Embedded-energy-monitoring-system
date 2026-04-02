import api from './axios'

export const getLatestSnapshot = (zone, metric) =>
  api.get(`/analytics/${zone}/latest`, { params: { metric } }).then(r => r.data)

export const getZoneSummary = (zone) =>
  api.get(`/analytics/${zone}/summary`).then(r => r.data)

export const getAllZonesSnapshot = (metric) =>
  api.get(`/analytics/all`, { params: { metric } }).then(r => r.data)

export const getSnapshotsRange = (zone, metric, from, to) =>
  api.get(`/analytics/${zone}/range`, { params: { metric, from, to } }).then(r => r.data)
