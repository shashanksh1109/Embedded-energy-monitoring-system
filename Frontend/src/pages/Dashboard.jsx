import { useState, useEffect } from 'react'
import { getAllZones } from '../api/zones'
import { getLatestTemperature } from '../api/temperature'
import { getLatestOccupancy } from '../api/occupancy'
import { getLatestHvac } from '../api/hvac'
import { getLatestPower } from '../api/power'
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
          getLatestTemperature(zone.name),
          getLatestOccupancy(zone.name),
          getLatestHvac(zone.name).catch(() => null),
          getLatestPower(zone.name).catch(() => null),
        ])
        setTemp(t)
        setOcc(o)
        setHvac(h)
        setPower(p)
        setTempHistory(prev => [...prev.slice(-19), { v: t?.temperatureC }])
      } catch (e) {
        // zone may have no data yet
      } finally {
        setLoading(false)
      }
    }

    fetchAll()
    const interval = setInterval(fetchAll, 5000)
    return () => clearInterval(interval)
  }, [zone.name])

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-2xl p-5">

      {/* Zone header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-white font-semibold text-lg">{zone.name}</h2>
          <p className="text-gray-500 text-xs">{zone.description}</p>
        </div>
        <HvacBadge mode={hvac?.mode} />
      </div>

      {loading ? (
        <div className="text-gray-600 text-sm">Loading...</div>
      ) : (
        <>
          {/* Stat cards */}
          <div className="grid grid-cols-2 gap-3 mb-4">
            <StatCard
              label="Temperature"
              value={temp?.temperatureC?.toFixed(1)}
              unit="°C"
              color="orange"
            />
            <StatCard
              label="Occupancy"
              value={occ?.occupancyCount ?? 0}
              unit="people"
              color="green"
            />
            <StatCard
              label="Power"
              value={power?.powerKw?.toFixed(2) ?? '—'}
              unit="kW"
              color="blue"
            />
            <StatCard
              label="Setpoint"
              value={hvac?.setpoint?.toFixed(1) ?? '—'}
              unit="°C"
              color="purple"
            />
          </div>

          {/* Temperature sparkline */}
          <div>
            <p className="text-xs text-gray-500 mb-1">Temperature trend</p>
            <SparkLine data={tempHistory} dataKey="v" color="#f97316" />
          </div>

          {/* Last updated */}
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

export default function Dashboard() {
  const [zones, setZones] = useState([])
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

      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-5">
        {zones.map(zone => (
          <ZonePanel key={zone.id} zone={zone} />
        ))}
      </div>
    </div>
  )
}
