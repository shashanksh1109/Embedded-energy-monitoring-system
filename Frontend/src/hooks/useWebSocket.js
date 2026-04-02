import { useEffect, useRef, useState } from 'react'
import { Client } from '@stomp/stompjs'
import SockJS from 'sockjs-client'

export function useWebSocket(zone) {
  const [temperature, setTemperature] = useState(null)
  const [occupancy, setOccupancy] = useState(null)
  const [hvac, setHvac] = useState(null)
  const [power, setPower] = useState(null)
  const [connected, setConnected] = useState(false)
  const clientRef = useRef(null)

  useEffect(() => {
    if (!zone) return

    const token = localStorage.getItem('token')

    const client = new Client({
      webSocketFactory: () => new SockJS('/ws'),
      connectHeaders: {
        Authorization: `Bearer ${token}`,
      },
      reconnectDelay: 5000,
      onConnect: () => {
        setConnected(true)

        client.subscribe(`/topic/temperature/${zone}`, (msg) => {
          setTemperature(JSON.parse(msg.body))
        })

        client.subscribe(`/topic/occupancy/${zone}`, (msg) => {
          setOccupancy(JSON.parse(msg.body))
        })

        client.subscribe(`/topic/hvac/${zone}`, (msg) => {
          setHvac(JSON.parse(msg.body))
        })

        client.subscribe(`/topic/power/${zone}`, (msg) => {
          setPower(JSON.parse(msg.body))
        })
      },
      onDisconnect: () => setConnected(false),
      onStompError: () => setConnected(false),
    })

    client.activate()
    clientRef.current = client

    return () => {
      client.deactivate()
    }
  }, [zone])

  return { temperature, occupancy, hvac, power, connected }
}
