import { useState, useEffect } from 'react'
import { getAllZones } from '../api/zones'
import { getLatestTemperature } from '../api/temperature'
import { getLatestOccupancy } from '../api/occupancy'
import { getLatestHvac } from '../api/hvac'
import { getLatestPower } from '../api/power'
import { getMode, setSimulationMode, setHardwareMode } from '../api/mode'
import StatCard from '../components/StatCard'
import { LineChart, Line, ResponsiveContainer, Tooltip } from 'recharts'

function SparkLine({ data, dataKey, color }) {
  if (!data || data.length === 0) return <div className="h-12 flex items-center justify-center text-gray-600 text-xs">no data</div>
  return (
    <ResponsiveContainer width="100%" height={48}>
      <LineChart data={data}>
        <Line type="monotone" dataKey={dataKey} stroke={color} dot={false} strokeWidth={1.5} />
        <Tooltip
          contentStyle={{ background: '#111', border: '1px solid #333', borderRadius: 6, fontSize: 11 }}
          labelFormatter={() => ''}
          formatter={(v) => [v?.toFixed(2), '']}
        />
      </LineChart>
    </ResponsiveContainer>
  )
}

function HvacBadge({ mode }) {
  const styles = {
    HEATING: 'bg-orange-500/20 text-orange-400 border-orange-500/30',
    COOLING: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
    IDLE:    'bg-gray-500/20 text-gray-400 border-gray-500/30',
  }
  const icons = { HEATING: '🔥', COOLING: '❄️', IDLE: '💤' }
  const style = styles[mode] || styles.IDLE
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full border text-xs font-medium ${style}`}>
      {icons[mode] || '💤'} {mode || 'IDLE'}
    </span>
  )
}

function ZonePanel({ zone }) {
  const [temp, setTemp] = useState(null)
  const [occ, setOcc] = useState(null)
  const [hvac, setHvac] = useState(null)
  const [power, setPower] = useState(null)
  const [tempHistory, setTempHistory] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchAll = async () => {
      try {
        const [t, o, h, p] = await Promise.all([
          getLatestTemperature(zone.id).catch(() => null),
          getLatestOccupancy(zone.id).catch(() => null),
          getLatestHvac(zone.id).catch(() => null),
          getLatestPower(zone.id).catch(() => null),
        ])
        setTemp(t)
        setOcc(o)
        setHvac(h)
        setPower(p)
        if (t) setTempHistory(prev => [...prev.slice(-19), { v: t.valueC }])
      } finally {
        setLoading(false)
      }
    }
    fetchAll()
    const interval = setInterval(fetchAll, 5000)
    return () => clearInterval(interval)
  }, [zone.id])

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-white font-medium">{zone.name}</h2>
        {hvac && <HvacBadge mode={hvac.mode} />}
      </div>
      {loading ? (
        <div className="text-gray-500 text-sm">Loading...</div>
      ) : (
        <>
          <div className="grid grid-cols-2 gap-3 mb-4">
            <StatCard label="Temperature" value={temp ? `${temp.valueC?.toFixed(1)}°C` : '—'} color="orange" />
            <StatCard label="Occupancy"   value={occ  ? `${occ.peopleCount} ppl`        : '—'} color="blue"   />
            <StatCard label="Setpoint"    value={hvac ? `${hvac.setpointC?.toFixed(1)}°C`: '—'} color="green"  />
            <StatCard label="Power"       value={power? `${power.powerKw?.toFixed(2)} kW`: '—'} color="purple" />
          </div>
          <div>
            <p className="text-xs text-gray-500 mb-1">Temperature trend</p>
            <SparkLine data={tempHistory} dataKey="v" color="#f97316" />
          </div>
          {temp?.recordedAt && (
            <p className="text-xs text-gray-600 mt-2">
              Last reading: {new Date(temp.recordedAt).toLocaleTimeString()}
            </p>
          )}
        </>
      )}
    </div>
  )
}

// ── Mode Toggle Component ─────────────────────────────────────────────
function ModeToggle() {
  const [mode, setMode]           = useState(null)
  const [sensorRunning, setSensorRunning] = useState(false)
  const [switching, setSwitching] = useState(false)
  const [message, setMessage]     = useState('')

  const fetchMode = async () => {
    try {
      const data = await getMode()
      setMode(data.mode)
      setSensorRunning(data.sensorRunning)
    } catch (e) {
      console.error('Failed to fetch mode', e)
    }
  }

  useEffect(() => {
    fetchMode()
    const interval = setInterval(fetchMode, 10000)
    return () => clearInterval(interval)
  }, [])

  const switchToSimulation = async () => {
    setSwitching(true)
    try {
      const data = await setSimulationMode()
      setMode(data.mode)
      setMessage(data.message)
      setTimeout(() => setMessage(''), 5000)
      setTimeout(fetchMode, 3000)
    } catch (e) {
      setMessage('Failed to switch mode')
    } finally {
      setSwitching(false)
    }
  }

  const switchToHardware = async () => {
    setSwitching(true)
    try {
      const data = await setHardwareMode()
      setMode(data.mode)
      setMessage(data.message)
      setTimeout(() => setMessage(''), 5000)
      setTimeout(fetchMode, 3000)
    } catch (e) {
      setMessage('Failed to switch mode')
    } finally {
      setSwitching(false)
    }
  }

  if (!mode) return null

  const isSimulation = mode === 'SIMULATION'
  const isHardware   = mode === 'HARDWARE'

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl p-4 mb-6">
      <div className="flex items-center justify-between flex-wrap gap-4">

        {/* Mode indicator */}
        <div className="flex items-center gap-3">
          <div className={`w-2.5 h-2.5 rounded-full ${isSimulation ? 'bg-green-400' : 'bg-blue-400'} animate-pulse`} />
          <div>
            <p className="text-white font-medium text-sm">
              {isSimulation ? '🖥️ Simulation Mode' : '🔌 Hardware Mode (PICsimLAB)'}
            </p>
            <p className="text-gray-500 text-xs mt-0.5">
              {isSimulation
                ? `Sensor service: ${sensorRunning ? 'running' : 'starting...'}`
                : `Waiting for PICsimLAB connection${sensorRunning ? '' : ' — sensor stopped'}`}
            </p>
          </div>
        </div>

        {/* Toggle buttons */}
        <div className="flex gap-2">
          <button
            onClick={switchToSimulation}
            disabled={switching || isSimulation}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all
              ${isSimulation
                ? 'bg-green-500/20 text-green-400 border border-green-500/30 cursor-default'
                : 'bg-gray-800 text-gray-300 border border-gray-700 hover:border-green-500/50 hover:text-green-400'
              } disabled:opacity-50`}
          >
            {switching && isSimulation ? '⏳ Switching...' : '🖥️ Simulation'}
          </button>

          <button
            onClick={switchToHardware}
            disabled={switching || isHardware}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all
              ${isHardware
                ? 'bg-blue-500/20 text-blue-400 border border-blue-500/30 cursor-default'
                : 'bg-gray-800 text-gray-300 border border-gray-700 hover:border-blue-500/50 hover:text-blue-400'
              } disabled:opacity-50`}
          >
            {switching && isHardware ? '⏳ Switching...' : '🔌 Hardware'}
          </button>
        </div>
      </div>

      {/* Hardware mode instructions */}
      {isHardware && (
        <div className="mt-4 p-3 bg-blue-500/10 border border-blue-500/20 rounded-lg">
          <p className="text-blue-300 text-xs font-medium mb-1">📋 Hardware Mode Instructions:</p>
          <ol className="text-blue-200/70 text-xs space-y-0.5 list-decimal list-inside">
            <li>Open PICsimLAB and load energy_monitor.hex</li>
            <li>Make sure Serial Port is set to COM6</li>
            <li>Run serial_bridge.py on Windows</li>
            <li>Press keypad buttons to change zone data</li>
            <li>Dashboard updates every 5 seconds</li>
          </ol>
        </div>
      )}

      {/* Status message */}
      {message && (
        <p className="mt-3 text-xs text-yellow-400">{message}</p>
      )}
    </div>
  )
}

// ── Main Dashboard ────────────────────────────────────────────────────
export default function Dashboard() {
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
      <div className="mb-6">
        <h1 className="text-white text-2xl font-semibold">Live Dashboard</h1>
        <p className="text-gray-400 text-sm mt-1">Real-time sensor data — updates every 5 seconds</p>
      </div>

      {/* Mode toggle */}
      <ModeToggle />

      {/* Zone panels */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-5">
        {zones.map(zone => (
          <ZonePanel key={zone.id} zone={zone} />
        ))}
      </div>
    </div>
  )
}
