import axios from 'axios'

// API URL priority:
// 1. VITE_API_URL environment variable (set at build time)
// 2. Relative /api (works when frontend and API are on same domain)
const API_URL = import.meta.env.VITE_API_URL || '/api'

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Attach the token to every request
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// Session expired or invalid -> back to the login page.
//
// Spring Security answers 403 (with an EMPTY body) when no valid token is
// present, so that case counts as "signed out" too. But our own API also
// returns 403 with a JSON {"error": "..."} body when a signed-in user lacks
// permission (e.g. a VIEWER adding a zone) - that must NOT sign them out.
// The login request itself is excluded, so a wrong password shows an error
// message instead of reloading the page.
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status
    const isLoginRequest = error.config?.url?.includes('/auth/login')
    const isPermissionError = status === 403 && Boolean(error.response?.data?.error)
    if ((status === 401 || status === 403) && !isLoginRequest && !isPermissionError) {
      localStorage.removeItem('token')
      localStorage.removeItem('username')
      localStorage.removeItem('refreshToken')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api