# Checkout Payment API Automation

![Robot API Tests](https://github.com/MjSemati/checkout-payment-api-automation/actions/workflows/robot-tests.yml/badge.svg)
![Python](https://img.shields.io/badge/python-3.9%2B-blue)
![Robot Framework](https://img.shields.io/badge/Robot%20Framework-7.x-00C0B5)
![Flask](https://img.shields.io/badge/fake%20server-Flask-000000)

Robot Framework API test suite for the MyDigipay checkout **payment methods** endpoint (`GET /payment/`).

> [!NOTE]
> Validates JSON schema, types, business rules **R1–R7**, with **6 positive** and **6 negative** core scenarios (+ optional extended coverage).

**Repository:** https://github.com/MjSemati/checkout-payment-api-automation

---

## Table of contents

- [Quick start](#quick-start)
- [Approach](#approach)
- [Project structure](#project-structure)
- [Prerequisites](#prerequisites)
- [How to run](#how-to-run)
- [Sample checkout page (demo UI)](#sample-checkout-page-demo-ui)
- [Scenarios covered (P1–P6, N1–N6)](#scenarios-covered-p1p6-n1n6)
- [Test data](#testdata-scenarios)
- [Business rules validated](#business-rules-validated)
- [Layering (BDD)](#layering-bdd)
- [Assumptions](#assumptions)
- [Tags](#tags)
- [Submission checklist](#submission-checklist)
- [CI (GitHub Actions)](#ci-github-actions--bonus)

---

## Quick start

> [!TIP]
> Run these in **two terminals** from the project root after `pip install -r requirements.txt`.

```bash
# Terminal 1 — fake API (+ demo checkout UI at http://127.0.0.1:8080/)
python3 fake_server/app.py

# Terminal 2 — core scenarios (P1–P6, N1–N6)
python3 -m robot --include required -d log features/

# Open HTML report (macOS)
open log/report.html
```

---

## Approach

| Item | Choice |
|------|--------|
| Environment | **Local fake server** (no real MyDigipay backend) |
| Test data | **JSON fixtures** in `testdata/scenarios/` (served by fake server) |
| Framework | **Robot Framework** + RequestsLibrary |
| Style | **BDD** — business steps in `features/`, technical code in `steps/` and `apis/` |

The task allows a fake server **or** static JSON files. This project uses **both**: JSON is the single source of truth; the fake server serves it by `?scenario=<name>`.

---

## Project structure

```
checkout-payment-api-automation/
├── README.md
├── requirements.txt
├── features/                      ← BDD scenarios (business layer)
│   ├── payment_positive.robot     ← P1–P6 (required)
│   ├── payment_negative.robot     ← N1–N6 (required)
│   ├── payment_ddt_examples.robot ← optional template-based DDT examples
│   └── payment_extended.robot     ← PDF gap coverage (extended tag)
├── steps/                         ← technical keywords
│   ├── payment_keywords.robot
│   └── testdata_keywords.robot
├── apis/
│   └── payment_api.robot          ← HTTP only
├── testdata/
│   └── scenarios/*.json           ← one JSON file per scenario
├── fake_server/
│   ├── app.py
│   └── static/index.html          ← optional demo checkout UI
└── log/                           ← Robot reports (after run)
```

---

## Prerequisites

- Python **3.9+**
- `pip install -r requirements.txt`

Libraries: `robotframework`, `robotframework-requests`, `robotframework-jsonlibrary`, `flask`.

---

## How to run

### 1. Start the fake server

```bash
python3 fake_server/app.py
```

Server: `http://127.0.0.1:8080`  
Endpoint: `GET /payment/?scenario=<name>&CellNumber=<phone>`

### 2. Try the sample checkout page (optional)

With the server running, open in a browser:

**http://127.0.0.1:8080/**

Pick a scenario (e.g. `happy_path`, `bnpl_blocked`, `server_error`), enter a cell number, and click **Load payment methods**. The page calls the same fake API your Robot tests use.

> [!NOTE]
> This UI is **illustrative only** — it is not covered by Robot tests and does not submit real payments.

### 3. Run tests (new terminal)

```bash
python3 -m robot -d log features/
```

### Run by tag or suite

```bash
python3 -m robot --include smoke -d log features/
python3 -m robot --include P5 -d log features/
python3 -m robot -d log features/payment_negative.robot
python3 -m robot -d log features/payment_ddt_examples.robot   # optional DDT examples
python3 -m robot --include extended -d log features/    # optional extra coverage
python3 -m robot --include required -d log features/      # core P1–P6 + N1–N6
```

### View reports

Open `log/report.html` and `log/log.html` after a run.

---

## Sample checkout page (demo UI)

A minimal **payment-method picker** shows how the API response could look on a checkout screen. It lives at `fake_server/static/index.html` and is served at **`http://127.0.0.1:8080/`** when the fake server is running.

### Wireframe (happy path)

```text
┌─────────────────────────────────────┐
│  Checkout — payment method          │
│  Scenario: [ happy_path (P1)  ▼]    │
│  Cell:     [ 09120000000        ]   │
│           [ Load payment methods ]  │
├─────────────────────────────────────┤
│  ○ Online Payment          [online] │
│  ○ Digital Wallet         [wallet]  │
│  ● BNPL Payment             [bnpl]  │
│      ◉ 1 installment · credit …     │
│      ○ 3 installments · credit …    │
├─────────────────────────────────────┤
│        [ Pay (demo only) ]          │
└─────────────────────────────────────┘
```

### What the demo reflects

| API field / rule | UI behavior |
|------------------|-------------|
| `is_clickable=false` (P2) | Method grayed out, “Not selectable (Rule R2)” |
| BNPL `options` (R4–R7) | Installment radios; default pre-selected |
| Inactive / zero credit (N1, N2) | Options shown struck through (ineligible) |
| HTTP 500 (N6) | Red error banner (fail fast) |
| `body.status ≠ 200` | Error message (e.g. `body_error` scenario) |

### Try scenarios quickly

| Select in UI | PDF | What you see |
|--------------|-----|----------------|
| `happy_path` | P1 | Three methods, BNPL installments |
| `bnpl_blocked` | P2 | BNPL disabled |
| `server_error` | N6 | HTTP error message |
| `empty_payment_methods` | — | “No payment methods” |

Source file: [`fake_server/static/index.html`](fake_server/static/index.html)

---

## Scenarios covered (P1–P6, N1–N6)

| ID | Type | Description |
|----|------|-------------|
| P1 | Positive | Happy path: online, wallet, BNPL; all rules pass |
| P2 | Positive / Rule | BNPL not clickable (`is_clickable=false`) |
| P3 | Positive / Contract | Payment method schema valid on happy path (R1) |
| P4 | Positive / Rule | Wallet flag rule valid (`is_wallet` consistency, R3) |
| P5 | Positive / Rule | BNPL R4-R7 valid on clickable happy path |
| P6 | Positive / Rule | Non-clickable BNPL with empty `options` is valid (R2/R4) |
| N1 | Negative | BNPL `credit=0` → rule R5 |
| N2 | Negative | BNPL `is_active=false` → rule R5 |
| N3 | Negative | Multiple defaults among eligible → rule R6 |
| N4 | Negative | Missing required field `type` → schema R1 |
| N5 | Negative | Wrong types (`id`, `is_clickable`) → R1 |
| N6 | Negative | HTTP 500; fail fast |

---

## Test data (`testdata/scenarios/`)

### Naming

| Rule | Example |
|------|---------|
| File name = `scenario` query param | `insufficient_credit.json` → `?scenario=insufficient_credit` |
| Lowercase, snake_case | `bnpl_blocked.json` |
| One file per scenario | Default: `happy_path.json` |

### JSON format

```json
{
  "http_status": 200,
  "status": 200,
  "payment_methods": [ ... ]
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `http_status` | No (default `200`) | HTTP status from fake server (`500` for N6) |
| `status` | Yes | Body status (`200` = OK for this task) |
| `payment_methods` | Yes (except N6) | Array of payment methods |

**Payment method (minimum):** `id` (int), `type`, `title`, `is_clickable`, `is_wallet` (bool); optional `description`, `source_id`, `options`.

**BNPL option:** `source_id`, `title`, `credit`, `is_active`, `is_default`, `price_type` (`CASH_PRICE` or `CREDIT_PRICE`).

### Scenario map

| File | `?scenario=` | PDF | Simulates |
|------|----------------|-----|-----------|
| `happy_path.json` | `happy_path` (default) | P1/P3/P4/P5 | All methods valid |
| `bnpl_blocked.json` | `bnpl_blocked` | P2 | BNPL not clickable |
| `insufficient_credit.json` | `insufficient_credit` | N1 | `credit: 0` (R5) |
| `inactive_bnpl.json` | `inactive_bnpl` | N2 | `is_active: false` (R5) |
| `multiple_default.json` | `multiple_default` | N3 | Two defaults (R6) |
| `missing_required_field.json` | `missing_required_field` | N4 | Missing `type` |
| `wrong_type.json` | `wrong_type` | N5 | Wrong field types |
| `server_error.json` | `server_error` | N6 | HTTP 500 |

<details>
<summary><strong>Extended scenarios</strong> (<code>payment_extended.robot</code>, tag <code>extended</code>)</summary>

| File | `?scenario=` | Covers |
|------|----------------|--------|
| `body_error.json` | `body_error` | N6 extension: HTTP 200 + `body.status` 500 |
| `missing_title.json` | `missing_title` | N4 extension: missing `title` |
| `empty_payment_methods.json` | `empty_payment_methods` | Scope: empty array |
| `invalid_price_type.json` | `invalid_price_type` | R7: invalid enum |
| `bnpl_blocked_empty_options.json` | `bnpl_blocked_empty_options` | P6: empty `options` |

</details>

### Data flow

```text
testdata/scenarios/foo.json → fake_server → Robot When/Then → steps compare response to same JSON
```

### Add a new scenario

1. Create `testdata/scenarios/my_case.json` (copy `happy_path.json` and edit).
2. Add a test in `features/` with the same name in When/Then steps.
3. Tag the test and document the rule under test.

---

## Business rules validated

| Rule | Description |
|------|-------------|
| R1 | `payment_methods` is array; required fields and types on each method |
| R2 | Selectable only if `is_clickable=true` |
| R3 | `is_wallet=false` when `type` is not `wallet` |
| R4 | `options` present and array; empty only if method not clickable |
| R5 | Eligible option: `is_active=true` and `credit>0` |
| R6 | Exactly one `is_default=true` among eligible options (if any eligible) |
| R7 | `price_type` ∈ `CASH_PRICE`, `CREDIT_PRICE` (case-sensitive) |

---

## Layering (BDD)

| Layer | Location | Responsibility |
|-------|----------|----------------|
| Business | `features/` | Given/When/Then; scenario names; tags |
| Technical | `steps/`, `apis/` | HTTP, JSON, schema & rule validators |
| Data | `testdata/scenarios/` | Expected API responses |

Example:

```robot
When User Requests Payment Methods With Scenario    insufficient_credit    ${CELL_NUMBER}
Then Response Body Should Match Testdata Fixture    insufficient_credit
And BNPL Business Rules Should Fail With Error    *Rule R5*
```

---

## Assumptions

1. **`is_wallet`** required on every method (R3); not in PDF example JSON but in fixtures.
2. **`CellNumber`** sent on requests; fake server does not change responses by phone.
3. **HTTP status** and **`body.status`** both checked on success paths.
4. **BNPL** found by `type=bnpl`, not array index.
5. **`http_status`** in JSON is meta only — stripped before body comparison.
6. Demo UI is illustrative only (no real payment submission), and full price validation is out of scope.
7. Use **`python3`** on macOS if `python` is not available.

---

## Tags

| Tag | Meaning |
|-----|---------|
| `required` | Mandatory PDF scenario |
| `smoke` | P1, N6 |
| `positive` / `negative` | Suite split |
| `P1`…`P6`, `N1`…`N6` | Traceability |
| `R1`…`R7`, `bnpl`, `schema` | Filters |

---

## Submission checklist

- [x] Source code
- [x] README (this file)
- [ ] Robot reports: `log/report.html`, `log/log.html`, `log/output.xml` after a test run

> [!IMPORTANT]
> CI publishes reports as a downloadable artifact — see [CI](#ci-github-actions--bonus) below if you do not attach local `log/` files.

---

## CI (GitHub Actions — bonus)

![Robot API Tests](https://github.com/MjSemati/checkout-payment-api-automation/actions/workflows/robot-tests.yml/badge.svg)

Workflow: `.github/workflows/robot-tests.yml`

| Step | What happens |
|------|----------------|
| Trigger | Push or PR to `main` / `master` |
| Setup | Python 3.11, `pip install -r requirements.txt` |
| Run | Start `fake_server`, then `robot --include required -d log features/` |
| Artifact | Upload `log/` as **`robot-reports`** (even if tests fail) |

**View results:** GitHub repo → **Actions** → latest **Robot API Tests** run → **Artifacts** → download `robot-reports` → open `report.html`
