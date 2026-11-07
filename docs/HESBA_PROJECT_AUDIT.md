# Hesba — Complete Project Audit

> **Date:** 2026-11-07
> **Repo:** `E:\projects\Hesba-Business` (note: the requested path `D:\apps\Hesba-Business` does not exist; the real working copy is on `E:`)
> **HEAD:** `4d8935b` — clean working tree
> **Stack:** Flutter 3.32.5 / Dart ^3.12.1 · Firebase Auth · Cloud Firestore · FCM · flutter_local_notifications · Cubit (flutter_bloc) · get_it · easy_localization · Cloudinary
> **Scale:** 288 Dart files in `lib/` · `dart analyze`: **0 errors, 1 warning, 45 infos** · **no `test/` directory at all**
> **Method:** read-only inspection (no source file was modified for this audit; this document is the only artifact created).

---

## 1. Executive summary

Hesba is a **functionally rich, launchable-in-principle app**: registration, products, sales (with atomic stock transactions), returns, expenses, subscriptions with receipt review, an admin dashboard, notifications and image uploads are all wired to **real** Firestore/Firebase Auth operations — no mock data was found anywhere in the owner-facing flows.

However the launch is blocked by **one deployment issue** and threatened by **several correctness gaps** (reports silently truncating data, a rules-vs-settings price mismatch, zero automated tests, and profit not being shown to the shop owner anywhere in the reports screen).

**Launch readiness: 🟠 NOT READY — 1× P0, 4× P1 must be resolved first.**

---

## 2. Feature status board

| # | Feature | Status | One-line justification |
|---|---------|--------|------------------------|
| 1 | Authentication (login / logout / reset) | **COMPLETE** | Real `signInWithEmailAndPassword`, `sendPasswordResetEmail`, `signOut`; error mapping complete. Needs on-device pass. |
| 2 | Registration | **COMPLETE** | Writes `users` + `shops` + best-effort trial with Auth-account rollback; `role: 'owner'` matches `firestore.rules:105`. |
| 3 | User profiles | **PARTIALLY_COMPLETE** | Update user + shop docs and shop-logo Cloudinary upload work; owner has no personal avatar, on-device unverified. |
| 4 | Products | **PARTIALLY_COMPLETE** | Full CRUD + validation + `double` stock; no tests; legacy clothing `variants` intentionally hidden. |
| 5 | Inventory / stock | **PARTIALLY_COMPLETE** | Sale decrement & return increment are transactional and fractional-safe; **no replenishment screen, no stock audit log, low-stock is display-only**. |
| 6 | Sales | **COMPLETE** | Atomic transaction validates existence/ownership/active/stock before write (`sales_repo_impl.dart:127-161`); edit/delete intentionally absent (rules are admin-only). |
| 7 | Expenses | **COMPLETE** | Full CRUD, validation, categories, stream-based list; layout crash fixed in `expense_list_card.dart`. |
| 8 | Profit calculations | **PARTIALLY_COMPLETE** | Per-sale profit with `costPrice` snapshot + admin `profitSummary` exist; **the owner-facing Reports/Dashboard screens show no profit at all**. |
| 9 | Subscription management | **PARTIALLY_COMPLETE** | Plans, 7-day trial, `SubscriptionGate` enforced in 19 call sites; **rules hardcode prices that settings can change** (see B-3). |
| 10 | Payment proof submission | **PARTIALLY_COMPLETE** | Cloudinary upload → `subscription_requests` doc matches rules shape; **amount mismatch risk** (B-3); untested end-to-end. |
| 11 | Notifications | **PARTIALLY_COMPLETE** | Local reminders (daily/weekly), FCM token storage, activity log with rich payloads + tap-routing just added; **no backend sends FCM**. |
| 12 | Image uploads | **COMPLETE** | Cloudinary unsigned upload (shop/product/receipt presets), only `https` URL persisted, typed error mapping. |
| 13 | Firebase integration | **PARTIALLY_COMPLETE** | Code-side rules file is correct; **the deployed console rules are stale (P0)**. `firestore.indexes.json` present; no Cloud Functions. |
| 14 | Admin dashboard | **PARTIALLY_COMPLETE** | Login, stats, shops, subscriptions, request approval, settings, global search all implemented; heavy `setState` use (architecture violation). |
| 15 | Navigation & routing | **PARTIALLY_COMPLETE** | Every referenced `AppRoutes.*` is registered; 2 dead route constants; notification payload routing added. |

