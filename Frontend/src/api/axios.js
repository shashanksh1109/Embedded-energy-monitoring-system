import axios from 'axios'
import { refreshAccessToken } from './session'

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

function signOutAndGoToLogin() {
  localStorage.removeItem('token')
  localStorage.removeItem('username')
  localStorage.removeItem('refreshToken')
  window.location.href = '/login'
}

// If several requests fail at the same moment (the dashboard sends many),
// they all wait for ONE refresh instead of each starting their own.
let refreshing = null

// 401 = not signed in, or the access token expired
//   -> try once to get a new access token with the refresh token,
//      then repeat the original request; if that fails, sign out.
// 403 = signed in, but not allowed (e.g. a VIEWER adding a zone)
//   -> never signs out; the page shows the error message.
// The login request itself is excluded, so a wrong password shows an
// error message instead of reloading the page.
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const original = error.config
    const status = error.response?.status
    const isLoginRequest = original?.url?.includes('/auth/login')

    if (status !== 401 || isLoginRequest || !original) {
      return Promise.reject(error)
    }

    if (!original._retried) {
      original._retried = true            // retry each request at most once
      if (!refreshing) {
        refreshing = refreshAccessToken().finally(() => { refreshing = null })
      }
      const newToken = await refreshing
      if (newToken) {
        original.headers.Authorization = `Bearer ${newToken}`
        return api(original)              // same request, new token
      }
    }

    signOutAndGoToLogin()
    return Promise.reject(error)
  }
)

export default api