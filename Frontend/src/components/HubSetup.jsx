import { useState } from 'react'
import { saveHubConfig } from '../api/hubs'

// Hardware setup editor for one hub: which outputs and sensors are wired
// to which pins. Saving creates a new config version; the hub downloads it
// within about 15 seconds and reports it as applied.
// The backend validates everything again, so a mistake here can never reach
// the hub - this page just makes mistakes hard to make in the first place.

const inputClass =
  'bg-gray-800 border border-gray-700 rounded-lg px-2 py-1.5 text-white text-sm focus:outline-none focus:border-blue-500'

const OUTPUT_KINDS = ['FAN', 'LED', 'RELAY']

const DRIVERS = [
  { value: 'SOC_TEMP', label: 'Pi CPU temperature (built in)' },
  { value: 'BME280', label: 'BME280 temperature (I2C)' },
  { value: 'INA219', label: 'INA219 power (I2C)' },
  { value: 'PIR', label: 'PIR motion (GPIO)' },
]

const I2C_CHOICES = {
  BME280: [0x76, 0x77],
  INA219: Array.from({ length: 16 }, (_, i) => 0x40 + i),
}

// Well-known I2C addresses, to explain what the hub's scan found
const KNOWN_I2C = {
  0x3c: 'OLED display',
  0x3d: 'OLED display',
  0x76: 'BME280 sensor',
  0x77: 'BME280 sensor',
}

const hex = (n) => '0x' + n.toString(16).toUpperCase().padStart(2, '0')

/** "Desk Fan" -> "desk_fan", made unique among the existing keys. */
function makeKey(name, used) {
  let base = name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '').slice(0, 28) || 'item'
  let key = base
  let n = 2
  while (used.has(key)) key = `${base}_${n++}`
  return key
}

