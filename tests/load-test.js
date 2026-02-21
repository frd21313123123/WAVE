#!/usr/bin/env node
/**
 * Load Test — WAVE Messenger
 *
 * Имитирует параллельных пользователей и измеряет пропускную способность.
 * Запускайте против уже работающего сервера.
 *
 * Запуск:
 *   npm start                        # сначала поднять сервер
 *   npm run test:load
 *   npm run test:load -- --concurrency=50 --duration=15
 *
 * Параметры:
 *   --port=3000          порт сервера (по умолчанию: $PORT или 3000)
 *   --concurrency=20     число параллельных воркеров
 *   --duration=10        длительность каждого сценария в секундах
 */

"use strict";

const http = require("node:http");

// ─── Аргументы CLI ────────────────────────────────────────────────────────────

const args = Object.fromEntries(
  process.argv
    .slice(2)
    .filter((a) => a.startsWith("--"))
    .map((a) => {
      const [k, v] = a.slice(2).split("=");
      return [k, v ?? true];
    })
);

const PORT        = Number(args.port        ?? process.env.PORT ?? 3000);
const CONCURRENCY = Number(args.concurrency ?? 20);
const DURATION_S  = Number(args.duration    ?? 10);

// ─── ANSI ─────────────────────────────────────────────────────────────────────

const C = {
  reset:  "\x1b[0m",
  bold:   "\x1b[1m",
  dim:    "\x1b[2m",
  red:    "\x1b[31m",
  yellow: "\x1b[33m",
  green:  "\x1b[32m",
  cyan:   "\x1b[36m",
};

// ─── HTTP ─────────────────────────────────────────────────────────────────────

function httpRequest(method, path_, cookie = "") {
  return new Promise((resolve, reject) => {
    const start = performance.now();
    const req = http.request(
      {
        hostname: "localhost",
        port: PORT,
        path: path_,
        method,
        headers: cookie ? { Cookie: cookie } : {},
      },
      (res) => {
        res.resume(); // слить тело, не обрабатывая
        res.on("end", () =>
          resolve({ status: res.statusCode, ms: performance.now() - start })
        );
      }
    );
    req.on("error", reject);
    req.end();
  });
}

function httpPost(path_, body, cookie = "") {
  const json = JSON.stringify(body);
  return new Promise((resolve, reject) => {
    const start = performance.now();
    const req = http.request(
      {
        hostname: "localhost",
        port: PORT,
        path: path_,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(json),
          ...(cookie ? { Cookie: cookie } : {}),
        },
      },
      (res) => {
        let data = "";
        res.on("data", (ch) => { data += ch; });
        res.on("end", () =>
          resolve({
            status: res.statusCode,
            ms: performance.now() - start,
            headers: res.headers,
            body: data,
          })
        );
      }
    );
    req.on("error", reject);
    req.write(json);
    req.end();
  });
}

// ─── Нагрузочный движок ───────────────────────────────────────────────────────

async function runLoad(scenarioFn, durationMs, concurrency, okStatuses = null) {
  const stats = { ok: 0, err: 0, times: [] };
  const endAt = Date.now() + durationMs;
  const isOk = (status) => okStatuses ? okStatuses.has(status) : status < 400;

  async function worker() {
    while (Date.now() < endAt) {
      try {
        const { status, ms } = await scenarioFn();
        if (isOk(status)) { stats.ok++; stats.times.push(ms); }
        else               { stats.err++; }
      } catch {
        stats.err++;
      }
    }
  }

  await Promise.all(Array.from({ length: concurrency }, worker));
  return stats;
}

// ─── Статистика ───────────────────────────────────────────────────────────────

function calcStats(times) {
  if (!times.length) return null;
  const s = [...times].sort((a, b) => a - b);
  const avg = s.reduce((a, b) => a + b, 0) / s.length;
  const p = (pct) => s[Math.min(Math.floor(s.length * pct), s.length - 1)];
  return { avg, min: s[0], p50: p(0.5), p95: p(0.95), p99: p(0.99), max: s[s.length - 1] };
}

function colorMs(ms) {
  const s = ms.toFixed(1) + "ms";
  if (ms < 50)  return C.green  + s + C.reset;
  if (ms < 200) return C.yellow + s + C.reset;
  return              C.red    + s + C.reset;
}

function colorRps(rps) {
  const s = rps.toFixed(1) + " req/s";
  if (rps > 200) return C.green  + s + C.reset;
  if (rps > 50)  return C.yellow + s + C.reset;
  return               C.red    + s + C.reset;
}

function printScenario(label, stats, durationS) {
  const total = stats.ok + stats.err;
  const rps   = stats.ok / durationS;
  const p     = calcStats(stats.times);

  console.log(`\n${C.bold}${label}${C.reset}`);
  console.log(`  Запросов:    ${C.bold}${total}${C.reset} всего  ` +
    `(${C.green}${stats.ok} OK${C.reset} / ` +
    `${stats.err > 0 ? C.red : C.dim}${stats.err} ошибок${C.reset})`);
  console.log(`  Пропускная:  ${colorRps(rps)}`);

  if (p) {
    console.log("  Задержка:");
    console.log(`    avg  ${colorMs(p.avg)}`);
    console.log(`    p50  ${colorMs(p.p50)}`);
    console.log(`    p95  ${colorMs(p.p95)}`);
    console.log(`    p99  ${colorMs(p.p99)}`);
    console.log(`    max  ${colorMs(p.max)}`);
  }
}

