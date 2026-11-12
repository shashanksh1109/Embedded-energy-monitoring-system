import { useState, useEffect, useCallback } from 'react'
import { listHubs, pairHub, sendCommand, getHubConfig } from '../api/hubs'
import { assignZone } from '../api/devices'
import { getAllZones } from '../api/zones'
import HubSetup from '../components/HubSetup'

// Hubs page:
//   - "Add hub": type the code shown on the hub's OLED
//   - per hub: online status, outputs with ON/OFF buttons (confirmed state),
//     and its sensors with a zone picker
// Refreshes every 3 seconds, so a switched output shows its confirmed
// state almost immediately.

const inputClass =
  'bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-blue-500'

function timeAgo(value) {
  if (!value) return 'never'
  const seconds = Math.round((Date.now() - new Date(value).getTime()) / 1000)
  if (seconds < 60) return `${seconds}s ago`
  if (seconds < 3600) return `${Math.round(seconds / 60)} min ago`
  return new Date(value).toLocaleString()
}

function AddHubForm({ onPaired }) {
  const [code, setCode] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState(null)

  const submit = async (e) => {
    e.preventDefault()
    setBusy(true)
    setError(null)
    try {
      const result = await pairHub(code.trim())
      setCode('')
      onPaired(result)
    } catch (err) {
      setError(err.response?.data?.error || 'Could not add the hub')
    } finally {
      setBusy(false)
    }
  }

  return (
    <form onSubmit={submit}
          className="bg-gray-900 border border-gray-800 rounded-2xl p-4 mb-6 flex flex-wrap items-end gap-3">
      <div className="flex flex-col">
        <label className="text-xs text-gray-400 mb-1">Code shown on the hub</label>
        <input required className={`${inputClass} font-mono tracking-widest uppercase w-40`}
               value={code} onChange={e => setCode(e.target.value)} placeholder="ABC-DEF" />
      </div>
      <button type="submit" disabled={busy}
              className="bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white rounded-lg px-4 py-2 text-sm font-medium">
        {busy ? 'Adding...' : 'Add hub'}
      </button>
      <p className="text-xs text-gray-500 w-full">
        Power on the hub; its screen shows a 6-character code. The code is valid for 10 minutes.
      </p>
      {error && <p className="w-full text-red-400 text-xs">{error}</p>}
    </form>
  )
}

function OutputRow({ hub, output, state, pending, onSend }) {
  const isOn = state === 'ON'
  return (
    <div className="flex items-center justify-between py-2 border-t border-gray-800">
      <div>
        <p className="text-sm text-white">{output.name}</p>
        <p className="text-xs text-gray-500">{output.kind} on GPIO {output.gpio}</p>
      </div>
      <div className="flex items-center gap-3">
        <span className={`text-xs ${pending ? 'text-amber-400' : isOn ? 'text-green-400' : 'text-gray-500'}`}>
          {pending ? 'switching...' : state ? `${state} (confirmed)` : 'unknown'}
        </span>
        <button disabled={!hub.online || pending} onClick={() => onSend(output.key, 'ON')}
                className={`px-3 py-1 rounded-lg text-xs font-medium disabled:opacity-40 ${
                  isOn ? 'bg-green-600 text-white' : 'bg-gray-800 text-gray-300 hover:bg-gray-700'}`}>
          ON
        </button>
        <button disabled={!hub.online || pending} onClick={() => onSend(output.key, 'OFF')}
                className={`px-3 py-1 rounded-lg text-xs font-medium disabled:opacity-40 ${
                  state === 'OFF' ? 'bg-gray-600 text-white' : 'bg-gray-800 text-gray-300 hover:bg-gray-700'}`}>
          OFF
        </button>
      </div>
    </div>
  )
}

