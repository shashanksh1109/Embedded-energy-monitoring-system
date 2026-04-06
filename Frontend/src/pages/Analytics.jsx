import { useState, useEffect } from 'react'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, ErrorBar
} from 'recharts'
import api from '../api/axios'

const METRICS = [
  { key: 'TEMP',      label: 'Temperature', unit: '°C',     color: '#f97316' },
  { key: 'POWER',     label: 'Power',       unit: ' kW',    color: '#3b82f6' },
  { key: 'OCCUPANCY', label: 'Occupancy',   unit: ' ppl',   color: '#22c55e' },
  { key: 'HVAC_STATE', label: 'HVAC',        unit: '%',      color: '#a855f7' },
]

const fetchLatest = (zone, metric) =>
  api.get(`/analytics/${zone}/latest?metric=${metric}`).then(r => r.data).catch(() => null)

const fetchSummary = (zone) =>
  api.get(`/analytics/${zone}/summary`).then(r => r.data).catch(() => null)

const fetchAll = (metric) =>
  api.get(`/analytics/all?metric=${metric}`).then(r => r.data).catch(() => [])

function StatBox({ label, value, unit, sub, color }) {
  return (
    <div className="bg-gray-800 rounded-xl p-4 flex flex-col gap-1">
      <span className="text-xs text-gray-500 uppercase tracking-wider">{label}</span>
      <span className="text-xl font-semibold" style={{ color }}>
        {value != null ? `${Number(value).toFixed(2)}${unit}` : '—'}
      </span>
      {sub && <span className="text-xs text-gray-500">{sub}</span>}
    </div>
  )
}

function MetricCard({ zone, metric, color, unit }) {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchLatest(zone, metric).then(d => { setData(d); setLoading(false) })
    const iv = setInterval(() =>
      fetchLatest(zone, metric).then(setData), 60000)
    return () => clearInterval(iv)
  }, [zone, metric])

  if (loading) return (
    <div className="bg-gray-900 border border-gray-800 rounded-2xl p-5 animate-pulse h-48" />
  )

  if (!data) return (
    <div className="bg-gray-900 border border-gray-800 rounded-2xl p-5 flex items-center justify-center text-gray-600 text-sm h-48">
      No snapshots yet
    </div>
  )

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-2xl p-5">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-white font-medium text-sm">{metric}</h3>
        <span className="text-xs text-gray-500">{data.sampleCount} samples</span>
      </div>
      <div className="grid grid-cols-2 gap-3 mb-3">
        <StatBox label="Mean"   value={data.meanVal}   unit={unit} color={color} />
        <StatBox label="StdDev" value={data.stddevVal} unit={unit} color="#9ca3af" />
        <StatBox label="Min"    value={data.minVal}    unit={unit} color="#6b7280" />
        <StatBox label="Max"    value={data.maxVal}    unit={unit} color="#6b7280" />
      </div>
      {/* Range bar */}
      <div className="mt-2">
        <div className="flex justify-between text-xs text-gray-500 mb-1">
          <span>{Number(data.minVal).toFixed(1)}{unit}</span>
          <span className="text-gray-400">range: {Number(data.range).toFixed(2)}{unit}</span>
          <span>{Number(data.maxVal).toFixed(1)}{unit}</span>
        </div>
        <div className="h-2 bg-gray-800 rounded-full overflow-hidden">
          <div
            className="h-full rounded-full"
            style={{
              background: color,
              marginLeft: '0%',
              width: '100%',
              opacity: 0.7,
            }}
          />
        </div>
        <div
          className="h-2 rounded-full mt-0.5"
          style={{
            background: color,
            width: `${Math.min(100, (data.stddevVal / (data.range || 1)) * 100 * 2)}%`,
            opacity: 0.4,
          }}
        />
        <p className="text-xs text-gray-600 mt-1">stddev spread</p>
      </div>
      <p className="text-xs text-gray-600 mt-3">
        Snapshot: {new Date(data.snapshotAt).toLocaleTimeString()}
      </p>
    </div>
  )
}

function ZoneComparisonChart({ metric, unit, color }) {
  const [data, setData] = useState([])

  useEffect(() => {
    fetchAll(metric).then(all => {
      setData(all.map(d => ({
        zone: d.zoneName || d.zone_name || Object.values(d)[0],
        mean: parseFloat((d.meanVal || d.mean_val || 0).toFixed(2)),
        stddev: parseFloat((d.stddevVal || d.stddev_val || 0).toFixed(2)),
      })))
    })
    const iv = setInterval(() =>
      fetchAll(metric).then(all => {
        setData(all.map(d => ({
          zone: d.zoneName || d.zone_name || Object.values(d)[0],
          mean: parseFloat((d.meanVal || d.mean_val || 0).toFixed(2)),
          stddev: parseFloat((d.stddevVal || d.stddev_val || 0).toFixed(2)),
        })))
      }), 60000)
    return () => clearInterval(iv)
  }, [metric])

  if (data.length === 0) return null

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-2xl p-5">
      <h3 className="text-white font-medium text-sm mb-4">
        {metric} — All Zones Comparison
      </h3>
      <ResponsiveContainer width="100%" height={160}>
        <BarChart data={data} barSize={40}>
          <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
          <XAxis dataKey="zone" tick={{ fill: '#6b7280', fontSize: 11 }} />
          <YAxis tick={{ fill: '#6b7280', fontSize: 11 }} unit={unit} width={50} />
          <Tooltip
            contentStyle={{ background: '#111', border: '1px solid #333', borderRadius: 6, fontSize: 11 }}
            formatter={(v, n) => [`${v}${unit}`, n]}
          />
          <Bar dataKey="mean" name="Mean" fill={color} radius={[4, 4, 0, 0]} fillOpacity={0.85}>
            <ErrorBar dataKey="stddev" width={4} strokeWidth={2} stroke={color} opacity={0.6} />
          </Bar>
        </BarChart>
      </ResponsiveContainer>
      <p className="text-xs text-gray-600 mt-2">Error bars show ±1 standard deviation</p>
    </div>
  )
}

export default function Analytics() {
  const [zone, setZone]     = useState('Zone_A')
  const [summary, setSummary] = useState(null)

  const zones = ['Zone_A', 'Zone_B', 'Zone_C']

  useEffect(() => {
    fetchSummary(zone).then(setSummary)
  }, [zone])

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-white text-2xl font-semibold">Analytics</h1>
          <p className="text-gray-400 text-sm mt-1">
            60-second statistical snapshots — mean, stddev, min, max
          </p>
        </div>
        <select
          value={zone}
          onChange={e => setZone(e.target.value)}
          className="bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2 focus:outline-none focus:border-blue-500"
        >
          {zones.map(z => <option key={z} value={z}>{z}</option>)}
        </select>
      </div>

      {/* Per-metric snapshot cards */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5 mb-6">
        {METRICS.map(m => (
          <MetricCard
            key={m.key}
            zone={zone}
            metric={m.key}
            color={m.color}
            unit={m.unit}
          />
        ))}
      </div>

      {/* Zone comparison charts */}
      <div className="space-y-5">
        <ZoneComparisonChart metric="TEMP"  unit="°C"   color="#f97316" />
        <ZoneComparisonChart metric="POWER" unit=" kW"  color="#3b82f6" />
      </div>
    </div>
  )
}