// ─── Сценарии ─────────────────────────────────────────────────────────────────

function makeScenarios(cookie) {
  return [
    {
      label: "Статика  GET /",
      fn: () => httpRequest("GET", "/"),
    },
    {
      label: "Статика  GET /app.js",
      fn: () => httpRequest("GET", "/app.js"),
    },
    {
      label: "Статика  GET /styles.css",
      fn: () => httpRequest("GET", "/styles.css"),
    },
    {
      label: "API анон GET /api/auth/me  (401 ожидаем)",
      fn: () => httpRequest("GET", "/api/auth/me"),
      okStatuses: new Set([401, 403]),   // 401 — корректный ответ для анонима
    },
    ...(cookie
      ? [
          {
            label: "API auth GET /api/auth/me",
            fn: () => httpRequest("GET", "/api/auth/me", cookie),
          },
          {
            label: "API auth GET /api/conversations",
            fn: () => httpRequest("GET", "/api/conversations", cookie),
          },
          {
            label: "API auth GET /api/users?q=a",
            fn: () => httpRequest("GET", "/api/users?q=a", cookie),
          },
        ]
      : []),
  ];
}

// ─── Main ─────────────────────────────────────────────────────────────────────

const TS2 = Date.now();
const TEST_USER  = { username: `load${TS2}`, email: `load${TS2}@test.local`, password: "LoadT3st!X" };
const TEST_LOGIN = { login: `load${TS2}`, password: "LoadT3st!X" };

async function main() {
  // Проверить доступность сервера
  try {
    await httpRequest("HEAD", "/");
  } catch {
    console.error(`${C.red}Сервер недоступен на localhost:${PORT}${C.reset}`);
    console.error(`${C.dim}Сначала запустите: npm start${C.reset}`);
    process.exit(1);
  }

  console.log(`${C.bold}${C.cyan}╔═══════════════════════════════╗${C.reset}`);
  console.log(`${C.bold}${C.cyan}║   WAVE — Load Test            ║${C.reset}`);
  console.log(`${C.bold}${C.cyan}╚═══════════════════════════════╝${C.reset}`);
  console.log(`  Воркеры:    ${C.bold}${CONCURRENCY}${C.reset}`);
  console.log(`  Длительность: ${C.bold}${DURATION_S}с${C.reset} на сценарий`);
  console.log(`  Цель:        ${C.bold}localhost:${PORT}${C.reset}`);

  // Регистрация + вход для получения cookie
  let cookie = "";
  try {
    await httpPost("/api/auth/register", TEST_USER);
    const res = await httpPost("/api/auth/login", TEST_LOGIN);
    let parsed;
    try { parsed = JSON.parse(res.body); } catch { /* ignore */ }
    const setCookie = res.headers["set-cookie"];
    if (setCookie) cookie = setCookie.map((c) => c.split(";")[0]).join("; ");
    if (cookie) console.log(`\n${C.dim}Тестовый пользователь создан, cookie получен.${C.reset}`);
    else         console.log(`\n${C.yellow}Не удалось получить cookie — аутентифицированные сценарии пропущены.${C.reset}`);
  } catch {
    console.log(`\n${C.yellow}Не удалось войти — аутентифицированные сценарии пропущены.${C.reset}`);
  }

  // Запуск сценариев
  const scenarios = makeScenarios(cookie);
  for (const { label, fn, okStatuses } of scenarios) {
    process.stdout.write(`\n${C.dim}Запускаю: ${label}...${C.reset}  `);
    const stats = await runLoad(fn, DURATION_S * 1000, CONCURRENCY, okStatuses);
    process.stdout.write("\r" + " ".repeat(60) + "\r");
    printScenario(label, stats, DURATION_S);
  }

  // Итог
  console.log(`\n${C.bold}Советы по оптимизации:${C.reset}`);
  console.log(`  ${C.dim}• Если GET /app.js и /styles.css медленные — добавьте gzip в Express (пакет compression).`);
  console.log(`  • Если API медленные под нагрузкой — JSON-файл db.json читается синхронно; рассмотрите кеш.`);
  console.log(`  • Добавьте Cache-Control: max-age=31536000 для статических ресурсов (иммутабельные файлы).${C.reset}`);
  console.log();

  // Удалить тестового пользователя
  if (cookie) {
    await httpRequest("DELETE", "/api/auth/account", cookie).catch(() => {});
  }
}

main().catch((err) => {
  console.error(`\n${C.red}Нагрузочный тест упал: ${err.message}${C.reset}`);
  process.exit(1);
});
