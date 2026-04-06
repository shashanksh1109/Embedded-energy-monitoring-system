import { useState, useEffect } from 'react'
import {
  LineChart, Line, AreaChart, Area,
  XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, ReferenceLine, Legend
} from 'recharts'
import { getAllZones } from '../api/zones'
import { getTemperatureRecent } from '../api/temperature'
import { getPowerRecent } from '../api/power'
import { getHvacRecent } from '../api/hvac'

const HOURS_OPTIONS = [
  { label: '1h',  value: 1  },
  { label: '6h',  value: 6  },
  { label: '24h', value: 24 },
  { label: '48h', value: 48 },
]

function fmt(iso) {
  const d = new Date(iso)
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

function CustomTooltip({ active, payload, label, unit }) {
  if (!active || !payload?.length) return null
  return (
    <div className="bg-gray-900 border border-gray-700 rounded-lg px-3 py-2 text-xs">
      <p className="text-gray-400 mb-1">{label}</p>
      {payload.map((p, i) => (
        <p key={i} style={{ color: p.color }}>
          {p.name}: {p.value?.toFixed(2)}{unit}
        </p>
      ))}
    </div>
  )
}

function ChartCard({ title, children, loading }) {
  return (
    <div className="bg-gray-900 border border-gray-800 rounded-2xl p-5">
      <h3 className="text-white font-medium text-sm mb-4">{title}</h3>
      {loading ? (
        <div className="h-48 flex items-center justify-center text-gray-600 text-sm">
          Loading...
        </div>
      ) : children}
    </div>
  )
}

export default function Charts() {
  const [zones, setZones]       = useState([])
  const [zone, setZone]         = useState('Zone_A')
  const [hours, setHours]       = useState(1)
  const [tempData, setTempData] = useState([])
  const [powerData, setPowerData] = useState([])
  const [hvacData, setHvacData] = useState([])
  const [loading, setLoading]   = useState(true)

  // Load zones
  useEffect(() => {
    getAllZones().then(z => {
      setZones(z)
      if (z.length > 0) setZone(z[0].name)
    })
  }, [])

  // Load chart data when zone or hours changes
  useEffect(() => {
    if (!zone) return
    setLoading(true)

    Promise.all([
      getTemperatureRecent(zone, hours).catch(() => []),
      getPowerRecent(zone, hours).catch(() => []),
      getHvacRecent(zone, hours).catch(() => []),
    ]).then(([temp, power, hvac]) => {
      // Reverse so oldest is first (left to right on chart)
      setTempData([...temp].reverse().map(r => ({
        time: fmt(r.recordedAt),
        temp: parseFloat(r.temperatureC?.toFixed(2)),
      })))

      setPowerData([...power].reverse().map(r => ({
        time: fmt(r.recordedAt),
        kw: parseFloat(r.powerKw?.toFixed(2)),
      })))

      setHvacData([...hvac].reverse().map(r => ({
        time: fmt(r.recordedAt),
        heater: parseFloat(r.heaterPct?.toFixed(1)),
        cooler: parseFloat(r.coolerPct?.toFixed(1)),
        temp:   parseFloat(r.currentTemp?.toFixed(2)),
      })))

      setLoading(false)
    })
  }, [zone, hours])

  // Downsample for readability — max 120 points
  const sample = (arr) => {
    if (arr.length <= 120) return arr
    const step = Math.ceil(arr.length / 120)
    return arr.filter((_, i) => i % step === 0)
  }

  const tData  = sample(tempData)
  const pData  = sample(powerData)
  const hData  = sample(hvacData)

  const tempMin = tData.length ? Math.min(...tData.map(d => d.temp)) - 1 : 18
  const tempMax = tData.length ? Math.max(...tData.map(d => d.temp)) + 1 : 26

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-white text-2xl font-semibold">Charts</h1>
          <p className="text-gray-400 text-sm mt-1">Historical sensor data</p>
        </div>

        {/* Controls */}
        <div className="flex items-center gap-3">
          {/* Zone selector */}
          <select
            value={zone}
            onChange={e => setZone(e.target.value)}
            className="bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2 focus:outline-none focus:border-blue-500"
          >
            {zones.map(z => (
              <option key={z.id} value={z.name}>{z.name}</option>
            ))}
          </select>

          {/* Time range */}
          <div className="flex bg-gray-800 border border-gray-700 rounded-lg overflow-hidden">
            {HOURS_OPTIONS.map(opt => (
              <button
                key={opt.value}
                onClick={() => setHours(opt.value)}
                className={`px-3 py-2 text-sm transition-colors ${
                  hours === opt.value
                    ? 'bg-blue-600 text-white'
                    : 'text-gray-400 hover:text-white'
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="space-y-5">

        {/* Temperature Chart */}
        <ChartCard title={`Temperature — ${zone} (last ${hours}h)`} loading={loading}>
          {tData.length === 0 ? (
            <div className="h-48 flex items-center justify-center text-gray-600 text-sm">
              No data for this period
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={200}>
              <AreaChart data={tData}>
                <defs>
                  <linearGradient id="tempGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor="#f97316" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#f97316" stopOpacity={0}   />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
                <XAxis dataKey="time" tick={{ fill: '#6b7280', fontSize: 10 }} interval="preserveStartEnd" />
                <YAxis domain={[tempMin, tempMax]} tick={{ fill: '#6b7280', fontSize: 10 }} unit="°C" width={45} />
                <Tooltip content={<CustomTooltip unit="°C" />} />
                <ReferenceLine y={24} stroke="#3b82f6" strokeDasharray="4 4" label={{ value: 'Cool', fill: '#3b82f6', fontSize: 10 }} />
                <ReferenceLine y={18} stroke="#f97316" strokeDasharray="4 4" label={{ value: 'Heat', fill: '#f97316', fontSize: 10 }} />
                <Area type="monotone" dataKey="temp" name="Temp" stroke="#f97316" fill="url(#tempGrad)" strokeWidth={2} dot={false} />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* Power Chart */}
        <ChartCard title={`Power Consumption — ${zone} (last ${hours}h)`} loading={loading}>
          {pData.length === 0 ? (
            <div className="h-48 flex items-center justify-center text-gray-600 text-sm">
              No data for this period
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={200}>
              <AreaChart data={pData}>
                <defs>
                  <linearGradient id="powerGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor="#3b82f6" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}   />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
                <XAxis dataKey="time" tick={{ fill: '#6b7280', fontSize: 10 }} interval="preserveStartEnd" />
                <YAxis tick={{ fill: '#6b7280', fontSize: 10 }} unit=" kW" width={50} />
                <Tooltip content={<CustomTooltip unit=" kW" />} />
                <Area type="monotone" dataKey="kw" name="Power" stroke="#3b82f6" fill="url(#powerGrad)" strokeWidth={2} dot={false} />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

        {/* HVAC Chart */}
        <ChartCard title={`HVAC Activity — ${zone} (last ${hours}h)`} loading={loading}>
          {hData.length === 0 ? (
            <div className="h-48 flex items-center justify-center text-gray-600 text-sm">
              No data for this period
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={200}>
              <LineChart data={hData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
                <XAxis dataKey="time" tick={{ fill: '#6b7280', fontSize: 10 }} interval="preserveStartEnd" />
                <YAxis tick={{ fill: '#6b7280', fontSize: 10 }} unit="%" width={40} />
                <Tooltip content={<CustomTooltip unit="%" />} />
                <Legend wrapperStyle={{ fontSize: 11, color: '#9ca3af' }} />
                <Line type="monotone" dataKey="heater" name="Heater" stroke="#f97316" strokeWidth={2} dot={false} />
                <Line type="monotone" dataKey="cooler" name="Cooler" stroke="#3b82f6" strokeWidth={2} dot={false} />
              </LineChart>
            </ResponsiveContainer>
          )}
        </ChartCard>

      </div>
    </div>
  )
}