import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

function getProjectRoot() {
  const currentFilePath = fileURLToPath(import.meta.url);
  return path.resolve(path.dirname(currentFilePath), "..", "..", "..");
}

function getTimestamp() {
  const now = new Date();
  const part = (value) => String(value).padStart(2, "0");
  return `${now.getFullYear()}${part(now.getMonth() + 1)}${part(now.getDate())}-${part(now.getHours())}${part(now.getMinutes())}${part(now.getSeconds())}`;
}

export async function createReportContext(action) {
  const projectRoot = getProjectRoot();
  const reportsSubdir = process.env.PROJECT_REPORTS_SUBDIR?.trim();
  const reportsRoot = reportsSubdir
    ? path.join(projectRoot, "reports", ...reportsSubdir.split(/[\\/]+/).filter(Boolean))
    : path.join(projectRoot, "reports");
  await mkdir(reportsRoot, { recursive: true });

  const safeAction = action.replace(/[^a-zA-Z0-9-]/g, "-").toLowerCase();
  const reportDir = path.join(reportsRoot, `${getTimestamp()}-${safeAction}`);
  await mkdir(reportDir, { recursive: true });

  return {
    action,
    reportDir,
    summaryPath: path.join(reportDir, "summary.json"),
    startedAt: new Date().toISOString()
  };
}

export async function writeSummary(summaryPath, summary) {
  const finalSummary = {
    ...summary,
    finishedAt: new Date().toISOString()
  };

  await writeFile(summaryPath, JSON.stringify(finalSummary, null, 2), "utf8");
}
