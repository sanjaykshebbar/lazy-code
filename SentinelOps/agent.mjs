#!/usr/bin/env node
/* SentinelOps PC Agent — self-contained distributed build.
 * Enrols, reports posture + installed-app inventory, and runs approved
 * installs/updates. Installs are SIMULATED unless --real-install / SO_REAL_INSTALL=1.
 * Env: SO_SERVER, SO_ENROLL_TOKEN, SO_CONFIG, SO_LOG, SO_REAL_INSTALL. */
import { readFileSync, writeFileSync, existsSync, mkdirSync, appendFileSync } from "node:fs";
import { homedir } from "node:os";
import os from "node:os";
import { dirname, join } from "node:path";
import { randomUUID, createHash } from "node:crypto";
import { execSync } from "node:child_process";

const VERSION = "0.1.0";
const args = process.argv.slice(2);
const has = (f) => args.includes(f);
const argVal = (f) => { const i = args.indexOf(f); return i >= 0 ? args[i + 1] : undefined; };
const REAL = has("--real-install") || process.env.SO_REAL_INSTALL === "1";
const LOG_FILE = process.env.SO_LOG || null;
function log(...a) {
  const line = "[agent] " + a.join(" ");
  console.log(line);
  if (LOG_FILE) { try { appendFileSync(LOG_FILE, new Date().toISOString() + " " + line + "\n"); } catch {} }
}
const sh = (cmd) => execSync(cmd, { stdio: ["ignore", "pipe", "ignore"], timeout: 8000 }).toString().trim();
const trySh = (cmd) => { try { return sh(cmd); } catch { return ""; } };
const gb = (b) => Math.round((b / 1024 ** 3) * 10) / 10;
const WIN = process.platform === "win32", MAC = process.platform === "darwin";

const CONFIG_PATH = process.env.SO_CONFIG || join(homedir(), ".sentinelops-agent.json");
function loadCfg() {
  let s = {};
  if (existsSync(CONFIG_PATH)) { try { s = JSON.parse(readFileSync(CONFIG_PATH, "utf8")); } catch {} }
  const cfg = {
    serverUrl: (process.env.SO_SERVER || s.serverUrl || "").replace(/\/+$/, ""),
    enrollToken: process.env.SO_ENROLL_TOKEN || s.enrollToken || "",
    serial: s.serial || detectSerial(),
    deviceId: s.deviceId || null,
    agentToken: s.agentToken || null,
    checkinIntervalSec: s.checkinIntervalSec || 300,
  };
  saveCfg(cfg); return cfg;
}
function saveCfg(cfg) { try { mkdirSync(dirname(CONFIG_PATH), { recursive: true }); writeFileSync(CONFIG_PATH, JSON.stringify(cfg, null, 2)); } catch (e) { log("config write failed:", e.message); } }

function detectSerial() {
  let raw = "";
  if (WIN) raw = (trySh('powershell -NoProfile -Command "(Get-CimInstance Win32_BIOS).SerialNumber"') || "").trim();
  else if (MAC) raw = (trySh("ioreg -l | grep IOPlatformSerialNumber").match(/"IOPlatformSerialNumber"\s*=\s*"([^"]+)"/) || [])[1] || "";
  else raw = trySh("cat /sys/class/dmi/id/product_serial");
  raw = (raw || "").split("\n").map((x) => x.trim()).filter(Boolean).pop() || "";
  if (raw && raw.toLowerCase() !== "to be filled by o.e.m." && raw.length >= 4) return raw;
  return "SO-" + createHash("sha1").update(os.hostname() + randomUUID()).digest("hex").slice(0, 12).toUpperCase();
}

