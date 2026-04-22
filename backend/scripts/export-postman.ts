import * as fs from 'node:fs';
import * as path from 'node:path';

/**
 * Простая конвертация OpenAPI v3 → Postman v2.1 collection (основная структура).
 * Не все OpenAPI-фичи поддерживаются (auth, примеры, сложные $ref — упрощённо).
 * Мобильщикам проще: импорт openapi.v1.json напрямую в Postman через "Import → OpenAPI".
 *
 * Usage: npm run postman:export  (после openapi:export)
 */

interface OpenAPIPaths {
  [path: string]: {
    [method: string]: {
      summary?: string;
      tags?: string[];
      parameters?: Array<{ name: string; in: string; required?: boolean; schema?: any }>;
      requestBody?: { content?: any };
      responses?: any;
      description?: string;
    };
  };
}

interface PostmanItem {
  name: string;
  request: {
    method: string;
    header: any[];
    url: { raw: string; host: string[]; path: string[] };
    body?: any;
  };
}

interface PostmanCollection {
  info: { _postman_id: string; name: string; schema: string };
  item: Array<{ name: string; item: PostmanItem[] }>;
  variable: Array<{ key: string; value: string }>;
  auth?: any;
}

function convertPath(apiPath: string, method: string, op: any): PostmanItem {
  // `/api/projects/{projectId}/chats` → `{{baseUrl}}/api/projects/:projectId/chats`
  const pathParts = apiPath
    .split('/')
    .filter(Boolean)
    .map((p) => p.replace(/\{(\w+)\}/g, ':$1'));

  const item: PostmanItem = {
    name: op.summary ?? `${method.toUpperCase()} ${apiPath}`,
    request: {
      method: method.toUpperCase(),
      header: [{ key: 'Content-Type', value: 'application/json' }],
      url: {
        raw: `{{baseUrl}}${apiPath}`,
        host: ['{{baseUrl}}'],
        path: pathParts,
      },
    },
  };
  if (op.requestBody?.content?.['application/json']) {
    item.request.body = {
      mode: 'raw',
      raw: '{}',
      options: { raw: { language: 'json' } },
    };
  }
  return item;
}

async function main(): Promise<void> {
  const specPath = path.resolve(__dirname, '..', 'docs', 'openapi.v1.json');
  if (!fs.existsSync(specPath)) {
    throw new Error(`Missing ${specPath}. Run npm run openapi:export first.`);
  }
  const spec = JSON.parse(fs.readFileSync(specPath, 'utf-8'));
  const paths = (spec.paths ?? {}) as OpenAPIPaths;

  const byTag: Record<string, PostmanItem[]> = {};
  for (const [p, methods] of Object.entries(paths)) {
    for (const [m, op] of Object.entries(methods)) {
      if (!['get', 'post', 'put', 'patch', 'delete'].includes(m)) continue;
      const tag = (op.tags && op.tags[0]) ?? 'default';
      (byTag[tag] ??= []).push(convertPath(p, m, op));
    }
  }

  const collection: PostmanCollection = {
    info: {
      _postman_id: 'repair-control-v1',
      name: 'Repair Control API v1.0',
      schema: 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
    },
    item: Object.entries(byTag).map(([tag, items]) => ({
      name: tag,
      item: items.sort((a, b) => a.name.localeCompare(b.name)),
    })),
    variable: [
      { key: 'baseUrl', value: 'http://localhost:3000' },
      { key: 'accessToken', value: '' },
    ],
    auth: {
      type: 'bearer',
      bearer: [{ key: 'token', value: '{{accessToken}}', type: 'string' }],
    },
  };

  const outPath = path.resolve(__dirname, '..', 'postman', 'repair-control.v1.json');
  fs.writeFileSync(outPath, JSON.stringify(collection, null, 2), 'utf-8');
  const totalItems = Object.values(byTag).reduce((acc, items) => acc + items.length, 0);
  console.log(`Postman collection exported: ${outPath}`);
  console.log(`Total requests: ${totalItems} (in ${Object.keys(byTag).length} folders)`);
}

main().catch((e) => {
  console.error('export-postman failed:', e);
  process.exit(1);
});