---

## 3. Detailed findings per feature

### 3.1 Authentication — COMPLETE
**Files:** `lib/features/auth/data/repos_impl/auth_repo_impl.dart`, `presentation/cubit/{login_cubit,forgot_password_cubit}.dart`, `presentation/views/login_view.dart`, `presentation/login_widgets/{login_form,forgot_password_dialog}.dart`, `lib/features/profile/data/repos_impl/account_repo_impl.dart:131` (signOut).

**Works:** real sign-in (`auth_repo_impl.dart:29-32`), legacy `wrong-password` + modern `invalid-credential` mapping (`login_cubit.dart:32-42`), email/password form validation, password-reset email actually sent (`auth_repo_impl.dart:160-162`) via a dialog, logout wired to `account_repo_impl.dart:131`.

**Missing / bugs:**
- `AppRoutes.resetPassword` (`app_routes.dart:5`) is defined but its router case is **commented out** (`app_router.dart:94-95`) → dead constant, no navigation break (reset uses the dialog).
- No automated tests.

**Fixes:** delete the dead route constant (P3).

---

### 3.2 Registration — COMPLETE
**Files:** `register_navigation.dart`, `auth_repo_impl.dart:40-150`, `firestore.rules:101-129`.

**Works:** Auth account → `users/{uid}` (`role: 'owner'`, `register_navigation.dart:170`) → best-effort trial (`auth_repo_impl.dart:99-108`) → `shops/{id}`; any Firestore failure **rolls back the Auth account** (`auth_repo_impl.dart:86-97,110+`), so no orphan logins.

**Cross-check vs rules:** `firestore.rules:105-106` requires `get('role','owner') == 'owner'` → **the old `vendor` vs `owner` conflict is resolved in current code** (writes `'owner'`). Trial creation matches `firestore.rules:121-129` (status `trial`, ≤7 days, `isTrial: true`).

**Missing:** on-device end-to-end verification (P1 testing item).

---

### 3.3 Profiles — PARTIALLY_COMPLETE
**Files:** `profile/data/repos_impl/account_repo_impl.dart` (updates `users` at :74 and `shops` at :90), `profile/presentation/views/update_profile_view.dart` (business-type dropdown, Cloudinary shop-logo upload at :350-364), `change_password_view.dart`.

**Missing:** personal profile photo (only the shop logo exists); the view uses `setState` heavily (see §5-A2). Rules allow owner update only within `onlyOwnerFields()` — any field outside that allowlist fails silently with permission-denied at runtime; **verify the allowlist matches every field the form sends** (NEEDS_TESTING).

---

### 3.4 Products — PARTIALLY_COMPLETE
**Files:** `lib/core/models/product.dart`, `products/presentation/cubit/product_form_cubit.dart`, `views/product_form_view.dart`, `data/repos_impl/products_repo_impl.dart`.

**Works:** real Firestore CRUD; validation (name required, price > 0, `stock`/`lowStockThreshold` decimal-aware, `product_form_cubit.dart:121,200-204`); `stock` is `double` end-to-end (`product.dart:14,74,96`); clothing fields are `color/size/model` only (variants table removed by prior decision; legacy `specs['variants']` data preserved but hidden).

**Missing:** tests; `dart analyze` info-level lints remain (45 infos project-wide).

---

### 3.5 Inventory & stock — PARTIALLY_COMPLETE
**Files:** `sales_repo_impl.dart:126-161`, `returns_repo_impl.dart:175-182`, `dashboard_repo_impl.dart:159-176`, `products_state.dart:43-54`.

