import api from './axios'

export const getLatestOccupancy = (zone) =>
  api.get(`/occupancy/${zone}/latest`).then(r => r.data)

export const getOccupancyStatus = (zone) =>
  api.get(`/occupancy/${zone}/status`).then(r => r.data)

export const getOccupancySparkline = (zone) =>
  api.get(`/occupancy/${zone}/sparkline`).then(r => r.data)

export const getOccupancyRecent = (zone, hours = 24) =>
  api.get(`/occupancy/${zone}/recent`, { params: { hours } }).then(r => r.data)

export const getPeakOccupancy = (zone, from, to) =>
  api.get(`/occupancy/${zone}/peak`, { params: { from, to } }).then(r => r.data)
