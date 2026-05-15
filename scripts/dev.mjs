import { spawn } from "node:child_process";

const apps = [
  { name: "api", cwd: "backend", color: "\x1b[36m" },
  { name: "web", cwd: "frontend/public-site", color: "\x1b[35m" },
  { name: "admin", cwd: "frontend/admin-panel", color: "\x1b[33m" },
];

const reset = "\x1b[0m";
const children = apps.map((app) => {
  const child = spawn("npm", ["run", "dev"], {
    cwd: new URL(`../${app.cwd}/`, import.meta.url),
    env: process.env,
    stdio: ["ignore", "pipe", "pipe"],
  });

  const prefix = `${app.color}[${app.name}]${reset}`;
  child.stdout.on("data", (chunk) => process.stdout.write(`${prefix} ${chunk}`));
  child.stderr.on("data", (chunk) => process.stderr.write(`${prefix} ${chunk}`));
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

  return child;
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
