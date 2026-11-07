# Hesba — Dynamic Subscription Pricing Fix

> **Date:** 2026-11-07
> **Repo:** `E:\projects\Hesba-Business`
> **Stack:** Flutter 3.32.5 · Cloud Firestore · Firestore Security Rules · Cubit
> **Scope:** subscription prices must be dynamic, admin-controlled, and validated
> server-side — without trusting the Flutter client.
> **Restrictions honored:** no Firebase Rules deployed · no live prices changed ·
> no production data modified · no Domain layer · no `setState` in new code ·
> no unnecessary runtime dependencies (the only new dependency is a **dev-only**
> test package for rules tests).

---

## 1. What was wrong (inspection findings)

| # | Area | Finding |
|---|------|---------|
| 1 | Current pricing implementation | Prices are read live from `admin_settings/settings` by the Flutter app (`subscription_plan.dart` → `AppSettingsService`), **but the Firestore rules hardcoded `99/249/449/799`**, so any admin price change would make every new payment request fail (or, before the hardcode existed, be unvalidated). |
| 2 | `admin_settings/settings` structure | `{ monthlyPrice: int, threeMonthsPrice: int, sixMonthsPrice: int, yearlyPrice: int, trialDays: int, paymentMethods: [{id,label,number}], updatedAt }`. Defaults: **99 / 249 / 449 / 799**. Readable by any signed-in user; written by admin only. |
| 3 | `subscription_plan.dart` | `plan.price` already returns the live settings value per plan id (`monthly / threeMonths / sixMonths / yearly`). Durations are fixed: **30 / 90 / 180 / 365 days**. |
| 4 | `subscription_repo_impl.dart` | `submitRequest()` sent `amount: plan.price` but did **not** refresh settings immediately before pricing the request, so a price changed while the paywall was open could produce a stale amount (which the rules would then reject). |
| 5 | Approval logic (`admin_repo_impl.dart`) | `approveRequest()` runs a transaction: appends `request.plan.days` to the live end date (never restarts or shortens an active period), sets `status: active`. `rejectRequest()` is admin-only. Approval duration comes from the **plan**, not the price. |
| 6 | `firestore.rules` | `subscription_requests` create validated the amount against hardcoded constants; update was already `isAdmin()` only; subscription `active` transition already required an admin-approved request. |

---

## 2. Modified files

| File | Change |
|------|--------|
| `firestore.rules` (lines ~169-212) | Amount validation is now **dynamic**: `amount` must equal the price configured in `admin_settings/settings` for exactly the selected plan. Added `amount is int` + `amount > 0` guards and an `exists()` guard so a missing settings doc / missing price field can never error-match. Fallback to the built-in defaults (99/249/449/799, constants written in the rules) **only** when the settings doc does not exist yet. Nothing else was loosened: `status == 'pending'` on create, `allow update: if isAdmin()`, `allow delete: if false` all unchanged. |
| `lib/features/subscription/data/repos_impl/subscription_repo_impl.dart` (`submitRequest`) | Added `await AppSettingsService.refresh()` right before the request is built, so the submitted `amount` uses the freshest admin price (the rules validate exactly this value server-side). |
| `lib/core/services/app_settings_service.dart` | Added `@visibleForTesting debugSetCurrent()` / `debugReset()` hooks so tests can simulate an admin price change **without touching Firestore**. Production code never calls them. |
| `test/subscription_pricing_test.dart` | **New** — 9 Flutter unit tests (first tests in the project). |
| `rules_tests/` (`package.json`, `rules.test.js`) | **New** — 11 Firestore rules tests running on the **local emulator only** (dev-dependency `@firebase/rules-unit-testing` + `firebase`; nothing added to `pubspec.yaml`). |
| `.gitignore` | Ignores `node_modules/` (for `rules_tests/`). |

Unchanged on purpose: `admin_settings.dart`, `subscription_plan.dart`,
`admin_repo_impl.dart` (approval/duration logic was already correct),
`admin_settings_view.dart` / `admin_settings_cubit.dart` (admin already can edit
any price and it saves to `admin_settings/settings`), `subscription_cubit.dart`
(already calls `AppSettingsService.refresh()` on load).

---

## 3. Security changes (no weakening)

1. **Amount is never trusted from the client.** The rules read the price from
   `admin_settings/settings` (a document only admins can write) and require
   `request.resource.data.amount` to equal the configured price of exactly the
   selected plan.
2. **Plan id cannot be swapped.** Each plan id is bound to its own price field;
   an unknown id (`lifetime`) or a mismatched id/amount pair matches no branch
   → denied.
3. **Type/value guards:** `amount is int && amount > 0`, and price fields are
   read with `.get('<field>', -1)` — a missing field yields `-1`, which a
   positive amount can never equal.
4. **Access-call budget:** worst case ≈ 2 `exists()` + 1 `get()` + `isAdmin()`'s
   `get()` ≈ 4 of the 10 allowed per evaluation (20 for the 2-write batch in
   `submitRequest`) — verified live on the emulator.
5. **Self-approval still impossible:** `subscription_requests` update remains
   `isAdmin()` only; a request can never be *created* with `status: 'approved'`;
   the subscription `active` transition still requires a request whose stored
   `status == 'approved'` (written by an admin).
6. **Cloud Functions were NOT needed:** the existing schema
   (`selectedPlan` + `amount` on the request, prices on `admin_settings`) lets
   Rules validate the price fully server-side, so no `functions/` project was
   introduced. If the schema ever needs server-computed pricing (e.g. discounts
   or taxes), that would be the point to add a callable function.
