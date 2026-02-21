#!/usr/bin/env node
/**
 * Performance Benchmark — WAVE Messenger
 *
 * Запускает тестовый сервер, прогревает каждый endpoint и измеряет
 * avg / min / p95 / max задержки. Помогает выявить узкие места.
 *
 * Запуск:
 *   npm run test:perf
 *   node tests/perf-benchmark.js
 */

"use strict";

const http = require("node:http");
const { spawn } = require("node:child_process");
const path = require("node:path");

const PORT = 3997; // отдельный порт, чтобы не конфликтовать с prod
const BASE = `http://localhost:${PORT}`;

const TS = Date.now();
const TEST_USER = {
  username: `perf${TS}`,
  email:    `perf${TS}@test.local`,
  password: "PerfT3st!X",
};
const TEST_LOGIN = { login: `perf${TS}`, password: "PerfT3st!X" };

// ─── ANSI цвета ───────────────────────────────────────────────────────────────
const C = {
  reset:  "\x1b[0m",
  bold:   "\x1b[1m",
  dim:    "\x1b[2m",
  red:    "\x1b[31m",
  yellow: "\x1b[33m",
  green:  "\x1b[32m",
  cyan:   "\x1b[36m",
};

// ─── HTTP утилиты ────────────────────────────────────────────────────────────

function rawRequest(opts, body = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(opts, (res) => {
      let data = "";
      res.on("data", (ch) => { data += ch; });
      res.on("end", () => {
        let json = null;
        try { json = JSON.parse(data); } catch { /* plain text ok */ }
        resolve({ status: res.statusCode, headers: res.headers, body: json ?? data });
      });
    });
    req.on("error", reject);
    if (body !== null) req.write(typeof body === "string" ? body : JSON.stringify(body));
    req.end();
  });
}

function get(urlPath, cookie = "") {
  return rawRequest({
    hostname: "localhost", port: PORT,
    path: urlPath, method: "GET",
    headers: cookie ? { Cookie: cookie } : {},
  });
}

function post(urlPath, body, cookie = "") {
  const json = JSON.stringify(body);
  return rawRequest({
    hostname: "localhost", port: PORT,
    path: urlPath, method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Content-Length": Buffer.byteLength(json),
      ...(cookie ? { Cookie: cookie } : {}),
    },
  }, json);
}

function del(urlPath, cookie = "") {
  return rawRequest({
    hostname: "localhost", port: PORT,
    path: urlPath, method: "DELETE",
    headers: cookie ? { Cookie: cookie } : {},
  });
}

// ─── Измерение ────────────────────────────────────────────────────────────────

async function benchmark(name, fn, iterations = 12) {
  // Прогрев — 2 запроса без записи результата
  for (let i = 0; i < 2; i++) {
    try { await fn(); } catch { /* ignore warmup errors */ }
  }

  const times = [];
  let errors = 0;

  for (let i = 0; i < iterations; i++) {
    const start = performance.now();
    try {
      await fn();
      times.push(performance.now() - start);
    } catch {
      errors++;
    }
  }

  if (times.length === 0) return { name, error: "все запросы завершились ошибкой" };

  times.sort((a, b) => a - b);
  const avg = times.reduce((s, t) => s + t, 0) / times.length;

  return {
    name,
    avg,
    min: times[0],
    p95: times[Math.floor(times.length * 0.95)] ?? times[times.length - 1],
    max: times[times.length - 1],
    errors,
    iterations,
  };
}

// ─── Управление сервером ──────────────────────────────────────────────────────

function startServer() {
  return new Promise((resolve, reject) => {
    const proc = spawn(
      "node",
      [path.join(__dirname, "..", "server.js")],
      {
        env: { ...process.env, PORT: String(PORT) },
        stdio: ["ignore", "pipe", "pipe"],
      }
    );

    let ready = false;
    const timeout = setTimeout(() => {
      if (!ready) { proc.kill(); reject(new Error("Сервер не стартовал за 15 с")); }
    }, 15_000);

    proc.stdout.on("data", (data) => {
      if (!ready && data.toString().includes("Messenger started")) {
        ready = true;
        clearTimeout(timeout);
        resolve(proc);
      }
    });

    proc.stderr.on("data", (data) => {
      if (process.env.DEBUG) process.stderr.write(data);
    });

    proc.on("exit", (code) => {
      if (!ready) reject(new Error(`Сервер завершился с кодом ${code}`));
    });
  });
}

function waitReady(retries = 25) {
  return new Promise((resolve, reject) => {
    let attempts = 0;
    const try_ = () => {
      const req = http.request(
        { hostname: "localhost", port: PORT, path: "/", method: "HEAD" },
        () => resolve()
      );
      req.on("error", () => {
        if (++attempts >= retries) return reject(new Error("Сервер недоступен"));
        setTimeout(try_, 300);
      });
      req.end();
    };
    try_();
  });
}

// ─── Отчёт ────────────────────────────────────────────────────────────────────

const FAST   = 50;   // < 50 ms  — OK
const MEDIUM = 200;  // < 200 ms — медленно, стоит оптимизировать

function colorMs(ms) {
  const s = ms.toFixed(1) + "ms";
  if (ms < FAST)   return C.green  + s + C.reset;
  if (ms < MEDIUM) return C.yellow + s + C.reset;
  return               C.red    + s + C.reset;
}

