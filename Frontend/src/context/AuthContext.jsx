import { createContext, useContext, useState } from 'react'
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
      if (data.refreshToken) {
        localStorage.setItem('refreshToken', data.refreshToken)
      }
      setToken(data.token)
      setUsername(data.username)
      return true
    } catch (err) {
      // LoginError messages from api/auth.js are written for users
      setError(err.message || 'Login failed — please try again')
      return false
    } finally {
      setLoading(false)
    }
  }

  const logout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('username')
    localStorage.removeItem('refreshToken')
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