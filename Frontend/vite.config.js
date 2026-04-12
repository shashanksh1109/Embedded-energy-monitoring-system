import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
  ],

  // Vitest configuration
  test: {
    environment: 'jsdom',        // simulate browser DOM
    globals: true,               // use describe/it/expect without imports
    setupFiles: './src/test/setup.js',  // runs before each test file
  },

  server: {
    host: true,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:8081',
        changeOrigin: true,
        configure: (proxy) => {
          proxy.on('error', (err) => console.log('proxy error', err))
          proxy.on('proxyReq', (_, req) => console.log('proxying:', req.method, req.url))
        }
      },
      '/ws': {
        target: 'http://127.0.0.1:8081',
        changeOrigin: true,
        ws: true,
      },
    }
  }
})
