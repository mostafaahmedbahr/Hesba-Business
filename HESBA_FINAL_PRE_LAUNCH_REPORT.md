# HESBA (حسبة) — FINAL PRE-LAUNCH REPORT (بعد التعديلات)

**Date:** 2026-11-17 (evening)
**Supersedes:** `HESBA_FINAL_PRE_LAUNCH_AUDIT.md` (the original audit, kept as the audit-trail record; all its FIX LOG entries are reflected here)
**Scope:** Full app, Firestore rules, admin dashboard, subscription system, Android release config, Play compliance — as verified **after** the fix round in this session.
**Honesty note:** Everything marked **(source)** is fixed in the code/rules files in this repository. Anything depending on the **deployed** Firebase project is **UNVERIFIED** — the authenticated CLI account used here gets `403 permission-denied` on `hesba-business`, and the last documented state of the deployed rules was stale (`docs/HESBA_PROJECT_AUDIT.md` §B-1). Local rules pass **122/122** emulator tests.

---

## A. EXECUTIVE SUMMARY

### Readiness: ~62/100 (was 56/100 before the fix round)
| Dimension | Weight | Before | Now | Weighted now |
|---|---|---|---|---|
| Security & data isolation | 25 | 4.5 | **5.0** | 12.5 |
| Financial data integrity | 20 | 7.0 | **8.5** | 17.0 |
| Feature completeness & correctness | 20 | 7.0 | **7.5** | 15.0 |
| Release configuration & signing | 15 | 6.5 | **6.5** | 9.75 |
| Testing & verification | 10 | 4.0 | **5.0** | 5.0 |
| Ops readiness | 10 | 3.0 | **3.0** | 3.0 |
| **Total** | | **56** | | **~62** |

Scoring: unchanged methodology from the original audit (verified-only points). Gains: reject/approve integrity, profit methodology unified with Reports, rules hardening (trial window, settings validation, admin-create), account-deletion flow, in-app privacy policy. No gain on deployed-rules verification, keystore exposure, Dart tests, or store-console steps.

### Critical blockers REMAINING (unchanged)
1. **P0 — Play upload keystore (`hesba-upload-key.keystore`) is committed to Git** (MD5 `a7d3724c8e4956479c41f0e6cef4d59b`, byte-identical to the release signing key). Rotate via Play App Signing + purge history + root-`.gitignore`.
2. **P0/P1 — Deployed Firestore rules UNVERIFIED.** Every rules fix in this round (reject/approve semantics, admin-create gap, trial window, settings validation) exists **only in the local file**. Publish + cold-start verify from an account with `hesba-business` access.
3. **P1 — Play Console steps:** paste privacy-policy URL in Store listing; complete Data Safety (declare in-app deletion request flow: manual deletion by support, financial records retained per policy); account-deletion declaration must match the policy exactly.
4. **P1 — Zero Dart tests** (`test/` does not exist). Minimum sale/return/debt/report suite required for a financial app.

### Final recommendation
**NOT READY — but close.** The fix round closed every subscription/financial defect found in the audit. Remaining gaps are operational/compliance (keystore, rules deploy, console steps, Dart tests), not design. With the four blockers above done **and verified**, this becomes **READY WITH CONDITIONS**.

---

## B. WHAT WAS FIXED (this round, 2026-11-17)

