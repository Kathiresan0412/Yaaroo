import { spawn } from "node:child_process";
import { existsSync } from "node:fs";

const apps = [
  { name: "web", cwd: "frontend/public-site", color: "\x1b[35m" },
  { name: "admin", cwd: "frontend/admin-panel", color: "\x1b[33m" },
];

const reset = "\x1b[0m";
const npmExecPath = process.env.npm_execpath;
const npmCommand = npmExecPath ? process.execPath : process.platform === "win32" ? "npm.cmd" : "npm";
const npmArgs = npmExecPath ? [npmExecPath, "run", "dev"] : ["run", "dev"];
const children = apps.flatMap((app) => {
  const cwd = new URL(`../${app.cwd}/`, import.meta.url);
  const prefix = `${app.color}[${app.name}]${reset}`;

  if (!existsSync(new URL("package.json", cwd))) {
    process.stderr.write(`${prefix} skipped: ${app.cwd}/package.json not found\n`);
    return [];
  }

  const child = spawn(npmCommand, npmArgs, {
    cwd,
    env: process.env,
    stdio: ["ignore", "pipe", "pipe"],
  });

  child.stdout.on("data", (chunk) => process.stdout.write(`${prefix} ${chunk}`));
  child.stderr.on("data", (chunk) => process.stderr.write(`${prefix} ${chunk}`));
  child.on("error", (error) => {
    process.stderr.write(`${prefix} failed to start: ${error.message}\n`);
    shutdown(1);
  });
  child.on("exit", (code, signal) => {
    if (signal) {
      process.stderr.write(`${prefix} exited with signal ${signal}\n`);
      return;
    }

    if (code !== 0) {
      process.stderr.write(`${prefix} exited with code ${code}\n`);
      shutdown(code ?? 1);
    }
  });

  return [child];
});

function shutdown(code = 0) {
  for (const child of children) {
    if (!child.killed) {
      child.kill("SIGTERM");
    }
  }

  setTimeout(() => process.exit(code), 100);
}

process.on("SIGINT", () => shutdown(0));
process.on("SIGTERM", () => shutdown(0));
