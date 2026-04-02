import { NavLink } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

const links = [
  { to: '/',          label: 'Dashboard',    icon: '⚡' },
  { to: '/overview',  label: 'Zone Overview', icon: '🏢' },
  { to: '/charts',    label: 'Charts',        icon: '📈' },
  { to: '/analytics', label: 'Analytics',     icon: '📊' },
  { to: '/schedules', label: 'Schedules',     icon: '📅' },
]

export default function Sidebar() {
  const { username, logout } = useAuth()

  return (
    <aside className="w-56 bg-gray-900 border-r border-gray-800 flex flex-col h-screen fixed left-0 top-0">
      {/* Logo */}
      <div className="px-6 py-5 border-b border-gray-800">
        <h1 className="text-white font-semibold text-sm">⚡ Energy Monitor</h1>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 space-y-1">
        {links.map(link => (
          <NavLink
            key={link.to}
            to={link.to}
            end={link.to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors ${
                isActive
                  ? 'bg-blue-600/20 text-blue-400'
                  : 'text-gray-400 hover:text-white hover:bg-gray-800'
              }`
            }
          >
            <span>{link.icon}</span>
            <span>{link.label}</span>
          </NavLink>
        ))}
      </nav>

      {/* User + logout */}
      <div className="px-4 py-4 border-t border-gray-800">
        <p className="text-xs text-gray-500 mb-2">{username}</p>
        <button
          onClick={logout}
          className="w-full text-left text-xs text-gray-400 hover:text-red-400 transition-colors"
        >
          Sign out →
        </button>
      </div>
    </aside>
  )
}
