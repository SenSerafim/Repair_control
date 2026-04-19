import { execSync } from 'node:child_process';
import * as fs from 'node:fs';
import * as path from 'node:path';
import * as dotenv from 'dotenv';

/**
 * Глобальный setup перед e2e: подгружает .env.test в process.env,
 * применяет миграции к тестовой БД и посев 8 платформенных шаблонов.
 *
 * Требование: postgres должен быть поднят (docker compose up -d postgres).
 * БД `repair_control_test` создаётся автоматически через prisma migrate deploy.
 */
export default async function globalSetup(): Promise<void> {
  const envPath = path.resolve(__dirname, '../../../.env.test');
  if (!fs.existsSync(envPath)) {
    throw new Error(`.env.test not found at ${envPath}`);
  }
  const parsed = dotenv.parse(fs.readFileSync(envPath));
  for (const [k, v] of Object.entries(parsed)) {
    process.env[k] = v;
  }

  const cwd = path.resolve(__dirname, '../../..');

  // Создаём БД если её нет
  const defaultUrl = process.env.DATABASE_URL!.replace(/\/[^/?]+\?/, '/postgres?');
  try {
    execSync(
      `psql "${defaultUrl}" -c "SELECT 1 FROM pg_database WHERE datname='repair_control_test'" | grep -q 1 || psql "${defaultUrl}" -c "CREATE DATABASE repair_control_test"`,
      { stdio: 'ignore', shell: '/bin/bash' } as any,
    );
  } catch {
    // psql может быть недоступен — попробуем через node-postgres на ходу при необходимости
  }

  execSync('npx prisma migrate deploy', { cwd, stdio: 'inherit', env: process.env });
  execSync('npx ts-node prisma/seed.ts', { cwd, stdio: 'inherit', env: process.env });
}
