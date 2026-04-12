import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import { BrowserRouter } from 'react-router-dom'
import Login from '../pages/Login'

vi.mock('../context/AuthContext', () => ({
  useAuth: () => ({
    login: vi.fn(),
    isAuthenticated: false,
  })
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => vi.fn(),
  }
})

const renderLogin = () => render(
  <BrowserRouter>
    <Login />
  </BrowserRouter>
)

describe('Login Page', () => {
  it('renders the sign in button', () => {
    renderLogin()
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument()
  })

  it('renders the username input', () => {
    renderLogin()
    expect(screen.getByPlaceholderText('admin')).toBeInTheDocument()
  })

  it('renders the password input', () => {
    renderLogin()
    expect(screen.getByPlaceholderText('••••••••')).toBeInTheDocument()
  })

  it('renders the dashboard subtitle', () => {
    renderLogin()
    expect(screen.getByText(/sign in to your dashboard/i)).toBeInTheDocument()
  })

  it('allows typing in username field', async () => {
    renderLogin()
    const usernameInput = screen.getByPlaceholderText('admin')
    await userEvent.type(usernameInput, 'admin')
    expect(usernameInput.value).toBe('admin')
  })

  it('allows typing in password field', async () => {
    renderLogin()
    const passwordInput = screen.getByPlaceholderText('••••••••')
    await userEvent.type(passwordInput, 'energy123')
    expect(passwordInput.value).toBe('energy123')
  })
})
