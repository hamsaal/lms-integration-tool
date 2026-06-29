import { expect, test } from "@playwright/test";

test("learner launch, submission, and instructor grade flow", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("button", { name: /launch as learner/i }).click();
  await expect(page.getByText(/learner activity is ready/i)).toBeVisible();

  await page.getByRole("textbox").fill("A membrane protects the cell and controls transport.");
  await page.getByRole("button", { name: /submit activity/i }).click();
  await expect(page.getByText(/activity submitted/i)).toBeVisible();

  await page.getByRole("button", { name: /grade 9/i }).click();
  await expect(page.getByText(/grade is pending passback sync/i)).toBeVisible();
  await expect(page.getByText("Score: 9")).toBeVisible();
});