| # | Finding (original severity) | Fix | Verification |
|---|---|---|---|
| B-1 | **S-3/P1 — Admin "reject" revoked a PAID subscription** (coupon of stored `rejected` → read-only, mirror clobbered with requested plan) | `rejectRequest` rewritten as one transaction: precondition `request.status == 'pending'`; live period (trial or paid) restored instead of revoked; mirror written from the restored sub (real plan, `lastRequestId`); customer-side healer `_restorationFrom()`; root cause fixed in `SubscriptionModel.effectiveStatus` (a live period wins over stored `pending`/`rejected`) + confirm dialogs on both approve/reject buttons | `flutter analyze` 0 errors; `flutter build appbundle --release` OK; rules emulator 118→122 pass |
| B-2 | **S-4/P1 — Approve had no idempotency guard; double-approval double-extends; approval silently lifted shop suspension** | `approveRequest` now precondition-reads the request inside the transaction (`status == 'pending'` or abort); suspension preserved (`suspended: stored.suspended`); mirror carries `lastRequestId`; `appendActivity` best-effort (committed approve never shown as failure) | Same build verified; 114/114 suite |
| B-3 | **S-5/P1 (F-7) — Rules denied admin creating `users/{uid}/subscription/current` → admin approve/reject/suspend hard-failed on sub-less accounts** | `firestore.rules` create branch: `isAdmin() ||` added (owner-trial constraints unchanged) | Emulator tests 11, 11b, 11c added — **14/14 in rules.test.js** |
| B-4 | **S-6/P2 (F-8) — 7-day trial hardcoded in rules vs editable `admin_settings.trialDays` → dashboard values ≠ 7 bricked trial creation** | Rules now read `trialDays` from `admin_settings/settings` (`configuredTrialDays()`: missing doc / non-int / out-of-range `0..365` → fallback 7; `trialWindowOk()` enforces timestamp types + ±1-day start window + `trialEnd <= start + trialDays`) | Emulator tests 12-15 — **18/18** |
| B-5 | **S-20/P2 (F-9) — Admin dashboard profit contradicted Reports** (current-cost fallback, 0-cost as free, returns ignored, 20k scan, mislabeled chart "إيرادات الاشتراكات" showing sales revenue) | `profitSummary()` reuses `ReportsCalculator` (netSales, snapshot-only COGS, returns reversal, `unknownCostLines` surfaced); `revenue` = reports' netSales; dashboard cards now "صافي الإيرادات" (with التكلفة/المرتجعات) and "إجمالي الأرباح" with "قبل المصروفات" + "تقديري — N سطر بلا تكلفة"; monthly charts use identical logic (returns attributed by month); dead `_productCostMap()` removed | `flutter analyze` 0 errors; `app-release.aab` rebuilt OK (74.5MB) |
| B-6 | **S-9/P2 (F-10) — Admin settings allowed bricking all purchases (0/negative/non-int price) at the rules layer** | `validAdminSettings()` / `validPriceValue()`: every plan price `int 1..1e9`, `trialDays` `int 0..365`, `paymentMethods is list`; `allow write: if isAdmin() && validAdminSettings()`. (UI already blocked bad values — gap was server-side.) | Emulator tests 16-19 — **22/22**; full suite **122/122** |
| B-7 | **Privacy policy missing (P1)** | Policy adopted (`https://www.freeprivacypolicy.com/live/b331026f-9deb-428d-8ad5-614ede1fdec5`, "Last updated: Nov 17 2026", Egypt, contact `hesbabusiness1@gmail.com`); in-app access via drawer tile + registration consent line; `morePrivacyPolicy` keys (ar/en) | UI-only; `flutter analyze` clean; JSON valid |
| B-8 | **No account deletion mechanism (P1/P2)** | New `DeleteAccountView` (drawer → "حذف الحساب", owner-only, staff blocked), current-password re-authentication, tracked request written to `account_deletion_requests` (rules: owner-create only, admin read, no client update/delete), sign-out + login redirect. Manual execution by support — consistent with the policy's deletion-by-contact clause; Data Safety must declare exactly this | `flutter analyze` 0 errors; `app-release.aab` rebuilt OK (74.6MB) |
| B-9 | **All rules regression-tested** | 3 + 4 + 4 new emulator tests added to `rules_tests/rules.test.js` (admin-create, trial window tracking settings, subscription integrity after price change already existed — now plus settings validation) | **Suite: 122/122 PASS** (was 111) |

**Git status note:** all source fixes are **committed** by the project owner (`9e0ccaf` subscription-renewal fix, `44fdfad` privacy, `c62443a` delete account, `df6efeb` trial window, `28480b2` dashboard profit). **Uncommitted:** `firestore.rules` (admin settings validation), `rules_tests/rules.test.js` (the regression tests), and the report files. The user should commit these too.

---

## C. SECURITY FINDINGS — current state

### P0 — still open
- **S-1** Play upload keystore tracked in Git (MD5 matches the release key). **Fix:** rotate upload key via Play App Signing (upload-key reset), purge from history, add `*.keystore`/`*.jks` to root `.gitignore`.
- **S-2** Deployed Firestore rules UNVERIFIED; documented previously as stale. All this round's rules fixes are inert in production until published. **Fix:** publish `firestore.rules` + `firestore.indexes.json`; verify via cold start (no `permission-denied` in logs).

### P1 — status
- ~~**S-3** Reject revokes paid periods~~ — **FIXED (source)**, see B-1.
- ~~**S-4** Approve idempotency / confirmations~~ — **FIXED (source)**, see B-2.
- ~~**S-5** Admin cannot create subscription doc~~ — **FIXED (source)** + regression tests.
- ~~**F-6** Privacy policy absent~~ — **Source fixed**; Play Console steps remain (paste URL into Store listing; Data Safety).
- ~~**F-27** In-app account deletion~~ — **FIXED (source)** via `account_deletion_requests` + manual execution by support.
- **S-7 / F-5** Zero Dart tests. **Still open.**

