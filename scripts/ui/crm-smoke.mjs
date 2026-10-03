/* Local browser contract test. Supabase HTTP is mocked; database security is
   verified separately by scripts/database/validate.mjs. Never use hosted credentials. */
import http from "node:http";
import { spawn } from "node:child_process";
import assert from "node:assert/strict";
import { chromium } from "playwright";
import { fileURLToPath } from "node:url";
const projectRoot = fileURLToPath(new URL("../../", import.meta.url));
const id = (n) =>
  `${n.repeat(8)}-${n.repeat(4)}-4${n.repeat(3)}-8${n.repeat(3)}-${n.repeat(12)}`;
const owner = id("1"),
  org = id("2"),
  lead = id("3"),
  cl = id("4"),
  off = id("5"),
  subject = id("6"),
  school = id("7");
const user = {
  id: owner,
  aud: "authenticated",
  role: "authenticated",
  email: "owner@example.test",
  app_metadata: {},
  user_metadata: {},
  created_at: "2026-01-01T00:00:00Z",
};
const prospect = {
  id: lead,
  organization_id: org,
  student_name: "Test Student",
  guardian_name: "Test Guardian",
  phone: "01712345678",
  class_level_id: cl,
  offering_id: off,
  source: "PUBLIC_FORM",
  stage: "NEW",
  lost_reason: null,
  notes: "Requested counselling",
  created_at: "2026-01-01T00:00:00Z",
  assigned_user_id: owner,
  next_follow_up_at: null,
  application_snapshot: {
    class_label: "Class 8",
    offering_label: "Math programme",
    schoolNameSnapshot: "Test School",
  },
  school_id: school,
  submission_intent: "interest",
};
const catalogue = [
  {
    id: off,
    code: "MATH",
    name: "Math programme",
    class_id: cl,
    program_id: off,
    group_id: null,
    branch_id: org,
    academic_year_id: org,
    academic_year_name: "2026",
    branch_name: "Main",
    class_name: "Class 8",
    group_name: null,
    showcase_title: "Math programme",
    showcase_title_bn: "গণিত প্রোগ্রাম",
    showcase_description: "Focused learning",
    showcase_description_bn: "মনোযোগী শিক্ষা",
    showcase_eyebrow: "Learning",
    showcase_eyebrow_bn: "শিক্ষা",
    showcase_icon: "math",
    public_schedule: null,
    public_schedule_bn: null,
    public_requirements: null,
    public_requirements_bn: null,
    admission_policy: null,
    admission_policy_bn: null,
    active_batch_count: 1,
    current_total_seats: 20,
    current_open_seats: 19,
    showcase_sort_order: 0,
    is_accepting_applications: true,
    application_state: "OPEN",
    applications_open_on: null,
    applications_close_on: null,
    created_at: prospect.created_at,
    subjects: [{ id: subject, code: "MATH", name: "Math" }],
    fee_plan: {
      billing_cycle: "MONTHLY",
      currency_code: "BDT",
      components: [
        {
          code: "TUITION",
          name: "Tuition",
          amount: 1500,
          charge_type: "TUITION",
          recurrence: "MONTHLY",
        },
      ],
    },
  },
];
const tables = {
  organizations: [
    {
      id: org,
      name: "Test Institute",
      slug: "test-institute",
      currency: "BDT",
      timezone: "Asia/Dhaka",
    },
  ],
  memberships: [
    { organization_id: org, user_id: owner, role: "OWNER", active: true },
  ],
  organization_modules: [
    { organization_id: org, module: "CRM", enabled: true },
  ],
  prospects: [prospect],
  schools: [
    {
      id: school,
      organization_id: org,
      name: "Test School",
      is_verified: true,
      active: true,
    },
  ],
  offerings: [{ id: off, organization_id: org, name: "Math programme" }],
  class_levels: [
    {
      id: cl,
      organization_id: org,
      code: "C8",
      name: "Class 8",
      active: true,
      sort_order: 8,
    },
  ],
  subjects: [
    {
      id: subject,
      organization_id: org,
      code: "MATH",
      name: "Math",
      active: true,
    },
  ],
  programmes: [],
  class_groups: [],
  academic_years: [],
  areas: [],
  lead_sources: [],
  guardian_relationships: [],
  followups: [],
  branches: [],
};
const errors = [];
const calls = [];
const api = http.createServer(async (req, res) => {
  let body = "";
  for await (const chunk of req) body += chunk;
  const input = body ? JSON.parse(body) : {};
  const url = new URL(req.url, "http://127.0.0.1");
  let result;
  if (url.pathname === "/auth/v1/user") result = user;
  else if (url.pathname.startsWith("/rest/v1/rpc/")) {
    const name = url.pathname.split("/").pop();
    calls.push({ name, input });
    if (name === "crm_public_catalogue") result = catalogue;
    else if (name === "crm_public_options")
      result = {
        organization: { name: "Test Institute", slug: "test-institute" },
        classes: tables.class_levels,
        programs: [],
        subjects: tables.subjects,
        schools: tables.schools,
        sources: [],
        relationships: [],
      };
    else if (name === "crm_public_interest")
      result = { prospect_no: "TEST1234" };
    else if (name === "crm_followup") {
      prospect.stage = input.p_input.stage;
      result = { stage: prospect.stage };
    } else if (name === "crm_master") result = { id: cl };
    else if (name === "crm_assign") result = null;
    else {
      errors.push("Unexpected RPC " + name);
      res.statusCode = 400;
      result = { message: "Unknown RPC" };
    }
  } else if (url.pathname.startsWith("/rest/v1/")) {
    const name = url.pathname.split("/").pop();
    let rows = tables[name] || [];
    if (!tables[name]) errors.push("Unexpected table " + name);
    if (
      !["organizations", "memberships"].includes(name) &&
      url.searchParams.get("organization_id") !== `eq.${org}`
    )
      errors.push("Unscoped query " + name);
    for (const [k, v] of url.searchParams)
      if (v.startsWith("eq."))
        rows = rows.filter((r) => String(r[k]) === v.slice(3));
    result = req.headers.accept?.includes("vnd.pgrst.object")
      ? (rows[0] ?? null)
      : rows;
  } else {
    res.statusCode = 404;
    result = {};
  }
  res.setHeader("content-type", "application/json");
  res.end(JSON.stringify(result));
});
(async () => {
  let app, browser;
  try {
    await new Promise((r) => api.listen(54321, "127.0.0.1", r));
    app = spawn(
      "node",
      [
        "node_modules/next/dist/bin/next",
        "start",
        "-H",
        "127.0.0.1",
        "-p",
        "3100",
      ],
      {
        cwd: projectRoot,
        env: {
          ...process.env,
          NEXT_PUBLIC_SUPABASE_URL: "http://127.0.0.1:54321",
          NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "local-smoke-key",
        },
        stdio: ["ignore", "pipe", "pipe"],
      },
    );
    let logs = "";
    app.stdout.on("data", (d) => (logs += d));
    app.stderr.on("data", (d) => (logs += d));
    for (let n = 0; n < 80; n++) {
      try {
        await fetch("http://127.0.0.1:3100/auth/sign-in");
        break;
      } catch {
        await new Promise((r) => setTimeout(r, 250));
      }
    }
    browser = await chromium.launch({
      executablePath: process.env.UI_CHROMIUM_PATH,
      args: [
        "--no-sandbox",
        "--disable-dev-shm-usage",
        "--use-gl=angle",
        "--use-angle=swiftshader",
        "--enable-unsafe-swiftshader",
      ],
    });
    const page = await browser.newPage({
      viewport: { width: 1440, height: 1000 },
    });
    page.on("pageerror", (e) => errors.push(e.message));
    const base = "http://127.0.0.1:3100";
    await page.goto(base + "/auth/sign-in");
    await page.getByRole("button", { name: "বাংলা", exact: true }).click();
    await page
      .getByRole("heading", { name: "প্রবেশ করুন", exact: true })
      .waitFor();
    await page.reload();
    await page
      .getByRole("heading", { name: "প্রবেশ করুন", exact: true })
      .waitFor();
    console.log("PASS: auth toggle persists without mixed labels");
    await page.goto(base + "/?organization=test-institute");
    await page
      .getByRole("heading", { name: "গণিত প্রোগ্রাম", exact: true })
      .waitFor();
    const interest = page.locator('a[href*="offering="]').first();
    assert.match(
      await interest.getAttribute("href"),
      /organization=test-institute/,
    );
    console.log("PASS: original public cards preserve tenant links");
    await page.goto(base + "/interest?organization=test-institute");
    await page.locator("[name=studentName]:visible").fill("Applicant");
    await page.locator("[name=guardianName]:visible").fill("Guardian");
    await page.locator("[name=mobile]:visible").fill("01712345678");
    await page.locator("[name=classId]:visible").selectOption(cl);
    await page.locator("button[type=submit]:visible").click();
    await page.locator("#interest-acknowledgement-slip").waitFor();
    assert.match(
      await page.locator("#interest-acknowledgement-slip").innerText(),
      /TEST1234/,
    );
    assert.equal(
      calls.find((c) => c.name === "crm_public_interest").input.p_payload
        .consentToContact,
      false,
    );
    console.log(
      "PASS: public intake submits and prints acknowledgement without consent gate",
    );
    await page.goto(
      base +
        "/interest?organization=test-institute&intent=admission&offering=" +
        off,
    );
    await page.getByText("প্রকাশিত ফি", { exact: false }).waitFor();
    assert.match(await page.locator("main").innerText(), /মাসিক/);
    assert.match(await page.locator("main").innerText(), /টিউশন ফি/);
    assert.equal(
      await page
        .locator("[name=policyAcknowledged]:visible")
        .getAttribute("required"),
      null,
    );
    console.log(
      "PASS: admission enquiry fees follow the selected language without consent requirements",
    );
    // A mocked signed-in session exercises UI contracts; this is not hosted Auth proof.
    const payload = Buffer.from(
      JSON.stringify({
        sub: owner,
        exp: Math.floor(Date.now() / 1000) + 3600,
        aud: "authenticated",
        role: "authenticated",
      }),
    ).toString("base64url");
    const token = `eyJhbGciOiJIUzI1NiJ9.${payload}.test`;
    const cookie =
      "base64-" +
      Buffer.from(
        JSON.stringify({
          access_token: token,
          refresh_token: "mock-refresh",
          expires_at: Math.floor(Date.now() / 1000) + 3600,
          expires_in: 3600,
          token_type: "bearer",
          user,
        }),
      ).toString("base64url");
    await page.context().addCookies([
      { name: "sb-127-auth-token", value: cookie, url: base },
      { name: "outlinerz-organization", value: org, url: base },
    ]);
    await page.goto(base + "/dashboard/crm/prospects");
    await page
      .getByRole("link", { name: "Test Student", exact: true })
      .waitFor();
    await page.getByRole("button", { name: "EN", exact: true }).click();
    await page
      .getByPlaceholder("Search name, mobile, school, offering or prospect ID")
      .fill("no match");
    await page
      .getByText("No prospects match the current filters.", { exact: true })
      .waitFor();
    await page
      .getByPlaceholder("Search name, mobile, school, offering or prospect ID")
      .fill("Test Student");
    await page.getByRole("link", { name: "Test Student", exact: true }).click();
    await page
      .getByRole("heading", { name: "Follow-up timeline", exact: true })
      .waitFor();
    await page
      .getByText("Record counselling / follow-up", { exact: true })
      .click();
    await page
      .locator("#followup-notes")
      .fill("Guardian wants a counselling session");
    await page.locator("#followup-status").selectOption("INTERESTED");
    await page
      .getByRole("button", { name: "Record Follow-up", exact: true })
      .click();
    await page.getByText("Follow-up recorded.", { exact: true }).waitFor();
    console.log("PASS: prospect search, profile and atomic follow-up contract");
    await page.goto(base + "/dashboard/crm/manage");
    await page
      .getByRole("button", { name: "Create record", exact: true })
      .click();
    await page.locator("#class-code").fill("C9");
    await page.locator("#class-name").fill("Class 9");
    await page.locator("#class-reason").fill("New class for next intake");
    await page
      .getByRole("button", { name: "Create record", exact: true })
      .last()
      .click();
    await page.getByText("Master record created.", { exact: true }).waitFor();
    console.log(
      "PASS: original master editor writes the new directory contract",
    );
    await page.getByRole("button", { name: "বাংলা", exact: true }).click();
    await page.getByRole("button", { name: "বিদ্যালয়", exact: true }).click();
    await page
      .getByRole("button", { name: "নতুন তথ্য", exact: true })
      .waitFor();
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto(base + "/dashboard/crm/prospects");
    await page
      .getByRole("link", { name: "Test Student", exact: true })
      .waitFor();
    assert.equal(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= window.innerWidth,
      ),
      true,
    );
    console.log("PASS: mobile CRM shell contains wide table scrolling");
    await page.evaluate(() => document.fonts.ready);
    assert.equal(
      await page.evaluate(() =>
        document.fonts.check('16px "Outlinerz Bengali"', "বাংলা"),
      ),
      true,
    );
    console.log("PASS: self-hosted Bengali glyphs load without a system font");
    const folder = process.env.UI_SCREENSHOT_DIR;
    if (folder) {
      await page.screenshot({
        path: folder + "/crm-mobile.png",
        fullPage: true,
      });
      await page.setViewportSize({ width: 1440, height: 1000 });
      await page.screenshot({
        path: folder + "/crm-desktop.png",
        fullPage: true,
      });
    }
    assert.deepEqual(errors, []);
    console.log(
      "PASS: no browser exceptions or unscoped mocked tenant queries",
    );
  } catch (e) {
    console.error("Browser errors:", errors);
    throw e;
  } finally {
    await browser?.close();
    app?.kill();
    await new Promise((r) => api.close(r));
  }
})().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
