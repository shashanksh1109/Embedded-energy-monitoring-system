import api from './axios'
export const getAnalyticsLatest = (zone, metric) =>
  api.get(`/analytics/${zone}/latest?metric=${metric}`).then(r => r.data)
export const getAnalyticsSummary = (zone) =>
  api.get(`/analytics/${zone}/summary`).then(r => r.data)
export const getAnalyticsAll = (metric) =>
  api.get(`/analytics/all?metric=${metric}`).then(r => r.data)
