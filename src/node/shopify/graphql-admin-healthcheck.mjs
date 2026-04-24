import { createReportContext, writeSummary } from "../lib/reporting.mjs";

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

async function main() {
  const report = await createReportContext("shopify-admin-healthcheck");
  const summary = {
    action: "shopify-admin-healthcheck",
    status: "running",
    startedAt: report.startedAt,
    inputs: {
      storeDomain: process.env.SHOPIFY_STORE_DOMAIN ?? null,
      apiVersion: process.env.SHOPIFY_ADMIN_API_VERSION ?? null
    },
    results: {},
    validation: [],
    errors: []
  };

  try {
    const storeDomain = requireEnv("SHOPIFY_STORE_DOMAIN");
    const accessToken = requireEnv("SHOPIFY_ADMIN_ACCESS_TOKEN");
    const apiVersion = requireEnv("SHOPIFY_ADMIN_API_VERSION");
    const endpoint = `https://${storeDomain}/admin/api/${apiVersion}/graphql.json`;

    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Shopify-Access-Token": accessToken
      },
      body: JSON.stringify({
        query: `
          query Healthcheck {
            shop {
              name
              primaryDomain {
                host
                url
              }
            }
          }
        `
      })
    });

    const payload = await response.json();
    if (!response.ok || payload.errors) {
      throw new Error(`Shopify GraphQL request failed with status ${response.status}.`);
    }

    summary.status = "success";
    summary.results.shop = payload.data.shop;
    summary.validation.push({
      type: "shopify-admin-graphql",
      status: "passed",
      details: "Shopify Admin GraphQL respondeu com dados da loja."
    });
  } catch (error) {
    summary.status = "failed";
    summary.errors.push({
      message: error.message
    });
    throw error;
  } finally {
    await writeSummary(report.summaryPath, summary);
    console.log(`Report: ${report.summaryPath}`);
  }
}

main().catch(() => {
  process.exitCode = 1;
});
