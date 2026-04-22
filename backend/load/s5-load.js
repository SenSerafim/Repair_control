// k6 load test для Repair Control S5 (чаты, лента, экспорты).
//
// Запуск:
//   docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d
//   k6 run backend/load/s5-load.js -e API_URL=http://localhost:3000 -e PHONE=+79990000001 -e PASSWORD=staging-demo-12345
//
// Требуется staging seed (демо-проект demo-project-active).
import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

export const options = {
  scenarios: {
    chat_hot: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '30s', target: 20 },
        { duration: '2m', target: 20 },
        { duration: '30s', target: 0 },
      ],
      exec: 'sendMessage',
    },
    feed_cursor: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '30s', target: 10 },
        { duration: '1m', target: 10 },
        { duration: '30s', target: 0 },
      ],
      exec: 'feedList',
    },
    stage_detail: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '30s', target: 10 },
        { duration: '1m', target: 10 },
        { duration: '30s', target: 0 },
      ],
      exec: 'stageDetail',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],
    'http_req_duration{scenario:feed_cursor}': ['p(95)<200'],
    'http_req_duration{scenario:chat_hot}': ['p(95)<300'],
    http_req_failed: ['rate<0.01'],
    chat_ok: ['rate>0.95'],
    feed_ok: ['rate>0.98'],
  },
};

const API = __ENV.API_URL || 'http://localhost:3000';
const PHONE = __ENV.PHONE || '+79990000001';
const PASSWORD = __ENV.PASSWORD || 'staging-demo-12345';

const chatOk = new Rate('chat_ok');
const feedOk = new Rate('feed_ok');
const latency = new Trend('business_latency');

let cachedToken = null;
let cachedProjectId = null;
let cachedStageId = null;
let cachedChatId = null;

function login() {
  const r = http.post(
    `${API}/api/auth/login`,
    JSON.stringify({ phone: PHONE, password: PASSWORD }),
    { headers: { 'Content-Type': 'application/json' } },
  );
  check(r, { 'login 200': (res) => res.status === 200 });
  cachedToken = r.json('accessToken');
  return cachedToken;
}

function authHeaders() {
  return {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${cachedToken || login()}`,
  };
}

function fetchFirstProjectAndChat() {
  const projResp = http.get(`${API}/api/projects`, { headers: authHeaders() });
  if (projResp.status !== 200) return false;
  const projects = projResp.json('items') || [];
  if (projects.length === 0) return false;
  cachedProjectId = projects[0].id;

  const stagesResp = http.get(`${API}/api/projects/${cachedProjectId}/stages`, {
    headers: authHeaders(),
  });
  const stages = stagesResp.json() || [];
  if (stages.length > 0) cachedStageId = stages[0].id;

  const chatsResp = http.get(`${API}/api/projects/${cachedProjectId}/chats`, {
    headers: authHeaders(),
  });
  const chats = chatsResp.json() || [];
  if (chats.length > 0) cachedChatId = chats[0].id;
  return true;
}

export function setup() {
  const token = login();
  const saved = { token };
  cachedToken = token;
  fetchFirstProjectAndChat();
  saved.projectId = cachedProjectId;
  saved.stageId = cachedStageId;
  saved.chatId = cachedChatId;
  return saved;
}

export function sendMessage(data) {
  if (!data?.chatId) return;
  group('POST /api/chats/:id/messages', () => {
    const start = Date.now();
    const r = http.post(
      `${API}/api/chats/${data.chatId}/messages`,
      JSON.stringify({ text: `k6 load ${__VU}-${__ITER}` }),
      { headers: { ...authHeaders(), Authorization: `Bearer ${data.token}` } },
    );
    latency.add(Date.now() - start, { op: 'chat_send' });
    chatOk.add(r.status === 201);
    check(r, { 'message 201': (res) => res.status === 201 });
  });
  sleep(0.5);
}

export function feedList(data) {
  if (!data?.projectId) return;
  group('GET /api/projects/:id/feed', () => {
    const start = Date.now();
    const r = http.get(`${API}/api/projects/${data.projectId}/feed?limit=50`, {
      headers: { Authorization: `Bearer ${data.token}` },
    });
    latency.add(Date.now() - start, { op: 'feed_list' });
    feedOk.add(r.status === 200);
    check(r, { 'feed 200': (res) => res.status === 200 });
  });
  sleep(0.3);
}

export function stageDetail(data) {
  if (!data?.stageId) return;
  group('GET /api/stages/:id', () => {
    const r = http.get(`${API}/api/stages/${data.stageId}`, {
      headers: { Authorization: `Bearer ${data.token}` },
    });
    check(r, { 'stage 200': (res) => res.status === 200 });
  });
  sleep(0.2);
}