const OSN = { win32: "windows", darwin: "macos", linux: "linux" };
function deviceInfo() { return { name: os.hostname(), os: OSN[process.platform] || process.platform, osVersion: os.release(), model: modelName() }; }
function modelName() {
  if (WIN) return trySh('powershell -NoProfile -Command "(Get-CimInstance Win32_ComputerSystem).Model"') || undefined;
  if (MAC) return trySh("sysctl -n hw.model") || undefined;
  return trySh("cat /sys/class/dmi/id/product_name") || undefined;
}
function cpuLoad() {
  const snap = () => os.cpus().reduce((a, c) => { const t = Object.values(c.times).reduce((x, y) => x + y, 0); return { idle: a.idle + c.times.idle, total: a.total + t }; }, { idle: 0, total: 0 });
  const a = snap(); const end = Date.now() + 200; while (Date.now() < end) {} const b = snap();
  const idle = b.idle - a.idle, total = b.total - a.total; if (total <= 0) return null;
  return Math.max(0, Math.min(100, Math.round((1 - idle / total) * 100)));
}
function encryption() {
  if (WIN) { const o = trySh('powershell -NoProfile -Command "(Get-BitLockerVolume -MountPoint C:).ProtectionStatus"'); if (/1|on/i.test(o)) return "on"; if (/0|off/i.test(o)) return "off"; }
  else if (MAC) { const o = trySh("fdesetup status"); if (/On/i.test(o)) return "on"; if (/Off/i.test(o)) return "off"; }
  else { if (/crypt/i.test(trySh("lsblk -o TYPE 2>/dev/null"))) return "on"; }
  return "unknown";
}
function disk() {
  try {
    if (WIN) { const o = trySh('powershell -NoProfile -Command "$d=Get-CimInstance Win32_LogicalDisk -Filter \\"DeviceID=\'C:\'\\"; \\"$($d.Size) $($d.FreeSpace)\\""'); const [s, f] = o.split(/\s+/).map(Number); if (s > 0) return { totalGb: gb(s), freeGb: gb(f) }; }
    else { const l = trySh("df -k /").split("\n").pop().split(/\s+/); const t = Number(l[1]), a = Number(l[3]); if (t > 0) return { totalGb: gb(t * 1024), freeGb: gb(a * 1024) }; }
  } catch {}
  return undefined;
}
function installedApps() {
  try {
    if (WIN) {
      const o = trySh('powershell -NoProfile -Command "Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*,HKLM:\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\* -EA SilentlyContinue | Where-Object DisplayName | Select-Object DisplayName,DisplayVersion | ConvertTo-Json -Compress"');
      const arr = JSON.parse(o || "[]"); const list = Array.isArray(arr) ? arr : [arr];
      return list.filter((a) => a && a.DisplayName).slice(0, 400).map((a) => ({ name: a.DisplayName, version: a.DisplayVersion || "" }));
    } else if (MAC) {
      return trySh("ls -1 /Applications").split("\n").filter((x) => x.endsWith(".app")).slice(0, 400).map((x) => ({ name: x.replace(/\.app$/, ""), version: "" }));
    } else {
      return trySh("dpkg-query -W -f='${Package}\\t${Version}\\n' 2>/dev/null").split("\n").filter(Boolean).slice(0, 500).map((l) => { const [n, v] = l.split("\t"); return { name: n, version: v || "" }; });
    }
  } catch { return []; }
}
function posture() {
  const total = os.totalmem(), free = os.freemem();
  const p = { cpu: { model: os.cpus()[0]?.model?.trim(), loadPct: cpuLoad() }, memory: { totalGb: gb(total), usedGb: gb(total - free) }, encryption: encryption(), loggedInUser: safeUser(), uptimeSec: Math.round(os.uptime()) };
  const d = disk(); if (d) p.disk = d; return p;
}
function safeUser() { try { return os.userInfo().username; } catch { return undefined; } }

async function api(cfg, path, opts = {}) {
  const res = await fetch(cfg.serverUrl + path, opts);
  const txt = await res.text(); let body; try { body = txt ? JSON.parse(txt) : {}; } catch { body = { raw: txt }; }
  if (!res.ok) { const e = new Error(body?.error?.message || ("HTTP " + res.status)); e.status = res.status; throw e; }
  return body;
}
const authHdr = (cfg) => ({ Authorization: "Bearer " + cfg.agentToken, "Content-Type": "application/json" });

