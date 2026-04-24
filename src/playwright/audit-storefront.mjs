import { createReportContext, writeSummary } from "../node/lib/reporting.mjs";

async function main() {
  const report = await createReportContext("audit-storefront");
  const summary = {
    action: "audit-storefront",
    status: "running",
    startedAt: report.startedAt,
    inputs: {
      storefrontBaseUrl: process.env.STOREFRONT_BASE_URL ?? null,
      viewport: {
        width: 390,
        height: 844
      }
    },
    results: {},
    validation: [],
    errors: []
  };

  let browser;

  try {
    if (!process.env.STOREFRONT_BASE_URL) {
      throw new Error("Missing required environment variable: STOREFRONT_BASE_URL");
    }

    let playwright;
    try {
      playwright = await import("playwright");
    } catch {
      throw new Error("Playwright is not installed in this environment.");
    }

    browser = await playwright.chromium.launch({ headless: true });
    const page = await browser.newPage({
      viewport: {
        width: 390,
        height: 844
      }
    });

    const response = await page.goto(process.env.STOREFRONT_BASE_URL, {
      waitUntil: "domcontentloaded"
    });

    const title = await page.title();

    if (!response || !response.ok()) {
      throw new Error("Storefront did not respond with a successful status.");
    }

    summary.status = "success";
    summary.results.httpStatus = response.status();
    summary.results.title = title;
    summary.validation.push({
      type: "playwright-live-mobile",
      status: "passed",
      details: "Storefront respondeu em viewport mobile-first."
    });
  } catch (error) {
    summary.status = "failed";
    summary.errors.push({
      message: error.message
    });
    throw error;
  } finally {
    if (browser) {
      await browser.close();
    }

    await writeSummary(report.summaryPath, summary);
    console.log(`Report: ${report.summaryPath}`);
  }
}

main().catch(() => {
  process.exitCode = 1;
});
