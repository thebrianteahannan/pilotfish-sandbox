import { chromium } from "playwright";
import http from "http";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.join(__dirname, "artifacts", "screenshots");
fs.mkdirSync(outDir, { recursive: true });

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
};

function startServer() {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const urlPath = decodeURIComponent((req.url || "/").split("?")[0]);
      let filePath = path.join(__dirname, urlPath === "/" ? "index.html" : urlPath);
      if (!filePath.startsWith(__dirname)) {
        res.writeHead(403);
        res.end("Forbidden");
        return;
      }
      fs.readFile(filePath, (err, data) => {
        if (err) {
          res.writeHead(404);
          res.end("Not found");
          return;
        }
        const ext = path.extname(filePath).toLowerCase();
        res.writeHead(200, { "Content-Type": MIME[ext] || "application/octet-stream" });
        res.end(data);
      });
    });
    server.listen(0, "127.0.0.1", () => {
      const { port } = server.address();
      resolve({ server, port });
    });
  });
}

const { server, port } = await startServer();
const base = `http://127.0.0.1:${port}`;
console.log("serving", base);

const shots = [
  { name: "01-hero-desktop", width: 1440, height: 900, fullPage: false },
  { name: "02-fullpage-desktop", width: 1440, height: 900, fullPage: true },
  { name: "03-mobile-hero", width: 390, height: 844, fullPage: false },
  { name: "04-mobile-full", width: 390, height: 844, fullPage: true },
];

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

for (const shot of shots) {
  await page.setViewportSize({ width: shot.width, height: shot.height });
  await page.goto(`${base}/`, { waitUntil: "domcontentloaded", timeout: 60000 });
  await page.waitForTimeout(2000);
  await page.evaluate(() => {
    document.querySelectorAll(".reveal").forEach((el) => el.classList.add("is-visible"));
  });
  const file = path.join(outDir, `${shot.name}.png`);
  await page.screenshot({ path: file, fullPage: shot.fullPage });
  console.log("wrote", file);
}

await page.setViewportSize({ width: 1440, height: 900 });
await page.goto(`${base}/`, { waitUntil: "domcontentloaded", timeout: 60000 });
await page.waitForTimeout(1000);
await page.evaluate(() => {
  document.querySelectorAll(".reveal").forEach((el) => el.classList.add("is-visible"));
  document.querySelector("#menu")?.scrollIntoView({ block: "start" });
});
await page.waitForTimeout(400);
const promoPath = path.join(outDir, "05-wings-promo.png");
await page.screenshot({ path: promoPath, fullPage: false });
console.log("wrote", promoPath);

await browser.close();
server.close();
console.log("done");
