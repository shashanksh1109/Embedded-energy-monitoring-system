import { useState, useEffect, useCallback } from 'react'
import { getDevices, registerDevice } from '../api/devices'
import { getAllZones } from '../api/zones'

// Devices page: list every device of the organization, and add new ones.
// Adding a device returns a one-time CLAIM CODE that the physical device
// sends to POST /api/devices/claim to activate itself.

const DEVICE_TYPES = [
  { value: 'TEMP', label: 'Temperature sensor' },
  { value: 'OCCUPANCY', label: 'Occupancy sensor' },
  { value: 'POWER', label: 'Power meter' },
  { value: 'HVAC', label: 'HVAC controller' },
  { value: 'MULTI', label: 'Multi-sensor' },
]

const API_BASE = import.meta.env.VITE_API_URL || `${window.location.origin}/api`

const inputClass =
  'bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-blue-500'

function timeAgo(iso) {
  if (!iso) return 'never'
  const seconds = Math.round((Date.now() - new Date(iso).getTime()) / 1000)
  if (seconds < 60) return `${seconds}s ago`
  if (seconds < 3600) return `${Math.round(seconds / 60)} min ago`
  if (seconds < 86400) return `${Math.round(seconds / 3600)} h ago`
  return new Date(iso).toLocaleDateString()
}

function StatusBadge({ status }) {
  const styles = {
    ACTIVE: 'bg-green-500/15 text-green-400 border-green-500/30',
    PENDING: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
    DISABLED: 'bg-gray-500/15 text-gray-400 border-gray-600',
  }
  return (
    <span className={`px-2 py-0.5 rounded-full border text-xs font-medium ${styles[status] || styles.DISABLED}`}>
      {status}
    </span>
  )
}

/** Shown once, right after a device is added. */
function ClaimCodePanel({ result, onClose }) {
  const [copied, setCopied] = useState(false)
  const code = result.claimCode
  const command =
    `curl -X POST ${API_BASE}/devices/claim -H "Content-Type: application/json" -d '{"code":"${code}"}'`

  const copy = async (text) => {
    try {
      await navigator.clipboard.writeText(text)
      setCopied(true)
      setTimeout(() => setCopied(false), 1500)
    } catch {
      setCopied(false)
    }
  }

  return (
    <div className="bg-slate-900 border border-blue-500/40 rounded-2xl p-5 mb-6">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-white font-medium">Device added: {result.device.deviceId}</p>
          <p className="text-gray-400 text-xs mt-1">
            Use this one-time claim code on the device. It is shown only once and
            expires {new Date(result.claimExpiresAt).toLocaleString()}.
          </p>
        </div>
        <button onClick={onClose} className="text-gray-500 hover:text-white text-sm">Close</button>
      </div>

      <div className="flex items-center gap-3 mt-4">
        <span className="font-mono text-2xl tracking-widest text-blue-300">{code}</span>
        <button onClick={() => copy(code)}
                className="bg-gray-800 hover:bg-gray-700 text-gray-200 rounded-lg px-3 py-1 text-xs">
          {copied ? 'Copied' : 'Copy code'}
        </button>
      </div>

      <p className="text-gray-400 text-xs mt-4 mb-1">On the device, activate it with:</p>
      <pre className="bg-gray-950 border border-gray-800 rounded-lg p-3 text-xs text-gray-300 overflow-x-auto">{command}</pre>
    </div>
  )
}

