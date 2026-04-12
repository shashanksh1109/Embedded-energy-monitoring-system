import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import StatCard from '../components/StatCard'

describe('StatCard', () => {
  it('renders the label', () => {
    render(<StatCard label="Temperature" value="22.5" unit="°C" />)
    expect(screen.getByText('Temperature')).toBeInTheDocument()
  })

  it('renders the value', () => {
    render(<StatCard label="Temperature" value="22.5" unit="°C" />)
    expect(screen.getByText('22.5')).toBeInTheDocument()
  })

  it('renders the unit', () => {
    render(<StatCard label="Temperature" value="22.5" unit="°C" />)
    expect(screen.getByText('°C')).toBeInTheDocument()
  })

  it('renders dash when value is null', () => {
    render(<StatCard label="Temperature" value={null} unit="°C" />)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders the sub text when provided', () => {
    render(<StatCard label="Power" value="5.2" unit="kW" sub="Zone A" />)
    expect(screen.getByText('Zone A')).toBeInTheDocument()
  })

  it('does not render sub text when not provided', () => {
    render(<StatCard label="Power" value="5.2" unit="kW" />)
    expect(screen.queryByText('Zone A')).not.toBeInTheDocument()
  })
})