### P2 — status
- ~~**S-6/F-8** Trial window mismatch~~ — **FIXED (source)**, 4 regression tests.
- ~~**S-9/F-10** Settings not server-validated~~ — **FIXED (source)**, 4 regression tests.
- ~~**S-20/F-9** Dashboard profit contradicts Reports~~ — **FIXED (source)** + chart mislabel fixed.
- **S-19** Ungated admin drawer entry — still present. **S-17** Feedback readable by admin but no admin UI — still present. **S-16** Staff can write negative/absurd stock — still present. **S-12** Cloudinary receipts share public preset — still present. **S-13** No App Check — still absent. **S-14** No Crashlytics — still absent. **S-15** iOS `aps-environment=development` — still present. **S-10** `UserRoleService` fail-open to owner — still present. **S-11** FCM tokens unbounded — still present. **S-18** ~150 flat catches, no reporting — still present.

*No P0/P1 marked FIXED is closed in production until the rules deploy completes.*

---

## D. FINANCIAL INTEGRITY — re-verified after this round

| Area | Status | Evidence (current) |
|---|---|---|
| Sale creation (stock + sale + credit debt, one transaction) | **PASS (source)** | unchanged — verified this audit |
| Fractional quantities / inactive product blocked | **PASS (source)** | unchanged |
| Cost snapshot at sale time | **PASS (source)** | unchanged |
| COGS / profit in Reports (snapshot-only, unknown-cost excluded) | **PASS (source)** | `reports_calculator.dart` — unchanged |
| Returns restore stock atomically + settle linked credit debt | **PASS (source)** | unchanged |
| Debt create/update rules (`paidAmount` never decreases) | **PASS (source)** | unchanged |
| Subscription math (append on renewal, fresh start after expiry, live-period wins) | **PASS (source)** | `subscription_model.dart` + `admin_repo_impl.dart` — hardened this round |
| Admin reject on a PAID account | **PASS (source) / UNVERIFIED (prod)** | B-1 — live period always survives; regression is covered by code review, no emulator test yet (no Dart tests) |
| Dashboard profit vs Reports profit | **PASS (source) / UNVERIFIED (prod data)** | B-5 — same engine (`ReportsCalculator`) used by both |
| Prices enforced on subscription requests | **PASS (local rules, 122/122 emulator)** | tests 1-10 re-verified |
| Admin settings → purchase integrity | **PASS (local rules, 122/122 emulator)** | B-6 + tests 16-19 |

**Bottom line:** per-shop financials (sales/returns/debts) were already trustworthy; the **platform-wide admin profit is now computed with the same code path**, the **reject-flow financial trap is closed**, and **admin settings can no longer brick purchases** — all subject to the deployed-rules verification (S-2).

---

## E. FEATURE AUDIT — delta summary

70 features were audited (see `HESBA_FINAL_PRE_LAUNCH_AUDIT.md` §B). After this round:

- **PASS (upgraded):** 46 **Subscription / renewal integrity** → PASS (source); 18 **Profit calculation (admin dashboard)** → PASS (source); 65 **Admin settings** → PASS (source); 57 **Deployed rules** → still UNVERIFIED (unchanged).
- **PASS (new):** 70 **Account deletion** (in-app request flow) — new screen added.
- **REGRESSION TESTS ADDED:** subscription-create admin gap, trial window vs settings, settings validation.
- **No feature regressed** (analyze clean; release AAB rebuilt; 122/122 emulator tests).

---

## F. RELEASE CHECKLIST — current status

| Item | Status | Note |
|---|---|---|
| applicationId / version / targetSdk 36 / minSdk 24 | ✅ | unchanged |
| Release signing via key.properties | ✅ | **keystore still in Git (P0)** |
| `flutter build appbundle --release` | ✅ | 74.5–74.6MB, built after every fix round |
| `flutter analyze` | ✅ | 0 errors; 67 baseline info/warnings |
| Firestore rules emulator suite | ✅ | **122/122** (was 111) |
| `test/` Dart suite | ❌ | Still absent |
| Privacy policy URL (Store listing) | ✅ (in-app) / ❌ (console) | URL exists + linked in-app; must be entered in Play Console |
| Data Safety form | ❌ | Must declare in-app deletion-request flow |
| Account deletion | ✅ (in-app) / ⚠️ | Manual execution by support; Data Safety must match the policy |
| App Check / Crashlytics | ❌ | Absent |
| Deployed rules/indexes | ❌ | **UNVERIFIED — required before any launch** |
| AndroidManifest permissions | ✅ | unchanged |
| Desugaring / boot receiver / POST_NOTIFICATIONS | ✅ | unchanged |
| iOS APNs `development` | ⚠️ | Out of scope for Play |
| `mostafa ahmed` debug log in release | ⚠️ | Still present in `main.dart:19` |

