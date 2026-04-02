import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'
import Layout from './components/Layout'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import ZoneOverview from './pages/ZoneOverview'
import Charts from './pages/Charts'
import Analytics from './pages/Analytics'
import Schedules from './pages/Schedules'

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Layout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Dashboard />} />
            <Route path="overview" element={<ZoneOverview />} />
            <Route path="charts" element={<Charts />} />
            <Route path="analytics" element={<Analytics />} />
            <Route path="schedules" element={<Schedules />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