**Works:**
- Sale: transaction checks product exists, same shop, `isActive`, `currentStock >= quantity` then decrements `double` stock (`sales_repo_impl.dart:143-156`).
- Return: adds quantity back (`returns_repo_impl.dart:179-182`).
- Low stock: `Product.isLowStock` (`product.dart:145`) shown as badge on product cards, sale cards, and counted on the dashboard (`dashboard_repo_impl.dart:172`).

**NOT_IMPLEMENTED:**
1. **Stock replenishment / purchase screen** — returns are the *only* way stock increases (grep for stock increment finds only `returns_repo_impl.dart`).
2. **Stock-change audit log** — `ActivityRepo` logs sales/returns/expenses/products but not quantity deltas.
3. **Low-stock warning before a sale** — the sale screen shows a badge but never blocks/warns.

**Fixes:** P2 for #1 and #3; P3 for #2.

---

### 3.6 Sales — COMPLETE
**Files:** `sales_repo_impl.dart`, `sales_cubit.dart`, `views/add_sale_view.dart`, `widgets/{sale_product_card,sales_list_card,payment_method_selector}.dart`.

**Works:** auto-ID sale doc (`sales_repo_impl.dart:110-113`); atomic stock transaction (§3.5); `costPrice` snapshot per item (`sale_model.dart:9-25`) so historical profit survives price changes; manual quantity text field (no +/- stepper, per prior decision); inactive products greyed + `غير متاح` badge and save blocked (`sale_product_card.dart`); payment methods cash/card/mobile_wallet (`app_constants.dart:146-153`); re-entrancy guard against double-tap (`sales_cubit.dart:26`).

**By design (not bugs):** no client-side sale edit/delete — `firestore.rules` makes those admin-only and no UI offers them.

---

### 3.7 Expenses — COMPLETE
**Files:** `expenses/data/repos_impl/expenses_repo_impl.dart`, `presentation/cubit/expenses_cubit.dart`, `views/{expenses_view,add_expense_view}.dart`, `widgets/expense_list_card.dart`.

**Works:** CRUD with validation (title/amount>0/category required, `expenses_cubit.dart:75-83`), stream-backed list, shop-name meta row (the `Flexible`-in-`Column` layout crash was fixed by moving the block inside the `Row`), delete passes `title/amount/category` into the activity payload.

---

### 3.8 Profit calculations — PARTIALLY_COMPLETE ⚠️
**Where profit exists today:**
| Location | Formula | File |
|---|---|---|
| Per sale item | `(unitPrice − costPrice) × quantity` | `sale_model.dart:25` |
| Admin dashboard (platform-wide) | `revenue − cost`, paged up to 20k sales | `admin_repo_impl.dart:156-240` |
| Products header | `Σ(price×stock) − Σ(costPrice×stock)` (stock-based, not sales-based) | `products_state.dart:43-51` |
| Activity notification | per-invoice profit | `sales_cubit.dart:95` |

**Missing (P1):** the **owner-facing Reports screen shows no profit** — `reports_state.dart:82-86` computes `totalSales / totalReturns / totalExpenses / balance` only; grep for `profit|costPrice` in `lib/features/reports/**` returns **nothing**. The Dashboard also has no today's-profit card (`dashboard_state.dart` has sales/returns/expenses totals only). For an accounting app whose user asks "مكسبه كاما", this is the single most important functional gap.

**Bug (P2):** legacy sales saved before the `costPrice` snapshot exist with `costPrice = 0` → their profit counts as 100% of revenue in `profitSummary()` (`admin_repo_impl.dart:185-202` defaults to 0). Flag as "estimated" or exclude.

**Fixes:** add `totalProfit`/`todayProfit` to `ReportsState`/`DashboardState` computed from `Σ item.profit` (needs `SaleItemModel.costPrice` which is already persisted); label legacy zero-cost sales.

---

