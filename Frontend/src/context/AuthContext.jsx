import { createContext, useContext, useState, useEffect } from 'react'
import { login as loginApi } from '../api/auth'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [token, setToken] = useState(localStorage.getItem('token'))
  const [username, setUsername] = useState(localStorage.getItem('username'))
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const login = async (username, password) => {
    setLoading(true)
    setError(null)
    try {
      const data = await loginApi(username, password)
      localStorage.setItem('token', data.token)
      localStorage.setItem('username', data.username)
      setToken(data.token)
      setUsername(data.username)
      return true
    } catch (err) {
      if (err.response?.status === 401) {
        setError('Invalid username or password')
      } else if (err.response?.status >= 500 || !err.response) {
        setError('Service unavailable — please try again in a moment')
      } else {
        setError('Login failed — please try again')
      }
      return false
    } finally {
      setLoading(false)
    }
  }

  const logout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('username')
    setToken(null)
    setUsername(null)
  }

  return (
    <AuthContext.Provider value={{ token, username, login, logout, loading, error }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