export default function HubSetup({ hub, setup, onSaved, onClose }) {
  const [outputs, setOutputs] = useState(() => (setup?.config?.outputs || []).map(o => ({ ...o })))
  const [sensors, setSensors] = useState(() => (setup?.config?.sensors || []).map(s => ({ ...s })))
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState(null)

  const allowedGpio = setup?.allowedGpio || []
  const scan = setup?.scan?.i2c || []

  // Pins and addresses already in use (to offer only free ones)
  const usedGpio = (exceptKey) => new Set(
    [...outputs, ...sensors].filter(i => i.key !== exceptKey && i.gpio != null).map(i => i.gpio)
  )
  const usedI2c = (exceptKey) => new Set(
    sensors.filter(s => s.key !== exceptKey && s.i2cAddress != null).map(s => s.i2cAddress)
  )
  const usedKeys = () => new Set([...outputs, ...sensors].map(i => i.key))
  const firstFreeGpio = () => allowedGpio.find(p => !usedGpio(null).has(p))

  const addOutput = () => {
    const gpio = firstFreeGpio()
    if (gpio == null) { setError('No free GPIO pins left'); return }
    const name = 'New output'
    setOutputs([...outputs, { key: makeKey(name, usedKeys()), name, kind: 'LED', gpio, activeHigh: true }])
  }

  const addSensor = (driver = 'PIR', i2cAddress = null) => {
    const name = DRIVERS.find(d => d.value === driver).label.split(' (')[0]
    const s = { key: makeKey(name, usedKeys()), name, driver }
    if (driver === 'PIR') {
      const gpio = firstFreeGpio()
      if (gpio == null) { setError('No free GPIO pins left'); return }
      s.gpio = gpio
    }
    if (I2C_CHOICES[driver]) {
      s.i2cAddress = i2cAddress ?? I2C_CHOICES[driver].find(a => !usedI2c(null).has(a))
    }
    setSensors([...sensors, s])
  }

  const updateOutput = (i, patch) => setOutputs(outputs.map((o, j) => (j === i ? { ...o, ...patch } : o)))
  const updateSensor = (i, patch) => setSensors(sensors.map((s, j) => (j === i ? { ...s, ...patch } : s)))

  const changeDriver = (i, driver) => {
    const s = { ...sensors[i], driver }
    delete s.gpio
    delete s.i2cAddress
    if (driver === 'PIR') s.gpio = allowedGpio.find(p => !usedGpio(s.key).has(p))
    if (I2C_CHOICES[driver]) s.i2cAddress = I2C_CHOICES[driver].find(a => !usedI2c(s.key).has(a))
    setSensors(sensors.map((x, j) => (j === i ? s : x)))
  }

  const save = async () => {
    setBusy(true)
    setError(null)
    try {
      const saved = await saveHubConfig(hub.hubDeviceId, { outputs, sensors })
      onSaved(saved)
    } catch (err) {
      setError(err.response?.data?.error || 'Could not save the setup')
    } finally {
      setBusy(false)
    }
  }

  const hasSoc = sensors.some(s => s.driver === 'SOC_TEMP')

  return (
    <div className="bg-slate-900 border border-blue-500/40 rounded-2xl p-5 mb-6">
      <div className="flex items-start justify-between mb-4">
        <div>
          <p className="text-white font-medium">Hardware setup: <span className="font-mono">{hub.thingName}</span></p>
          <p className="text-xs text-gray-400 mt-1">
            Current version {setup?.version ?? 0}. Saving creates a new version; the hub applies it within about 15 seconds.
            Free GPIO pins: {allowedGpio.join(', ')}.
          </p>
        </div>
        <button onClick={onClose} className="text-gray-500 hover:text-white text-sm">Close</button>
      </div>

      {/* What the hub's I2C scan found */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl p-3 mb-5 text-xs text-gray-400">
        <span className="text-gray-300">Found by the hub on I2C: </span>
        {scan.length === 0 && 'nothing yet'}
        {scan.map(a => {
          const isBme = a === 0x76 || a === 0x77
          const isIna = a >= 0x40 && a <= 0x4f
          const alreadyAdded = sensors.some(s => s.i2cAddress === a)
          return (
            <span key={a} className="inline-flex items-center gap-2 mr-4">
              <span className="font-mono text-gray-200">{hex(a)}</span>
              <span>{KNOWN_I2C[a] || (isIna ? 'INA219 sensor?' : 'unknown device')}</span>
              {(isBme || isIna) && !alreadyAdded && (
                <button onClick={() => addSensor(isBme ? 'BME280' : 'INA219', a)}
                        className="text-blue-400 hover:text-blue-300">+ add</button>
              )}
            </span>
          )
        })}
      </div>

      {/* Outputs */}
      <div className="flex items-center justify-between mb-2">
        <p className="text-xs text-gray-400 uppercase tracking-wider">Outputs</p>
        <button onClick={addOutput} className="text-blue-400 hover:text-blue-300 text-xs">+ Add output</button>
      </div>
      {outputs.length === 0 && <p className="text-xs text-gray-500 mb-3">No outputs.</p>}
      {outputs.map((o, i) => (
        <div key={o.key} className="flex flex-wrap items-center gap-2 py-2 border-t border-gray-800">
          <input className={`${inputClass} w-40`} value={o.name} maxLength={60}
                 onChange={e => updateOutput(i, { name: e.target.value })} />
          <select className={inputClass} value={o.kind} onChange={e => updateOutput(i, { kind: e.target.value })}>
            {OUTPUT_KINDS.map(k => <option key={k} value={k}>{k}</option>)}
          </select>
          <select className={inputClass} value={o.gpio}
                  onChange={e => updateOutput(i, { gpio: Number(e.target.value) })}>
            {allowedGpio.filter(p => p === o.gpio || !usedGpio(o.key).has(p)).map(p =>
              <option key={p} value={p}>GPIO {p}</option>)}
          </select>
          <label className="text-xs text-gray-400 flex items-center gap-1">
            <input type="checkbox" checked={o.activeHigh !== false}
                   onChange={e => updateOutput(i, { activeHigh: e.target.checked })} />
            on = high
          </label>
          <span className="text-xs text-gray-600 font-mono">{o.key}</span>
          <button onClick={() => setOutputs(outputs.filter((_, j) => j !== i))}
                  className="ml-auto text-xs text-red-400 hover:text-red-300">Remove</button>
        </div>
      ))}

      {/* Sensors */}
      <div className="flex items-center justify-between mt-5 mb-2">
        <p className="text-xs text-gray-400 uppercase tracking-wider">Sensors</p>
        <div className="flex gap-3">
          {!hasSoc && <button onClick={() => addSensor('SOC_TEMP')} className="text-blue-400 hover:text-blue-300 text-xs">+ CPU temperature</button>}
          <button onClick={() => addSensor('PIR')} className="text-blue-400 hover:text-blue-300 text-xs">+ Motion sensor</button>
        </div>
      </div>
      {sensors.length === 0 && <p className="text-xs text-gray-500 mb-3">No sensors.</p>}
      {sensors.map((s, i) => (
        <div key={s.key} className="flex flex-wrap items-center gap-2 py-2 border-t border-gray-800">
          <input className={`${inputClass} w-40`} value={s.name} maxLength={60}
                 onChange={e => updateSensor(i, { name: e.target.value })} />
          <select className={inputClass} value={s.driver} onChange={e => changeDriver(i, e.target.value)}>
            {DRIVERS.filter(d => d.value !== 'SOC_TEMP' || s.driver === 'SOC_TEMP' || !hasSoc).map(d =>
              <option key={d.value} value={d.value}>{d.label}</option>)}
          </select>
          {s.driver === 'PIR' && (
            <select className={inputClass} value={s.gpio}
                    onChange={e => updateSensor(i, { gpio: Number(e.target.value) })}>
              {allowedGpio.filter(p => p === s.gpio || !usedGpio(s.key).has(p)).map(p =>
                <option key={p} value={p}>GPIO {p}</option>)}
            </select>
          )}
          {I2C_CHOICES[s.driver] && (
            <select className={inputClass} value={s.i2cAddress}
                    onChange={e => updateSensor(i, { i2cAddress: Number(e.target.value) })}>
              {I2C_CHOICES[s.driver].filter(a => a === s.i2cAddress || !usedI2c(s.key).has(a)).map(a =>
                <option key={a} value={a}>I2C {hex(a)}</option>)}
            </select>
          )}
          <span className="text-xs text-gray-600 font-mono">{s.key}</span>
          <button onClick={() => setSensors(sensors.filter((_, j) => j !== i))}
                  className="ml-auto text-xs text-red-400 hover:text-red-300">Remove</button>
        </div>
      ))}

      {error && <p className="text-red-400 text-xs mt-4">{error}</p>}
      <div className="flex gap-3 mt-5">
        <button onClick={save} disabled={busy}
                className="bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white rounded-lg px-4 py-2 text-sm font-medium">
          {busy ? 'Saving...' : 'Save setup'}
        </button>
        <button onClick={onClose} className="text-gray-400 hover:text-white text-sm px-2">Cancel</button>
      </div>
      <p className="text-xs text-gray-500 mt-3">
        Removing a sensor here stops the hub from reading it; its history stays in the dashboard.
        Outputs always start OFF after a new setup is applied.
      </p>
    </div>
  )
}