### 3.9 Subscription management — PARTIALLY_COMPLETE
**Files:** `subscription/data/models/{subscription_plan,subscription_model,subscription_request_model}.dart`, `repos_impl/subscription_repo_impl.dart`, `presentation/subscription_gate.dart`, `cubit/subscription_cubit.dart`, `core/services/app_settings_service.dart`, `firestore.rules:115-187`.

**Works:** 4 plans with **live prices from `admin_settings/settings`** (`subscription_plan.dart:31-39`, defaults 99/249/449/799 in `admin_settings.dart:41-44`); 7-day client-created trial once (`auth_repo_impl.dart:99-108`); `SubscriptionGate.ensureCanModify` enforced at **19 call sites** covering sales, returns, expenses, products, categories, reminders, home quick-actions; one-pending-request guard (`subscription_repo_impl.dart:104-114`); batch writes `subscription_requests` + `subscription/lastRequestId` (`:135-142`).

**Bugs:**
- **B-3 (P1):** `firestore.rules:174-179` hardcodes `amount == 99/249/449/799`, but the app sends `plan.price` from `admin_settings`. **The moment an admin edits a price in the dashboard, every receipt submission is rejected with `permission-denied`.**
- Rules `subscription` update path requires `lastRequestId` doc to be `approved` for `active` (`firestore.rules:144`) — depends on admin flow working; NEEDS_TESTING.

**Fixes:** make the rules read the price via `get(/databases/$(database)/documents/admin_settings/settings).data` (or freeze prices and remove the dashboard editors).

---

### 3.10 Payment proof submission — PARTIALLY_COMPLETE
**Files:** `subscription_receipt_upload.dart`, `subscription_cubit.dart:71-122`, `subscription_repo_impl.dart:97-149`, `cloudinary_image_service.dart`, `app_constants.dart:34-38`.

**Works:** pick + Cloudinary upload (`hesba/payment-proofs` folder, receipt preset), URL kept in cubit state, submit validates plan/method/receipt (`subscription_cubit.dart:79-99`), doc shape satisfies `firestore.rules:169-182` (`userId==myUid`, `status=='pending'`, `paymentMethod ∈ {instapay,vodafone_cash,etisalat_cash}`, `paymentProofUrl` matches `https://.*`).

**Missing / risks:**
- **B-3 above (amount)** — P1.
- Receipt preset defaults to the *same* preset as regular images (`app_constants.dart:36-37`, `hesba_images`) — confirm the Cloudinary preset actually allows screenshots (P3).
- End-to-end untested (NEEDS_TESTING).

---

### 3.11 Notifications — PARTIALLY_COMPLETE
**Files:** `core/services/notification_service.dart` (459 lines), `features/notifications/**` (22 files), `core/router/notification_router.dart`, `main.dart:18,31-45`, `assets` reminders.

**Works:**
- Local daily/weekly reminders via `zonedSchedule` + `matchDateTimeComponents`, per-day ids `_dayId = id*10+weekday` (`notification_service.dart:347-393`), reconciled by `syncReminders` (`:399-431`).
- FCM permission + token saved on the user doc (`:182-242`); foreground local display for FCM; payload preserved for cold start.
- **Tap routing by type** (added in `4d8935b`): `activity:sale → sales tab`, `activity:product → products tab`, `activity:return/expense → its screen`, `reminder/test → notifications`, fallback dashboard (`notification_router.dart:19-68`), works for terminated app (bounded navigator retry, `main.dart:31-45`).
- Activity log with rich bodies (product × qty = total, invoice total, profit, payment method) + system notification per operation (`activity_message.dart`, `activity_cubit.dart:33-45`).

**Bugs / gaps:**
- **No FCM backend** — nothing in the repo (no `functions/`, no `sendAll`) ever sends a remote push; only local notifications and manual Firebase Console sends exist. Push-on-another-device = NOT_IMPLEMENTED (P2).
- Notification id namespaces: reminders 1001-1007 & 2000+, activities 4000-4999 (`notification_service.dart:344-345`). Personal reminder ids grow from 2000 (`notification_cubit.dart:160-166`); **~2000 user reminders would collide with the activity range** (P3, theoretical).
- Every operation now raises a system notification with no off switch — user already offered an on/off toggle (P3).
- Legacy activity rows have no `payload` → intentionally non-tappable (documented behavior).