function AddDeviceForm({ zones, onAdded, onCancel }) {
  const [zoneId, setZoneId] = useState(zones[0]?.id || '')
  const [deviceType, setDeviceType] = useState('TEMP')
  const [displayName, setDisplayName] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState(null)

  if (zones.length === 0) {
    return (
      <div className="bg-gray-900 border border-gray-800 rounded-2xl p-4 mb-6 text-sm text-gray-400">
        Add a zone first (Zone Overview), then add devices to it.
        <button onClick={onCancel} className="ml-3 text-gray-500 hover:text-white">Close</button>
      </div>
    )
  }

  const submit = async (e) => {
    e.preventDefault()
    setBusy(true)
    setError(null)
    try {
      const result = await registerDevice({
        zoneId,
        deviceType,
        displayName: displayName.trim() || null,
      })
      onAdded(result)
    } catch (err) {
      setError(err.response?.data?.error || 'Could not add the device')
    } finally {
      setBusy(false)
    }
  }

  return (
    <form onSubmit={submit}
          className="bg-gray-900 border border-gray-800 rounded-2xl p-4 mb-6 flex flex-wrap items-end gap-3">
      <div className="flex flex-col">
        <label className="text-xs text-gray-400 mb-1">Zone</label>
        <select className={inputClass} value={zoneId} onChange={e => setZoneId(e.target.value)}>
          {zones.map(z => <option key={z.id} value={z.id}>{z.name}</option>)}
        </select>
      </div>
      <div className="flex flex-col">
        <label className="text-xs text-gray-400 mb-1">Type</label>
        <select className={inputClass} value={deviceType} onChange={e => setDeviceType(e.target.value)}>
          {DEVICE_TYPES.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
        </select>
      </div>
      <div className="flex flex-col flex-1 min-w-48">
        <label className="text-xs text-gray-400 mb-1">Name (optional)</label>
        <input maxLength={120} className={inputClass} value={displayName}
               onChange={e => setDisplayName(e.target.value)} placeholder="Window sensor" />
      </div>
      <button type="submit" disabled={busy}
              className="bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white rounded-lg px-4 py-2 text-sm font-medium">
        {busy ? 'Adding...' : 'Add device'}
      </button>
      <button type="button" onClick={onCancel} className="text-gray-400 hover:text-white text-sm px-2 py-2">
        Cancel
      </button>
      {error && <p className="w-full text-red-400 text-xs">{error}</p>}
    </form>
  )
}

export default function Devices() {
  const [devices, setDevices] = useState([])
  const [zones, setZones] = useState([])
  const [loading, setLoading] = useState(true)
  const [adding, setAdding] = useState(false)
  const [lastAdded, setLastAdded] = useState(null)

  const refresh = useCallback(() =>
    getDevices().then(setDevices).catch(console.error), [])

  useEffect(() => {
    Promise.all([getDevices(), getAllZones()])
      .then(([d, z]) => { setDevices(d); setZones(z) })
      .catch(console.error)
      .finally(() => setLoading(false))
    const iv = setInterval(refresh, 15000)      // status and "online" update on their own
    return () => clearInterval(iv)
  }, [refresh])

  if (loading) return <div className="text-gray-400">Loading devices...</div>

  return (
    <div>
      <div className="mb-6 flex items-start justify-between">
        <div>
          <h1 className="text-white text-2xl font-semibold">Devices</h1>
          <p className="text-gray-400 text-sm mt-1">
            Sensors and controllers in your organization. Refreshes every 15 seconds.
          </p>
        </div>
        {!adding && (
          <button onClick={() => { setAdding(true); setLastAdded(null) }}
                  className="bg-blue-600 hover:bg-blue-500 text-white rounded-lg px-4 py-2 text-sm font-medium">
            + Add device
          </button>
        )}
      </div>

      {lastAdded && <ClaimCodePanel result={lastAdded} onClose={() => setLastAdded(null)} />}

      {adding && (
        <AddDeviceForm
          zones={zones}
          onAdded={result => {
            setLastAdded(result)
            setAdding(false)
            setDevices(prev => [...prev, result.device])
          }}
          onCancel={() => setAdding(false)}
        />
      )}

      <div className="bg-gray-900 border border-gray-800 rounded-2xl overflow-hidden">
        <table className="w-full">
          <thead>
            <tr className="text-xs text-gray-500 uppercase tracking-wider">
              <th className="px-4 py-3 text-left">Device</th>
              <th className="px-4 py-3 text-left">Type</th>
              <th className="px-4 py-3 text-left">Zone</th>
              <th className="px-4 py-3 text-center">Status</th>
              <th className="px-4 py-3 text-center">Online</th>
              <th className="px-4 py-3 text-center">Last seen</th>
            </tr>
          </thead>
          <tbody>
            {devices.map(d => (
              <tr key={d.id} className="border-t border-gray-800">
                <td className="px-4 py-3">
                  <p className="text-white text-sm font-mono">{d.deviceId}</p>
                  {d.displayName && <p className="text-gray-500 text-xs">{d.displayName}</p>}
                </td>
                <td className="px-4 py-3 text-sm text-gray-300">{d.deviceType}</td>
                <td className="px-4 py-3 text-sm text-gray-300">{d.zoneName || '-'}</td>
                <td className="px-4 py-3 text-center"><StatusBadge status={d.status} /></td>
                <td className="px-4 py-3 text-center">
                  <span className={`inline-block w-2.5 h-2.5 rounded-full ${d.online ? 'bg-green-400' : 'bg-gray-600'}`}
                        title={d.online ? 'Online' : 'Offline'} />
                </td>
                <td className="px-4 py-3 text-center text-xs text-gray-500">{timeAgo(d.lastSeenAt)}</td>
              </tr>
            ))}
            {devices.length === 0 && (
              <tr className="border-t border-gray-800">
                <td colSpan={6} className="px-4 py-10 text-center text-gray-500 text-sm">
                  No devices yet. Click "+ Add device" to connect your first sensor.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}