import { useState, useEffect } from 'react'
import { getAllZones, createZone } from '../api/zones'
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
  const icons = { HEATING: '\u{1F525}', COOLING: '\u2744\uFE0F', IDLE: '\u{1F4A4}' }
  const s = styles[mode] || styles.IDLE
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full border text-xs font-medium ${s}`}>
      {icons[mode] || '\u{1F4A4}'} {mode || 'IDLE'}
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
          <span className="text-gray-600 text-sm">{'\u2014'}</span>
        ) : temp ? (
          <span className={`text-sm font-semibold ${
            temp.temperatureC > 24 ? 'text-blue-400' :
            temp.temperatureC < 18 ? 'text-orange-400' : 'text-green-400'
          }`}>
            {temp.temperatureC.toFixed(1)}{'\u00B0'}C
          </span>
        ) : (
          <span className="text-gray-600 text-sm">{'\u2014'}</span>
        )}
      </td>

      {/* Occupancy */}
      <td className="px-4 py-4 text-center">
        {loading ? (
          <span className="text-gray-600 text-sm">{'\u2014'}</span>
        ) : occ !== null ? (
          <div className="flex items-center justify-center gap-1">
            <span className="text-sm text-white">{occ?.occupancyCount ?? 0}</span>
            <span className="text-xs text-gray-500">/ {zone.capacity}</span>
          </div>
        ) : (
          <span className="text-gray-600 text-sm">{'\u2014'}</span>
        )}
      </td>

      {/* HVAC */}
      <td className="px-4 py-4 text-center">
        {loading ? (
          <span className="text-gray-600 text-sm">{'\u2014'}</span>
        ) : (
          <div className="flex flex-col items-center gap-1">
            <HvacBadge mode={hvac?.mode} />
            {hvac?.setpoint && (
              <span className="text-xs text-gray-500">
                target {hvac.setpoint.toFixed(1)}{'\u00B0'}C
              </span>
            )}
          </div>
        )}
      </td>

      {/* Power */}
      <td className="px-4 py-4 text-center">
        {loading ? (
          <span className="text-gray-600 text-sm">{'\u2014'}</span>
        ) : power ? (
          <div className="flex flex-col items-center">
            <span className="text-sm text-blue-400 font-semibold">
              {power.powerKw.toFixed(2)} kW
            </span>
            <span className="text-xs text-gray-500">
              ${power.costUsd?.toFixed(4) ?? '\u2014'}
            </span>
          </div>
        ) : (
          <span className="text-gray-600 text-sm">{'\u2014'}</span>
        )}
      </td>

      {/* Last updated */}
      <td className="px-4 py-4 text-center">
        <span className="text-xs text-gray-600">
          {temp?.recordedAt
            ? new Date(temp.recordedAt).toLocaleTimeString()
            : '\u2014'}
        </span>
      </td>
    </tr>
  )
}

const inputClass =
  'bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-blue-500'

/** "Add zone" form. Calls POST /api/zones; the backend picks the building and organization. */
function AddZoneForm({ onCreated, onCancel }) {
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [capacity, setCapacity] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState(null)

  const submit = async (e) => {
    e.preventDefault()
    setBusy(true)
    setError(null)
    try {
      const zone = await createZone({
        name: name.trim(),
        description: description.trim() || null,
        capacity: capacity === '' ? 0 : Number(capacity),
      })
      onCreated(zone)
    } catch (err) {
      setError(err.response?.data?.error || 'Could not create the zone')
    } finally {
      setBusy(false)
    }
  }

  return (
    <form onSubmit={submit}
          className="bg-gray-900 border border-gray-800 rounded-2xl p-4 mb-6 flex flex-wrap items-end gap-3">
      <div className="flex flex-col">
        <label className="text-xs text-gray-400 mb-1">Zone name</label>
        <input required maxLength={64} className={inputClass} value={name}
               onChange={e => setName(e.target.value)} placeholder="Conference Room" />
      </div>
      <div className="flex flex-col flex-1 min-w-48">
        <label className="text-xs text-gray-400 mb-1">Description (optional)</label>
        <input maxLength={255} className={inputClass} value={description}
               onChange={e => setDescription(e.target.value)} placeholder="2nd floor, east side" />
      </div>
      <div className="flex flex-col w-28">
        <label className="text-xs text-gray-400 mb-1">Capacity</label>
        <input type="number" min={0} className={inputClass} value={capacity}
               onChange={e => setCapacity(e.target.value)} placeholder="12" />
      </div>
      <button type="submit" disabled={busy}
              className="bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white rounded-lg px-4 py-2 text-sm font-medium">
        {busy ? 'Adding...' : 'Add zone'}
      </button>
      <button type="button" onClick={onCancel}
              className="text-gray-400 hover:text-white text-sm px-2 py-2">
        Cancel
      </button>
      {error && <p className="w-full text-red-400 text-xs">{error}</p>}
    </form>
  )
}

export default function ZoneOverview() {
  const [zones, setZones]   = useState([])
  const [loading, setLoading] = useState(true)
  const [adding, setAdding] = useState(false)

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
      <div className="mb-6 flex items-start justify-between">
        <div>
          <h1 className="text-white text-2xl font-semibold">Zone Overview</h1>
          <p className="text-gray-400 text-sm mt-1">
            All zones {'\u2014'} latest readings {'\u2014'} refreshes every 10 seconds
          </p>
        </div>
        {!adding && (
          <button onClick={() => setAdding(true)}
                  className="bg-blue-600 hover:bg-blue-500 text-white rounded-lg px-4 py-2 text-sm font-medium">
            + Add zone
          </button>
        )}
      </div>

      {adding && (
        <AddZoneForm
          onCreated={zone => {
            setZones(prev => [...prev, zone])     // show it right away, no reload
            setAdding(false)
          }}
          onCancel={() => setAdding(false)}
        />
      )}

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
              : '\u2014'}
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
            {zones.length === 0 && (
              <tr className="border-t border-gray-800">
                <td colSpan={7} className="px-4 py-10 text-center text-gray-500 text-sm">
                  No zones yet {'\u2014'} click "+ Add zone" to create your first one.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}