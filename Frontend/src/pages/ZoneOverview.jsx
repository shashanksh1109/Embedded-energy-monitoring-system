import { useState, useEffect } from 'react'
import { getAllZones } from '../api/zones'
import { getLatestTemperature } from '../api/temperature'
import { getLatestOccupancy } from '../api/occupancy'
import { getLatestHvac } from '../api/hvac'
import { getLatestPower } from '../api/power'

const STATUS_DOT = ({ ok }) => (
  <span className={`inline-block w-2 h-2 rounded-full ${ok ? 'bg-green-400' : 'bg-gray-600'}`} />
)

function HvacBadge({ mode }) {
  const styles = {
    HEATING: 'bg-orange-500/20 text-orange-400 border-orange-500/30',
    COOLING: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
    IDLE:    'bg-gray-500/20 text-gray-500 border-gray-600',
  }
  const icons = { HEATING: '🔥', COOLING: '❄️', IDLE: '💤' }
  const s = styles[mode] || styles.IDLE
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full border text-xs font-medium ${s}`}>
      {icons[mode] || '💤'} {mode || 'IDLE'}
    </span>
  )
}

function ZoneRow({ zone }) {
  const [temp, setTemp]   = useState(null)
  const [occ, setOcc]     = useState(null)
  const [hvac, setHvac]   = useState(null)
  const [power, setPower] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetch = async () => {
      const [t, o, h, p] = await Promise.all([
        getLatestTemperature(zone.name).catch(() => null),
        getLatestOccupancy(zone.name).catch(() => null),
        getLatestHvac(zone.name).catch(() => null),
        getLatestPower(zone.name).catch(() => null),
      ])
      setTemp(t); setOcc(o); setHvac(h); setPower(p)
      setLoading(false)
    }
    fetch()
    const iv = setInterval(fetch, 10000)
    return () => clearInterval(iv)
  }, [zone.name])

  return (
    <tr className="border-t border-gray-800 hover:bg-gray-800/40 transition-colors">
      {/* Zone */}
      <td className="px-4 py-4">
        <div className="flex items-center gap-2">
          <STATUS_DOT ok={!!temp} />
          <div>
            <p className="text-white font-medium text-sm">{zone.name}</p>
            <p className="text-gray-500 text-xs">{zone.description}</p>
          </div>
        </div>
      </td>

      {/* Capacity */}
      <td className="px-4 py-4 text-center">
        <span className="text-gray-400 text-sm">{zone.capacity} max</span>
      </td>

      {/* Temperature */}
      <td className="px-4 py-4 text-center">
        {loading ? (
          <span className="text-gray-600 text-sm">—</span>
        ) : temp ? (
          <span className={`text-sm font-semibold ${
            temp.temperatureC > 24 ? 'text-blue-400' :
            temp.temperatureC < 18 ? 'text-orange-400' : 'text-green-400'
          }`}>
            {temp.temperatureC.toFixed(1)}°C
          </span>
        ) : (
          <span className="text-gray-600 text-sm">—</span>
        )}
      </td>

      {/* Occupancy */}
      <td className="px-4 py-4 text-center">
        {loading ? (
          <span className="text-gray-600 text-sm">—</span>
        ) : occ !== null ? (
          <div className="flex items-center justify-center gap-1">
            <span className="text-sm text-white">{occ?.occupancyCount ?? 0}</span>
            <span className="text-xs text-gray-500">/ {zone.capacity}</span>
          </div>
        ) : (
          <span className="text-gray-600 text-sm">—</span>
        )}
      </td>

      {/* HVAC */}
      <td className="px-4 py-4 text-center">
        {loading ? (
          <span className="text-gray-600 text-sm">—</span>
        ) : (
          <div className="flex flex-col items-center gap-1">
            <HvacBadge mode={hvac?.mode} />
            {hvac?.setpoint && (
              <span className="text-xs text-gray-500">
                target {hvac.setpoint.toFixed(1)}°C
              </span>
            )}
          </div>
        )}
      </td>

      {/* Power */}
      <td className="px-4 py-4 text-center">
        {loading ? (
          <span className="text-gray-600 text-sm">—</span>
        ) : power ? (
          <div className="flex flex-col items-center">
            <span className="text-sm text-blue-400 font-semibold">
              {power.powerKw.toFixed(2)} kW
            </span>
            <span className="text-xs text-gray-500">
              ${power.costUsd?.toFixed(4) ?? '—'}
            </span>
          </div>
        ) : (
          <span className="text-gray-600 text-sm">—</span>
        )}
      </td>

      {/* Last updated */}
      <td className="px-4 py-4 text-center">
        <span className="text-xs text-gray-600">
          {temp?.recordedAt
            ? new Date(temp.recordedAt).toLocaleTimeString()
            : '—'}
        </span>
      </td>
    </tr>
  )
}

export default function ZoneOverview() {
  const [zones, setZones]   = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getAllZones()
      .then(setZones)
      .catch(console.error)
      .finally(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-gray-400">Loading zones...</div>

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-white text-2xl font-semibold">Zone Overview</h1>
        <p className="text-gray-400 text-sm mt-1">
          All zones — latest readings — refreshes every 10 seconds
        </p>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
          <p className="text-xs text-gray-500 uppercase tracking-wider mb-1">Total Zones</p>
          <p className="text-2xl font-semibold text-white">{zones.length}</p>
        </div>
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
          <p className="text-xs text-gray-500 uppercase tracking-wider mb-1">Total Capacity</p>
          <p className="text-2xl font-semibold text-white">
            {zones.reduce((sum, z) => sum + z.capacity, 0)} people
          </p>
        </div>
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-4">
          <p className="text-xs text-gray-500 uppercase tracking-wider mb-1">Active Since</p>
          <p className="text-sm font-medium text-white mt-1">
            {zones[0]?.createdAt
              ? new Date(zones[0].createdAt).toLocaleDateString()
              : '—'}
          </p>
        </div>
      </div>

      {/* Table */}
      <div className="bg-gray-900 border border-gray-800 rounded-2xl overflow-hidden">
        <table className="w-full">
          <thead>
            <tr className="text-xs text-gray-500 uppercase tracking-wider">
              <th className="px-4 py-3 text-left">Zone</th>
              <th className="px-4 py-3 text-center">Capacity</th>
              <th className="px-4 py-3 text-center">Temperature</th>
              <th className="px-4 py-3 text-center">Occupancy</th>
              <th className="px-4 py-3 text-center">HVAC</th>
              <th className="px-4 py-3 text-center">Power</th>
              <th className="px-4 py-3 text-center">Updated</th>
            </tr>
          </thead>
          <tbody>
            {zones.map(zone => (
              <ZoneRow key={zone.id} zone={zone} />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}