function installCmd(software) {
  const q = JSON.stringify(software);
  if (WIN) return "winget install --silent --accept-package-agreements --accept-source-agreements " + q;
  if (MAC) return "brew install --cask " + q + " || brew install " + q;
  return "sudo apt-get install -y " + q;
}
function upgradeCmd(software) {
  const q = JSON.stringify(software);
  if (WIN) return "winget upgrade --silent --accept-package-agreements --accept-source-agreements " + q;
  if (MAC) return "brew upgrade --cask " + q + " || brew upgrade " + q;
  return "sudo apt-get install -y --only-upgrade " + q;
}
function runCmd(kind, software, method) {
  const cmd = kind === "update" ? upgradeCmd(software) : installCmd(software);
  if (!REAL || (method && method !== "agent")) { log("   [simulate] " + kind + ' "' + software + '" via ' + (method || "agent") + " -> " + cmd); return { status: "installed", simulated: true }; }
  try { log("   [" + kind + "] " + cmd); execSync(cmd, { stdio: "inherit", timeout: 20 * 60 * 1000 }); return { status: "installed", simulated: false }; }
  catch (e) { return { status: "failed", simulated: false, error: e.message }; }
}

async function ensureEnrolled(cfg) {
  if (cfg.agentToken && cfg.deviceId) return;
  if (!cfg.serverUrl) throw new Error("SO_SERVER not set");
  if (!cfg.enrollToken) throw new Error("SO_ENROLL_TOKEN not set");
  const info = deviceInfo();
  log("enrolling " + info.name + " (" + info.os + " " + info.osVersion + ")…");
  const r = await api(cfg, "/api/agent/enroll", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ token: cfg.enrollToken, device: { ...info, serial: cfg.serial, agentVersion: VERSION } }) });
  cfg.deviceId = r.deviceId; cfg.agentToken = r.agentToken; if (r.checkinIntervalSec) cfg.checkinIntervalSec = r.checkinIntervalSec; saveCfg(cfg);
  log("enrolled -> deviceId=" + cfg.deviceId);
}
async function cycle(cfg) {
  const p = posture();
  await api(cfg, "/api/agent/telemetry", { method: "POST", headers: authHdr(cfg), body: JSON.stringify({ posture: p, installedApps: installedApps(), agentVersion: VERSION }) });
  log("telemetry sent — cpu " + p.cpu.loadPct + "% · mem " + Math.round(p.memory.usedGb / p.memory.totalGb * 100) + "% · enc " + p.encryption);
  const { commands } = await api(cfg, "/api/agent/commands?claim=1", { headers: authHdr(cfg) });
  if (!commands.length) { log("no pending commands"); return; }
  for (const c of commands) {
    log((c.kind || "install") + ' "' + c.software + '"…');
    const out = runCmd(c.kind || "install", c.software, c.installMethod);
    await api(cfg, "/api/agent/requests/" + c.id + "/result", { method: "POST", headers: authHdr(cfg), body: JSON.stringify({ status: out.status, result: out }) });
    log("-> " + c.software + ": " + out.status + (out.simulated ? " (simulated)" : ""));
  }
}
async function main() {
  const cfg = loadCfg();
  if (has("--status")) { log("config " + CONFIG_PATH); log("server=" + (cfg.serverUrl || "(unset)") + " serial=" + cfg.serial + " deviceId=" + (cfg.deviceId || "(none)") + " enrolled=" + !!cfg.agentToken); return; }
  await ensureEnrolled(cfg);
  if (has("--request")) { const s = argVal("--request"); if (!s) throw new Error('usage: --request "<app>"'); const r = await api(cfg, "/api/agent/requests", { method: "POST", headers: authHdr(cfg), body: JSON.stringify({ software: s, requestedBy: deviceInfo().name }) }); log('requested "' + s + '" -> ' + r.status + (r.requiresApproval ? " (needs approval)" : "")); return; }
  if (has("--once")) { await cycle(cfg); return; }
  log("running v" + VERSION + " — check-in every " + cfg.checkinIntervalSec + "s");
  let busy = false;
  const tick = async () => { if (busy) return; busy = true; try { await cycle(cfg); } catch (e) { log("cycle error:", e.message); } finally { busy = false; } };
  await tick();
  const t = setInterval(tick, cfg.checkinIntervalSec * 1000);
  const stop = (s) => { log("received " + s + ", stopping"); clearInterval(t); process.exit(0); };
  process.on("SIGINT", () => stop("SIGINT")); process.on("SIGTERM", () => stop("SIGTERM"));
}
main().catch((e) => { console.error("[agent] fatal:", e.message); process.exit(1); });