7. **Fail modes are safe:** if `admin_settings/settings` is missing, only the
   built-in defaults are accepted (still server-side constants); if a price
   field is missing/mistyped, submission is denied (fail-closed), never
   silently accepted.

---

## 4. Required behavior — where each is satisfied

| Requirement | Where |
|-------------|-------|
| Admin can change any price | `admin_settings_view.dart` → `AdminSettingsCubit` → `admin_settings/settings` (existing, verified) |
| Flutter shows latest prices | `subscription_plan.price` reads `AppSettingsService`; refreshed on screen load **and** now right before submit |
| Payment request uses current price | `submitRequest()` → `AppSettingsService.refresh()` → `amount: plan.price` |
| Firestore validates amount vs trusted pricing | `firestore.rules` create rule (dynamic `get()` of settings) |
| Users cannot manipulate amount or plan id | Rules: amount↔plan binding + `is int` + `> 0` (emulator-tested) |
| Users cannot approve their own requests | Rules: create=`pending` only, update=`isAdmin()` only (emulator-tested) |
| Only admins approve/reject | `isAdmin()` on `subscription_requests` update; `approveRequest`/`rejectRequest` admin-only (emulator-tested) |
| Existing pending requests survive a price change | Validation happens at **create** time only; the stored `amount` is frozen at submission. The admin still reviews/approves old rows after a change (approval grants `plan.days`, independent of price). Emulator-tested. |
| Existing active subscriptions keep their end date | `approveRequest` appends `plan.days` to the *live* end date only when there is one; no rule or code change touched stored periods |
| Approved subscriptions get correct duration | Duration = `SubscriptionPlan.days` (30/90/180/365) — unchanged, unit-tested |

---

## 5. Test results

### `flutter analyze`
```
46 issues found → 0 errors, 1 warning, 45 infos
```
Identical to the pre-change baseline (the single warning is the pre-existing
`activity_view.dart:380 unused_local_variable`). **No new issues.**

### `flutter test` — `test/subscription_pricing_test.dart` → **9/9 passed**
- Default prices 99/249/449/799 and durations 30/90/180/365
- `AdminSettings.fromJson` parsing + defaults for missing fields
- Admin price change immediately changes `plan.price`
- Payment request built with the current price (`amount: plan.price`)
- Old pending request keeps its submitted amount after a price change
- Rules file: dynamic settings lookup, `is int` / `> 0`, all 4 plan branches,
  `allow update: if isAdmin()`, `status == 'pending'`, `active` requires an
  approved request

### Rules tests (local Firestore emulator, nothing deployed) → **11/11 passed**
```
firebase emulators:exec --only firestore --project hesba-business \
  "node --test rules_tests/rules.test.js"
```
| Required scenario | Result |
|---|---|
| 1. Monthly at 99 | ✅ accepted |
| 2. 3-months at 249 | ✅ accepted |
| 3. 6-months at 449 | ✅ accepted |
| 4. Yearly at 799 | ✅ accepted |
| 5. Admin changes monthly → 149 | ✅ settings updated |
| 6. Customer pays new price 149 | ✅ accepted; stale 99 rejected |
| 7. Tampered amount (1, 0, −99, `"99"` string, wrong-plan amounts, 999999) | ✅ all rejected |
| 8. Tampered plan id (`lifetime`, swapped ids) | ✅ all rejected |
| 9. Unauthorized approval (requester, stranger, guest, born-approved) | ✅ rejected; seeded admin approve/reject allowed |
| 10. Pending request created at old price, price changed afterwards | ✅ still reviewable by admin; activation with a *pending* request impossible; activation works only after admin approval; new submission at the old price rejected |

The emulator ran with the real `firestore.rules` file — this is a genuine
execution of the rules, not a string check.

---

## 6. Remaining manual actions

1. **🔴 Publish the rules (NOT done — by instruction).** The deployed console
   rules are still the stale version (audit P0). Until the updated
   `firestore.rules` is pasted into **Firebase Console → Firestore → Rules**
   (or deployed from an authenticated CLI account with access to
   `hesba-business`), production keeps the old hardcoded behavior. Recommended
   before publish: re-run the rules test command above once more.
2. **Verify the production settings doc types.** The rules expect the four
   price fields to be **integers** (e.g. `99`, not `99.0`). The dashboard
   always writes ints; if anyone edited the doc in the console and stored
   doubles, fix them to ints in the console (this is a data edit — not done).
3. **Review policy for pending requests after a price change.** The stored
   `amount` is the price at submission time; the admin should compare it with
   the current price when reviewing (the admin UI already displays it). No
   automatic re-validation on approval — intentional, so already-paid receipts
   are not lost.
4. **On-device pass (manual):** the 10 scenarios end-to-end in the two apps
   (customer paywall + admin approve/reject), because receipt upload (Cloudinary)
   and the admin UI cannot be exercised from unit/emulator tests.
5. **Optional hardening (not done, out of scope):** a Cloud Function to
   recompute the amount server-side on approval; emulators config in
   `firebase.json`; CI job running `flutter test` + rules tests.

---

## 7. How to re-run everything

```powershell
# Static analysis + Flutter tests
C:\dev\flutter_3.32.5\bin\flutter.bat analyze
C:\dev\flutter_3.32.5\bin\flutter.bat test

# Rules tests (local emulator only — never deploys)
cd E:\projects\Hesba-Business
npm --prefix rules_tests install
firebase emulators:exec --only firestore --project hesba-business "node --test rules_tests/rules.test.js"
```