function HubCard({ hub, config, zones, onChanged, onEditSetup }) {
  const [error, setError] = useState(null)

  const states = Object.fromEntries((hub.outputs || []).map(o => [o.target, o.state]))
  const pendingTargets = new Set(
    (hub.recentCommands || []).filter(c => c.status === 'PENDING').map(c => c.target)
  )
  const outputs = config?.config?.outputs || []
  const applied = config && config.appliedVersion === config.version

  const send = async (target, action) => {
    setError(null)
    try {
      await sendCommand(hub.hubDeviceId, target, action)
      onChanged()
    } catch (err) {
      setError(err.response?.data?.error || 'Command failed')
    }
  }

  const placeSensor = async (deviceId, zoneId) => {
    setError(null)
    try {
      await assignZone(deviceId, zoneId || null)
      onChanged()
    } catch (err) {
      setError(err.response?.data?.error || 'Could not place the sensor')
    }
  }

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-2xl p-5">
      <div className="flex items-start justify-between mb-3">
        <div>
          <p className="text-white font-medium font-mono">{hub.thingName}</p>
          <p className="text-xs text-gray-500">{hub.model || 'Hub'} - last seen {timeAgo(hub.lastSeenAt)}</p>
        </div>
        <div className="text-right">
          <span className={`inline-flex items-center gap-2 text-xs ${hub.online ? 'text-green-400' : 'text-gray-500'}`}>
            <span className={`w-2.5 h-2.5 rounded-full ${hub.online ? 'bg-green-400' : 'bg-gray-600'}`} />
            {hub.online ? 'Online' : 'Offline'}
          </span>
          {config && (
            <p className={`text-xs mt-1 ${applied ? 'text-gray-500' : 'text-amber-400'}`}>
              Setup v{config.version} {applied ? 'applied' : '- waiting for the hub'}
            </p>
          )}
          <button onClick={onEditSetup} className="text-xs text-blue-400 hover:text-blue-300 mt-1">
            Hardware setup
          </button>
        </div>
      </div>

      <p className="text-xs text-gray-400 uppercase tracking-wider mt-4 mb-1">Outputs</p>
      {outputs.length === 0 && (
        <p className="text-xs text-gray-500 py-2">No outputs in this hub's hardware setup yet.</p>
      )}
      {outputs.map(o => (
        <OutputRow key={o.key} hub={hub} output={o} state={states[o.key]}
                   pending={pendingTargets.has(o.key)} onSend={send} />
      ))}

      <p className="text-xs text-gray-400 uppercase tracking-wider mt-5 mb-1">Sensors</p>
      {(hub.sensors || []).length === 0 && (
        <p className="text-xs text-gray-500 py-2">No sensors reported yet.</p>
      )}
      {(hub.sensors || []).map(s => (
        <div key={s.device_id} className="flex items-center justify-between py-2 border-t border-gray-800">
          <div>
            <p className="text-sm text-white">{s.display_name || s.local_id}</p>
            <p className="text-xs text-gray-500 font-mono">{s.thing_name} - {s.device_type}</p>
          </div>
          <select className={inputClass} value={s.zone_id || ''}
                  onChange={e => placeSensor(s.device_id, e.target.value)}>
            <option value="">Not placed (ignored)</option>
            {zones.map(z => <option key={z.id} value={z.id}>{z.name}</option>)}
          </select>
        </div>
      ))}

      {!hub.online && (
        <p className="text-xs text-gray-500 mt-3">The hub is offline: outputs can't be switched until it is back.</p>
      )}
      {error && <p className="text-red-400 text-xs mt-3">{error}</p>}
    </div>
  )
}

export default function Hubs() {
  const [hubs, setHubs] = useState([])
  const [configs, setConfigs] = useState({})
  const [zones, setZones] = useState([])
  const [loading, setLoading] = useState(true)
  const [adding, setAdding] = useState(false)
  const [message, setMessage] = useState(null)
  const [editing, setEditing] = useState(null)      // hubDeviceId whose setup is open

  const refresh = useCallback(async () => {
    try {
      const list = await listHubs()
      setHubs(list)
      const entries = await Promise.all(
        list.map(h => getHubConfig(h.hubDeviceId).then(c => [h.hubDeviceId, c]).catch(() => [h.hubDeviceId, null]))
      )
      setConfigs(Object.fromEntries(entries))
    } catch (err) {
      console.error(err)
    }
  }, [])

  useEffect(() => {
    Promise.all([refresh(), getAllZones().then(setZones)])
      .catch(console.error)
      .finally(() => setLoading(false))
    const iv = setInterval(refresh, 3000)
    return () => clearInterval(iv)
  }, [refresh])

  if (loading) return <div className="text-gray-400">Loading hubs...</div>

  // Online hubs first
  const sorted = [...hubs].sort((a, b) => Number(b.online) - Number(a.online))

  return (
    <div>
      <div className="mb-6 flex items-start justify-between">
        <div>
          <h1 className="text-white text-2xl font-semibold">Hubs</h1>
          <p className="text-gray-400 text-sm mt-1">
            Raspberry Pi hubs, their outputs and sensors. Refreshes every 3 seconds.
          </p>
        </div>
        <button onClick={() => { setAdding(!adding); setMessage(null) }}
                className="bg-blue-600 hover:bg-blue-500 text-white rounded-lg px-4 py-2 text-sm font-medium">
          {adding ? 'Close' : '+ Add hub'}
        </button>
      </div>

      {message && <p className="text-green-400 text-sm mb-4">{message}</p>}

      {adding && (
        <AddHubForm onPaired={result => {
          setAdding(false)
          setMessage(`Hub ${result.thingName} added. Its screen now shows CONNECTED.`)
          refresh()
        }} />
      )}

      {editing && hubs.find(h => h.hubDeviceId === editing) && (
        <HubSetup
          key={editing}
          hub={hubs.find(h => h.hubDeviceId === editing)}
          setup={configs[editing]}
          onClose={() => setEditing(null)}
          onSaved={saved => {
            setEditing(null)
            setMessage(`Setup version ${saved.version} saved. The hub applies it within about 15 seconds.`)
            refresh()
          }}
        />
      )}

      {sorted.length === 0 && (
        <div className="bg-gray-900 border border-gray-800 rounded-2xl p-10 text-center text-gray-500 text-sm">
          No hubs yet. Click "+ Add hub" and enter the code shown on your hub.
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {sorted.map(h => (
          <HubCard key={h.hubDeviceId} hub={h} config={configs[h.hubDeviceId]}
                   zones={zones} onChanged={refresh}
                   onEditSetup={() => { setEditing(h.hubDeviceId); setMessage(null) }} />
        ))}
      </div>
    </div>
  )
}