import { expect, test } from "@playwright/test";

test("home page shows the product name", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { level: 1, name: "TakeoutPick" })).toBeVisible();
});

test("health endpoint responds", async ({ request }) => {
  const res = await request.get("/api/v1/health");
  expect(res.ok()).toBe(true);
  expect(await res.json()).toEqual({ data: { status: "ok" } });
});