const RECOMMENDATIONS = {
  "login":         "bcrypt — ожидаемо медленный (безопасность). Снизьте saltRounds с 10→8 для dev.",
  "register":      "bcrypt — ожидаемо медленный. В prod оставьте как есть.",
  "conversations": "JSON-файл читается целиком. Рассмотрите кеш в памяти или SQLite.",
  "messages":      "JSON-файл читается целиком. Добавьте пагинацию и кеш.",
  "users":         "Линейный поиск по users[]. Индексируйте users по username/displayName.",
  "app.js":        "Большой бандл (215 KB). Включите gzip/brotli в Express или Nginx.",
  "styles.css":    "Большой CSS (145 KB). Включите gzip. Добавьте Cache-Control: max-age.",
};

function recommend(name) {
  for (const [key, msg] of Object.entries(RECOMMENDATIONS)) {
    if (name.toLowerCase().includes(key)) return msg;
  }
  return null;
}

function printReport(results) {
  console.log(`\n${C.bold}${C.cyan}╔══════════════════════════════════════════════╗${C.reset}`);
  console.log(`${C.bold}${C.cyan}║    WAVE — Performance Benchmark Results      ║${C.reset}`);
  console.log(`${C.bold}${C.cyan}╚══════════════════════════════════════════════╝${C.reset}\n`);

  const W = Math.max(...results.map((r) => r.name.length));

  console.log(
    C.bold +
    "Endpoint".padEnd(W + 2) +
    "avg".padStart(11) +
    "min".padStart(11) +
    "p95".padStart(11) +
    "max".padStart(11) +
    "  errors" +
    C.reset
  );
  console.log("─".repeat(W + 50));

  for (const r of results) {
    if (r.error) {
      console.log(`${r.name.padEnd(W + 2)}  ${C.red}ОШИБКА: ${r.error}${C.reset}`);
      continue;
    }
    const err = r.errors > 0
      ? `${C.red}${r.errors}${C.reset}`
      : `${C.dim}0${C.reset}`;
    console.log(
      r.name.padEnd(W + 2) +
      ("  " + colorMs(r.avg)).padStart(19) +
      ("  " + colorMs(r.min)).padStart(19) +
      ("  " + colorMs(r.p95)).padStart(19) +
      ("  " + colorMs(r.max)).padStart(19) +
      "  " + err
    );
  }

  console.log("─".repeat(W + 50));

  const slow = results.filter((r) => !r.error && r.avg >= MEDIUM);
  if (slow.length === 0) {
    console.log(`\n${C.green}${C.bold}✓ Все endpoint'ы в норме (avg < ${MEDIUM} ms).${C.reset}`);
  } else {
    console.log(`\n${C.yellow}${C.bold}⚠ Медленные endpoint'ы (avg ≥ ${MEDIUM} ms):${C.reset}`);
    for (const r of slow) {
      console.log(`  ${C.red}✗${C.reset} ${r.name}  avg=${r.avg.toFixed(1)}ms`);
      const rec = recommend(r.name);
      if (rec) console.log(`    ${C.dim}→ ${rec}${C.reset}`);
    }
  }

  console.log(
    `\n${C.green}■${C.reset} < ${FAST}ms — быстро  ` +
    `${C.yellow}■${C.reset} < ${MEDIUM}ms — приемлемо  ` +
    `${C.red}■${C.reset} ≥ ${MEDIUM}ms — медленно\n`
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`${C.cyan}Запуск тестового сервера на порту ${PORT}...${C.reset}`);
  const proc = await startServer();
  await waitReady();
  console.log(`${C.green}Сервер готов. Запускаем бенчмарки...${C.reset}\n`);

  let cookie = "";

  try {
    // ── Подготовка: регистрация + вход ──────────────────────────────────────
    process.stdout.write(`${C.dim}Создаю тестового пользователя...${C.reset}\n`);
    await post("/api/auth/register", TEST_USER);
    const loginRes = await post("/api/auth/login", TEST_LOGIN);
    const setCookie = loginRes.headers["set-cookie"];
    if (setCookie) cookie = setCookie.map((c) => c.split(";")[0]).join("; ");
    if (!cookie) console.warn(`${C.yellow}Не удалось получить cookie — некоторые тесты упадут${C.reset}`);

    // ── Статические файлы ────────────────────────────────────────────────────
    const staticResults = await Promise.all([
      benchmark("GET /",           () => get("/"),           15),
      benchmark("GET /app.js",     () => get("/app.js"),     15),
      benchmark("GET /styles.css", () => get("/styles.css"), 15),
      benchmark("GET /sw.js",      () => get("/sw.js"),      15),
    ]);

    // ── API (последовательно — не создавать нагрузку параллельно) ────────────
    const apiResults = [];
    for (const [name, fn, n] of [
      ["POST /api/auth/login",    () => post("/api/auth/login", TEST_LOGIN), 5],
      ["GET  /api/auth/me",       () => get("/api/auth/me",       cookie),  15],
      ["GET  /api/users?q=",      () => get("/api/users?q=",      cookie),  15],
      ["GET  /api/conversations", () => get("/api/conversations", cookie),  15],
    ]) {
      process.stdout.write(`  ${C.dim}${name}${C.reset}\r`);
      apiResults.push(await benchmark(name, fn, n));
    }
    process.stdout.write(" ".repeat(50) + "\r");

    printReport([...staticResults, ...apiResults]);

  } finally {
    // ── Очистка ──────────────────────────────────────────────────────────────
    process.stdout.write(`${C.dim}Удаляю тестового пользователя...${C.reset}\n`);
    await del("/api/auth/account", cookie).catch(() => {});
    proc.kill();
    console.log(`${C.dim}Тестовый сервер остановлен.${C.reset}`);
  }
}

main().catch((err) => {
  console.error(`\n${C.red}Бенчмарк упал: ${err.message}${C.reset}`);
  process.exit(1);
});