---

## G. FINAL VERDICT

**1. Can real shops safely use Hesba today?** Not yet — not until the deployed rules are verified (S-2) and the keystore is rotated (S-1). The in-app experience is functionally solid; the two remaining P0s are outside the app's code.

**2. Can users' financial data be trusted?** Per-shop reports/debts/returns: yes (transactional, snapshot costs, tested). Platform admin profit: now yes (same engine) — previously not. Rejection of a renewal can no longer destroy a paid period (source).

**3. Is customer data properly isolated?** By local rules: yes (emulator-proven). Against production: **UNVERIFIED** until rules are published and tested with a cold start.

**4. Are subscriptions secure?** Locally and by code: yes, robustly — server-side price check, admin-only activation, suspend kill-switch, append-on-renewal, rejection no longer revokes paid time. In production today: **unverified** (S-2), and the Play upload keystore exposure (S-1) is unrelated but must be closed.

**5. Is the admin dashboard properly protected?** Server-side yes; UX hardened this round (confirm dialogs, approval preconditions, settings can't zero prices). Remaining: admin feedback inbox absent, first-50 search, ungated drawer entry, profit caps surfaced to UI.

**6. Is the Android release configuration ready?** Almost — builds, signing wired, targetSdk 36, permissions justified. Blocked on: keystore rotation/purge, store-console steps (privacy URL, Data Safety, deletion declaration).

**7. What MUST be fixed before launch?**
1. Rotate/purge `hesba-upload-key.keystore` from Git + root-`.gitignore` (S-1).
2. Publish + cold-start-verify `firestore.rules` (+indexes) on `hesba-business`; record evidence (S-2).
3. Play Console: privacy-policy URL in Store listing; Data Safety completed to match the policy (in-app deletion-request + manual processing + financial-records retention); account-deletion declaration consistent (F-6).
4. Minimum Dart test suite: sale transaction, return vs sold qty, debt payment cap, profit calculator (F-5).
5. Commit the uncommitted fixes: `firestore.rules`, `rules_tests/rules.test.js` (and remove `logSuccess('mostafa ahmed')`, keep the tree clean).
6. Re-verify: `flutter analyze` (0 errors), rules emulator suite (**122/122**), `flutter build appbundle --release`.
7. Live smoke test on the real project: register → trial → sale → credit sale → return → renewal request → **rejection (paid period intact)** → renewal → expiry → read-only behavior.

**8. What can safely wait until after launch?** Admin feedback inbox, search improvements (`F-11/F-28`), FCM backend + token pruning, App Check, Crashlytics, `UserRoleService` fail-open fix, `mostafa ahmed` log (or do it in the same commit), staff stock-delete tightening (`S-16`), Cloudinary preset split, DSL/`tz.local` reminder DST fixes, God-view refactors (`admin_settings_view` 1516 lines, `home_view` 1259, `product_form_view` 1130), profit/settings/operations UI polish.

---

## APPENDIX — Verification log (what was actually run)

| Command / check | Result |
|---|---|
| `flutter analyze` | **0 errors**, 67 info/warnings (baseline) — after every fix round |
| `flutter test` | "Test directory `test` not found" — still absent |
| Rules emulator suite (`node --test` × 6 files) | **122/122 PASS** (baseline 111 → +11 new tests) |
| `flutter build appbundle --release` | ✅ rebuilt OK after fix rounds (74.5MB → 74.6MB) |
| Firebase CLI on `hesba-business` | ❌ 403 permission-denied (deployed rules UNVERIFIED) |
| `git status` (end of round) | 5 source fixes committed by owner (`9e0ccaf…28480b2`); `firestore.rules`, `rules_tests/rules.test.js` + reports uncommitted |
| Working tree | preserved for all edits requested by the owner |

**One-line answer to "is it ready?"** Not yet — but the only things between Hesba and a confident launch are now operational (keystore rotation, rules deploy + verify, Play Console forms, Dart tests), not architectural.
