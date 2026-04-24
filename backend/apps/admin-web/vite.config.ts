import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// base: '/admin/' — в проде мы сервируем SPA под /admin/ через nginx.
// VITE_BASE=/admin/ пробрасывается через CI, для dev остаётся '/'.
export default defineConfig({
  plugins: [react()],
  server: { port: 5173 },
  base: process.env.VITE_BASE ?? '/',
  build: { outDir: 'dist', sourcemap: true },
  define: {
    'import.meta.env.VITE_API_BASE_URL': JSON.stringify(
      process.env.VITE_API_BASE_URL ?? 'http://localhost:3000',
    ),
  },
});
