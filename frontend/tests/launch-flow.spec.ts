import { expect, test } from "@playwright/test";

test("learner launch, submission, instructor grading, and admin console flow", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("button", { name: /launch as learner/i }).click();
  await expect(page.getByText(/learner activity is ready/i)).toBeVisible();

  await page.locator(".activity-panel textarea").fill("A membrane protects the cell and controls transport.");
  await page.getByRole("button", { name: /submit activity/i }).click();
  await expect(page.getByText(/activity submitted/i)).toBeVisible();

  await page.getByRole("button", { name: /grade 9/i }).click();
  await expect(page.getByText(/grade is pending passback sync/i)).toBeVisible();
  await expect(page.getByText("Score: 9")).toBeVisible();

  await page.getByRole("button", { name: /load admin console/i }).click();
  await expect(page.getByText(/admin console loaded/i)).toBeVisible();

  await page.getByRole("button", { name: /preview roster/i }).click();
  await expect(page.getByText(/roster preview completed/i)).toBeVisible();
  await expect(page.locator(".metric-grid").getByText("Created")).toBeVisible();

  await page.getByRole("button", { name: /queue import/i }).click();
  await expect(page.getByText(/roster import job queued/i)).toBeVisible();
  await expect(page.getByText(/roster_import #/i)).toBeVisible();
});