---

### 3.12 Image uploads — COMPLETE
**Files:** `core/services/cloudinary_image_service.dart`, `core/utils/shop_image_upload.dart`, `core/widgets/{shop_image_picker,shop_image_view}.dart`, `app_constants.dart:14-43`.

**Works:** Cloudinary unsigned uploads for shop images / product images / payment receipts (three folders, three presets), `String.fromEnvironment` overrides, `isCloudinaryConfigured` guard, typed error messages (`shop_image_upload.dart:155-160`), only the `https` URL is persisted to Firestore.

**Risk (P3):** cloud name `qavqsavd` + preset `hesba_images` ship as code defaults — unsigned presets are publicly usable by anyone who decompiles the APK; consider restricting the preset (e.g. folder-based restrictions / max files) on the Cloudinary side.

---

### 3.13 Firebase integration — PARTIALLY_COMPLETE (one P0)
**Files:** `firestore.rules` (287 lines), `firebase.json`, `.firebaserc`, `firestore.indexes.json`, `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`.

**Works:** project `hesba-business` wired in `firebase.json`; indexes file present; both platform config files present; `dart analyze` clean.

**Bugs:**
- **B-1 (P0):** the rules in `firestore.rules` (incl. `admin_settings → allow read: if signedIn()` at line 283) were **never published** — the deployed console rules still contain the old `isAdmin()` version, so `AppSettingsService.refresh()` fails with `cloud_firestore/permission-denied` on every cold start (logged via `logWarning` in `app_settings_service.dart`). CLI deploy failed with 403 (logged-in Firebase account lacks access to `hesba-business`). **Resolution chosen by the user: manual publish via Firebase Console.**
- No Cloud Functions / no `functions/` directory → no server-side FCM, no scheduled jobs (see §3.11).
- `AppConstants.cashRegisterCollection` (`app_constants.dart:12`) is defined but no code references it — dead constant (P3).

---

### 3.14 Admin dashboard — PARTIALLY_COMPLETE
**Files:** `lib/features/admin/**` (17 files incl. `admin_ds.dart` 1029 lines, `admin_settings_view.dart` 1425 lines, `dashboard_view.dart` 604, `shop_details_view.dart` 885).

**Works:** admin login gated by `users.role == 'admin'` (`admin_repo_impl.dart:23-29`); stats dashboard, shops list/details (suspend/activate), subscriptions, **request approval with admin note** (`admin_repo_impl.dart:507`), products/sales/expenses/activity viewers, settings editor (plan prices, wallet numbers), global search. Admin writes pass `isAdmin()` rules.

**Issues:** every admin view uses `setState` (architecture violation, §5-A2); 4 of the 15 largest files are admin views; `activity_view.dart:380` has the project's only analyzer warning (unused variable `h`).

---

### 3.15 Navigation & routing — PARTIALLY_COMPLETE
**Files:** `core/router/{app_routes,app_router,notification_router}.dart`, `main.dart`, `features/main/**`.

**Verified:** referenced routes = `splash, login, register, resetPassword, dashboard, addSaleView, returnsView, addReturnView, expensesView, addExpenseView, subscription, notifications` — **all registered** in `app_router.dart` except `resetPassword` (commented, but also never pushed → no break). `MainLayout` accepts `initialTab` and clamps to 0..3 (`main_layout.dart:35-36`), which is what notification routing uses. Auth-gated route set at `app_router.dart:104-111` includes `notifications`.

**Dead code (P3):** `AppRoutes.resetPassword`, `AppRoutes.shopRegistration` (defined, never referenced), `AppConstants.cashRegisterCollection`.

---

## 4. Issue register (prioritized)

