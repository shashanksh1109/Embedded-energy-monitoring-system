import { Outlet } from 'react-router-dom'
import Sidebar from './Sidebar'

export default function Layout() {
  return (
    <div className="min-h-screen bg-gray-950 text-white flex">
      <Sidebar />
      <main className="ml-56 flex-1 p-6 overflow-auto">
        <Outlet />
      </main>
    </div>
  )
}