### P0 — Critical, blocks launch
| ID | Issue | Evidence | Fix |
|----|-------|----------|-----|
| **B-1** | Deployed Firestore rules are stale → `admin_settings` read denied → settings/prices/wallet numbers never load in production | `firestore.rules:283` vs console; `app_settings_service.dart` swallows the error | Publish `firestore.rules` in Firebase Console (user's chosen path), then cold-start the app and confirm the `[AppSettings] permission-denied` log is gone |

### P1 — High, must fix before launch
| ID | Issue | Evidence | Fix |
|----|-------|----------|-----|
| **B-3** | Rules hardcode subscription amounts `99/249/449/799` while the app sends live `admin_settings` prices → any price change breaks all receipt submissions | `firestore.rules:174-179` vs `subscription_plan.dart:34-39`, `subscription_repo_impl.dart:128` | Read price from `admin_settings` inside the rule (or freeze prices) |
| **B-4** | Reports silently cap at 300 invoices/returns/expenses → wrong totals for any busy shop | `reports_cubit.dart:49,57,66` (`sublist(0,300)`) | Paginate or aggregate server-side; at minimum surface "showing last 300" |
| **B-5** | Owner-facing profit missing: Reports and Dashboard show no profit despite `costPrice` being stored per item | `reports_state.dart:82-86`; grep `profit` in `features/reports` = 0 hits | Add `totalProfit`/`todayProfit` = `Σ item.profit` to reports + dashboard |
| **B-6** | Zero automated tests (`test/` does not exist) | repo root | Add smoke tests: sale transaction (fractional 0.5, inactive blocked, insufficient stock), `buildActivityMessage` payloads, `openNotificationPayload` routing |

### P2 — Medium, important, not launch-blocking
| ID | Issue | Fix |
|----|-------|-----|
| **B-7** | `setState` used in **31 files** (architecture rule: Cubit only) — worst offenders: admin views, `product_form_view.dart`, `add_return_view.dart`, `update_profile_view.dart` | Migrate incrementally; block new usage in review |
| **B-8** | No stock replenishment/purchase screen — returns are the only stock-in path | New screen + `ActivityRepo` stock audit entries |
| **B-9** | No low-stock warning at sale time (badge only) | Dialog/toast in `add_sale_view` when `isLowStock` |
| **B-10** | No FCM backend — push only works when sent manually from Firebase Console | Cloud Function on `sales`/`expense` create, or accept local-only |
| **B-11** | Legacy sales (`costPrice = 0`) inflate `profitSummary()` | Treat 0-cost as "unknown", exclude or flag |
| **B-12** | Mixed localization: hardcoded Arabic in Reports labels, `activity_message.dart`, errors in `expenses_cubit.dart:77` while 636 keys exist in both `ar.json`/`en.json` (in sync, 450 used keys all present) | Move strings to keys |

### P3 — Low, future
| ID | Issue |
|----|-------|
| **B-13** | Dead code: `AppRoutes.resetPassword`, `AppRoutes.shopRegistration`, `cashRegisterCollection` |
| **B-14** | 15 files > 500 lines (largest: `admin_settings_view` 1425, `home_view` 1207, `admin_ds` 1029) |
| **B-15** | Notification id collision after ~2000 personal reminders (2000+ vs activity 4000-4999) |
| **B-16** | No on/off toggle for per-operation notifications |
| **B-17** | Cloudinary unsigned preset shipped in code (restrict on Cloudinary side) |
| **B-18** | `activity_view.dart:380` unused variable (the only analyzer warning) |

---

## 5. Cross-cutting findings

### A1 — Validation
Strong in the mutation paths that matter (sale stock/active checks are inside the transaction; expense/product/return forms validate before hitting the repo; subscription submit has a re-entrancy guard). Gaps: profile allowlist vs rules (NEEDS_TESTING), no client-side "return more than sold" check visible in `returns_cubit` (verify — the repo/rule layer must enforce it).

### A2 — Architecture compliance
- **No Domain layer** ✅ — Data (models/repos/repo impls) + Presentation (cubit/state/view/widget) only.
- **Cubit for state** ❌ — `setState(` found in **31 files / 100+ occurrences** (admin feature is entirely `setState`-based; also product form, add-sale, add-return, profile, reminders sheet, main tabs).
- **Naming/theme/responsive** ✅ — consistent `*_cubit/_state/_view/_widgets` layout, `AppTheme`, `flutter_screenutil` everywhere.

### A3 — Code health metrics
- 288 Dart files; 15 files > 500 lines.
- `dart analyze`: 0 errors, 1 warning, 45 infos (mostly `prefer_initializing_formals`).
- Translations: 636 keys × 2 languages, perfectly in sync; 450 distinct `.tr()` keys used, **0 missing**.
- No `TODO`/`FIXME`/`UnimplementedError` anywhere in `lib/`.
- No mock/hardcoded data in owner-facing features; Reports read live Firestore streams.
- Duplicated money formatting: `AdminFmt.money` (`admin_ds.dart:173`) vs private `_money` (`activity_message.dart:192`) vs `fmtReport` (`reports_state.dart:164`) — extract one helper (P3).

---

## 6. Dependencies between tasks

```
B-1 (publish rules)  ──► everything Firebase-dependent can be device-tested
B-3 (rules price)    ──► payment proof submission E2E test (3.10)
B-5 (profit)         ──► depends on nothing; highest user value
B-4 (reports cap)    ──► B-5 (profit must be computed on the same full dataset)
B-6 (tests)          ──► best written after B-4/B-5 so they cover final logic
B-8 (replenishment)  ──► B-9 (low-stock warning) is more useful once stock can be refilled
B-7 (setState)       ──► independent; do gradually, never in the launch critical path
B-10 (FCM backend)   ──► optional for launch; needs a Firebase project with billing/Functions
```

---

## 7. Launch readiness assessment

**Verdict: 🟠 NOT READY (close).**

The core money paths (register → sell → stock → expense → return) are implemented correctly and transactionally, and `dart analyze` is clean. What stands between this and Play release:

1. **Publish the Firestore rules (B-1)** — 5 minutes in the console, removes a production error on every cold start.
2. **Fix the subscription amount rule (B-3)** — otherwise the first admin price tweak silently breaks all revenue.
3. **Stop Reports from lying (B-4) and show profit (B-5)** — an accounting app that truncates at 300 invoices and shows no profit is not launchable to its own audience.
4. **Add a minimal test suite (B-6)** — at least the sale transaction and payload routing, since there is currently zero safety net.

Everything else (setState migration, replenishment screen, FCM backend, dead code) can ship in the first post-launch iterations.

---

## 8. Exact next implementation steps

1. **[Ops · P0]** Firebase Console → `hesba-business` → Firestore → Rules → paste `firestore.rules` → Publish → cold-restart app → confirm `[AppSettings]` `permission-denied` log is gone.
2. **[Rules · P1]** Rewrite `firestore.rules:174-179` to resolve the price from `admin_settings/settings` via `get()`; publish together with step 1.
3. **[Feature · P1]** `reports_state.dart`: add `double get totalProfit => sales.fold(0, (s, e) => s + e.items.fold(0, (i, it) => i + it.profit));` (+ returns profit adjustment), surface a profit card in `reports_stats.dart`; same for `todayProfit` in `dashboard_state.dart`.
4. **[Bug · P1]** `reports_cubit.dart`: remove the `sublist(0,300)` caps — query by period (`where createdAt >= start`) or page; if left, label the UI "آخر 300 فاتورة".
5. **[Tests · P1]** Create `test/` with: (a) `sales_repo` transaction logic via fake Firestore — 0.5 fractional deduct, inactive blocked, insufficient stock, wrong shop; (b) `buildActivityMessage` golden strings for sale/return/expense/product; (c) `openNotificationPayload` route mapping table.
6. **[Device · P1]** On-device pass: register (owner role accepted by rules), fractional sale 0.5, expense screen shop-name row, notification tap → correct tab, receipt submission end-to-end after step 2.
7. **[Backlog · P2]** Stock replenishment screen → low-stock sale warning → notification toggle → FCM function → incremental setState migration.
