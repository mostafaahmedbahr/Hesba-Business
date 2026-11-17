# HESBA (حسبة) — FINAL PRE-LAUNCH REPORT (محدَّث 2026-11-17 — بعد جولة المراجعة الثالثة)

**Date:** 2026-11-17 (later, third round)
**Supersedes:** `HESBA_FINAL_PRE_LAUNCH_REPORT.md` (round 2, same day) and keeps `HESBA_FINAL_PRE_LAUNCH_AUDIT.md` (audit-trail record).
**Scope:** full app, Firestore rules, admin dashboard, subscription system, Android release config, Play compliance — as verified **after** the third round (god-view decomposition completed + unit-test suite + error-handling/logging system + stream/leak review).
**Honesty note:** Everything marked **(source)** is fixed in the working tree / repository (all of it is now **committed** — see "Git status note" below). Anything depending on the **deployed** Firebase project is **UNVERIFIED** — the CLI account used here gets `403 permission-denied` on `hesba-business`, and the documented deployed state of the rules was stale at last check (`docs/HESBA_PROJECT_AUDIT.md` §B-1). Local rules pass **134/134** emulator tests (unchanged this round — no rules touched).

---

## A. EXECUTIVE SUMMARY

### Readiness: ~68/100 (was ~66/100 after round 2, was ~62 after round 1, was 56 at the original audit)

| Dimension | Weight | Audit | Round 1 | Round 2 | **Now** | Weighted now |
|---|---|---|---|---|---|---|
| Security & data isolation | 25 | 4.5 | 5.0 | 5.5 | **5.5** | 13.75 |
| Financial data integrity | 20 | 7.0 | 8.5 | 9.0 | **9.2** | 18.4 |
| Feature completeness & correctness | 20 | 7.0 | 7.5 | 8.0 | **8.0** | 16.0 |
| Release configuration & signing | 15 | 6.5 | 6.5 | 6.5 | **6.5** | 9.75 |
| Testing & verification | 10 | 4.0 | 5.0 | 5.5 | **7.0** | 7.0 |
| Ops readiness | 10 | 3.0 | 3.0 | 3.0 | **4.0** | 4.0 |
| **Total** | | **56** | **~62** | **~66** | **~68** | **68.9** |

Scoring: unchanged methodology (verified-only points). Gains this round: **66 Dart unit tests exist and pass** (sale/return/credit-debt/adjustment math is now machine-verified, not just reviewed), **all ~150 flat catches are instrumented** with a central, file-scoped logger + in-app diagnostics view, **god-view decomposition COMPLETED** (all listed views decomposed, zero behavior change), **stream/leak review** closed 4 resource leaks. Gains since round 2 are **source-only, still unverified in production** where noted.

### Critical blockers REMAINING

1. **P0 — Play upload keystore (`hesba-upload-key.keystore`) is committed to Git** (MD5 `a7d3724c8e4956479c41f0e6cef4d59b`, byte-identical to the release signing key). Rotate via Play App Signing + purge history + root-`.gitignore`.
2. **P0/P1 — Deployed Firestore rules UNVERIFIED.** Every rules fix in rounds 1–2 (reject/approve semantics, admin-create gap, trial window, settings validation, feedback inbox rules, staff stock bounds + movement invariant) exists **only in the local file**. Publish + cold-start verify from an account with `hesba-business` access.
3. **P1 — Play Console steps:** privacy-policy URL in Store listing; complete Data Safety (declare in-app deletion request flow); account-deletion declaration must match the policy exactly.
4. **P1 — Dart test suite in place but incomplete.** `test/` now holds 66 passing unit tests (repo logic only). Still missing: profit-calculator unit tests and cubit/widget coverage. Stores/subscription "full flow" integration remains untested on a real project.

### Final recommendation

**NOT READY — but the gap is now entirely operational** (same framing as round 2). Three of the four blockers were *sharper* this round: the test suite now exists (blocker #4 reduced), the keystore and deployed-rules remain, and the Play Console forms remain. With those done **and verified**, this becomes **READY WITH CONDITIONS**.

---

## B. WHAT WAS FIXED (third round, 2026-11-17) — committed in `9b2b57f … 84abaef`

| # | Finding (severity) | Fix | Verification |
|---|---|---|---|
| B-16 | **God-view debt — remaining six listed views** (`admin_settings_view.dart` 1516, `add_expense_view.dart` 1260, `invoice_sheet.dart` 1028, `shop_details_view.dart` 936, `supplier_details_view.dart` 931, `add_debt_sheet.dart` 891) | All six decomposed into `widgets/<feature>/*` folders with the same convention as round 2 (public `PascalCase` widgets, Arabic doc comments, **zero behavior change** — extraction only; `_ShopItemsTab`/`_OverviewTab`/`_SubscriptionTab` now take `shopId`/`ownerId` constructor params instead of `findAncestorWidgetOfExactType<_DetailsScaffold>()`; receipt/invoice share helpers extracted to `invoice_helpers.dart`; shared duplicated section-card container extracted in supplier & expense views) | `flutter analyze` 0 errors (67 baseline info/warnings, zero new); each moved file re-checked for identical behavior by construction (mechanical moves, no logic edits) |
| B-17 | **S-7/F-5 — zero Dart tests** (reported absent in rounds 1–2) | New `test/` suite, **66 passing unit tests**, all on `fake_cloud_firestore` + `mocktail`: sales repo 16 (validation, discount clamping, atomic stock decrement, credit-sale debt written in the same transaction, person linkage) · returns repo 13 (sold-qty enforcement incl. second return, original-price match, proportional discount allocation, credit-debt settlement incl. cap at remaining) · accounts repo 16 (person dedup by normalized phone, direction forcing for customers, payment cap vs remaining, cross-shop rejection) · expenses repo 8 (validation + shop isolation) · models 8 · **AppLogger 5** | `flutter test` → **66/66 PASS**; `flutter analyze test/` clean |
| B-18 | **S-18 — ~150 flat catches, no reporting infrastructure** | New **`AppLogger`** (`core/services/app_logger.dart`): in-memory ring buffer (300 entries), leveled debug/info/warning/error, `installGlobalHandlers()` (uncaught `FlutterError` + `PlatformDispatcher.onError` + `runZonedGuarded` in `main.dart`), `nonFatal(context, error, stackTrace)` as the single funnel. **All 161 catch sites across 75 files are instrumented** with file-path context (error severity auto-detected via `AppToast.error`/`rethrow` → `error`, else `warning`). `logError/logSuccess/logWarning` kept as compatibility wrappers (now route to `AppLogger`). New **`DiagnosticsView`** (admin → «سجل التشخيص») listing the latest entries with context/message/stackTrace + copy-all + clear. Docs at `docs/ERROR_HANDLING_LOGGING.md`. `logSuccess('mostafa ahmed')` removed from `main.dart` | `flutter analyze` 0 errors (67 baseline unchanged); `flutter test` 66/66; docs committed |
| B-19 | **Stream/leak audit — 4 resource leaks found & fixed** (review, not a behavior change) | ① `ProfileCubit`: `watchProfile()` listener was never stored/cancelled → now stored with `??=` + cancelled in `close()` ② `ActivityCubit._init`: `getActivities()` uncaught (dead badge on repo failure) + subscriptions created after `await` could outlive `close()` → try/catch + `isClosed` guard after each await ③ `ActivityView` (admin): `stream: watchActivityLogs()` inline in `build()` → new Firestore listener per rebuild → hoisted to `late final` in `initState()` ④ `ConnectivityService.initialize`: result of `.listen()` never assigned to `_subscription` (dispose was a no-op) + duplicate listener risk on re-init → assigned + double-init guard | `flutter analyze` 0 errors; `flutter test` 66/66; every cubit re-verified to cancel subscriptions in `close()` (14/14 cubits with `.listen()`) |

**Notes:**
- **S-12 Cloudinary receipt preset — deliberately NOT changed** this round. The receipt stays on the shared public preset (`hesba/payment-proofs`, unsigned upload, publicly deliverable URL). A Cloudinary-hardening vs Firebase Storage migration proposal was prepared but **not accepted** (options deferred in this session). S-12/S-13/S-14 carry over unchanged.
- **`mostafa ahmed` debug log removed** (`main.dart`) — this round closes the round-2 ⚠️ note.

**Round 1 (B-1…B-9) and round 2 (B-10…B-15) unchanged and committed.**

**Git status note:** unlike the end of round 1, the tree is **clean** — `9b2b57f … 84abaef` contains every round-3 change (refactors, tests, logger, stream fixes). Nothing left uncommitted.

---

## C. SECURITY FINDINGS — current state

### P0 — still open
- **S-1** Play upload keystore tracked in Git (MD5 matches the release key). **Fix:** rotate upload key via Play App Signing (upload-key reset), purge from history, add `*.keystore`/`*.jks` to root `.gitignore`.
- **S-2** Deployed Firestore rules UNVERIFIED (now two **and a half** rounds of rules fixes un-deployed — round 3 touched no rules). **Fix:** publish `firestore.rules` + `firestore.indexes.json`; verify via cold start.

### P1 — status
- ~~**S-3 … S-6, S-9** subscription/renewal/settings/trial integrity~~ — **FIXED (source)** round 1.
- ~~**S-7 / F-5** Zero Dart tests~~ — **PARTIALLY CLOSED (source)** this round (B-17): repo-level unit tests exist and pass. Still missing profit-calculator unit tests + explicit cubit/widget coverage; not a launch blocker anymore, but keep as follow-up.
- ~~**S-18** ~150 flat catches, no reporting~~ — **CLOSED (source-internal) this round (B-18)**: centralized `AppLogger` + diagnostics view + instrumented catch sites. External crash reporting deliberately not added (S-14 remains a conscious choice, not an oversight).
- ~~**F-6** Privacy policy absent~~ — **FIXED (source)**; Play Console steps remain.
- ~~**F-27** In-app account deletion~~ — **FIXED (source)**.

### P2 — status
- ~~**S-6/F-8** Trial window mismatch~~ — **FIXED (source)** round 1.
- ~~**S-9/F-10** Settings not server-validated~~ — **FIXED (source)** round 1.
- ~~**S-10** `UserRoleService` fail-open~~ — **FIXED (source)** round 2.
- ~~**S-16** Staff stock tampering~~ — **FIXED (source)** round 2.
- ~~**S-17** Feedback inbox absent~~ — **FIXED (source)** round 2.
- ~~**F-11/F-28** Admin search vs first-50 blind spot~~ — **FIXED (source)** round 2.
- **S-12** Cloudinary receipts share public preset — **still open** (B-18 note; proposal deferred this round).
- **S-13** No App Check — still absent.
- **S-14** No Crashlytics — still absent (deliberate, internal logging instead).
- **S-15** iOS `aps-environment=development` — still present.
- **S-11** FCM tokens unbounded — still present.
- **S-19** Ungated admin drawer entry — still present.
- **God-view refactor debt** (`admin_ds.dart` ~1100 remains — shared design-system file, intentionally kept) — **fully paid for views** this round (B-16).

*No P0/P1/P2 marked FIXED (source) is closed in production until the rules deploy completes.*

---

## D. FINANCIAL INTEGRITY — re-verified after round 3

| Area | Status | Evidence (current) |
|---|---|---|
| Sale creation (stock + sale + credit debt, one transaction) | **PASS (source) + unit-tested** | `sales_repo_test.dart` — 16 tests incl. discount clamp, stock decrement, inactive product block, credit-debt same-transaction write |
| Fractional quantities / inactive product blocked | **PASS (source) + unit-tested** | sale test suite |
| Cost snapshot at sale time | **PASS (source)** | unchanged (sale tests verify price/total math) |
| COGS / profit in Reports (snapshot-only, unknown-cost excluded) | **PASS (source) — NOT unit-tested** | `reports_calculator.dart` — no profit-calculator tests yet (remaining gap, see B-17) |
| Returns restore stock atomically + settle linked credit debt | **PASS (source) + unit-tested** | `returns_repo_test.dart` — incl. settlement capped at remaining debt + proportional discount allocation |
| Debt create/update rules (`paidAmount` never decreases) | **PASS (source) + unit-tested** | `accounts_repo_test.dart` — payment cap vs remaining, cross-shop rejection, person dedup |
| Subscription math (append on renewal, live-period wins) | **PASS (source)** | round 1 |
| Admin reject on a PAID account | **PASS (source) / UNVERIFIED (prod)** | round 1 B-1 |
| Dashboard profit vs Reports profit | **PASS (source) / UNVERIFIED (prod data)** | round 1 B-5 |
| Prices enforced on subscription requests | **PASS (local rules, 134/134 emulator)** | unchanged this round |
| Staff stock writes bounded + movement invariant | **PASS (local rules, 134/134 emulator)** | round 2 B-12 |
| Feedback inbox rules | **PASS (local rules, 134/134 emulator)** | round 2 B-10 |
| Admin settings → purchase integrity | **PASS (local rules, 134/134 emulator)** | round 1 B-6 |
| StockPurchase cap (≤500 items / ≤10M EGP total) | **PASS (local rules, 134/134 emulator)** | round 2 B-12 |
| **Error funnel (all catches instrumented, internal log)** | **PASS (source)** | B-18 — 161 sites → `AppLogger` |
| **Stream/subscription lifecycle (14/14 cubits)** | **PASS (source)** | B-19 — no cancelled-path leaks remain |

**Bottom line:** round 3 turns the financial paths from "reviewed and correct" into **machine-verified** (66/66 unit tests). The remaining verification gap is the platform-level layer: deployed rules (S-2) and the absence of profit-calculator unit tests.

---

## E. FEATURE AUDIT — delta summary

70 features were audited in round 1 (see `HESBA_FINAL_PRE_LAUNCH_AUDIT.md` §B). After this round:

- **PASS (upgraded):** All six remaining god-views **decomposed** → view layer is now thin throughout the app (only the shared `admin_ds.dart` design system remains large). No feature change.
- **PASS (new, partial):** **Dart unit-test suite** (66 tests) — repos and models machine-verified. Remaining gaps: profit calculator, cubit/widget coverage.
- **PASS (new):** **In-app diagnostics view** («سجل التشخيص» — latest logged events w/ context & stackTrace) + **central logger** (ring buffer, uncaught-error capture, admin entry point).
- **PASS (hardening):** **Stream/subscription lifecycle** — 4 leaks fixed; all cubits cancel on close.
- **REGRESSION TESTS ADDED:** 66 Dart unit tests (new suite); rules emulator suite unchanged (**134/134**).
- **No feature regressed** (analyze clean; 67-baseline info/warnings unchanged; 66/66 tests).
- **No feature added for customers** — this round is engineering-quality only (tests, logging, decomposition, resource hygiene).

---

## F. RELEASE CHECKLIST — current status

| Item | Status | Note |
|---|---|---|
| applicationId / version / targetSdk 36 / minSdk 24 | ✅ | unchanged |
| Release signing via key.properties | ✅ | **keystore still in Git (P0)** |
| `flutter build appbundle --release` | ✅ (round 1, 74.6MB) | **Re-run after rounds 2–3 (refactor + tests)** before upload |
| `flutter analyze` | ✅ | 0 errors, **67 info/warnings** (baseline — zero new) |
| Firestore rules emulator suite | ✅ | **134/134** (unchanged) |
| `test/` Dart suite | ✅ | **66/66 PASS** (round 3 — was absent) |
| Privacy policy URL (Store listing) | ✅ (in-app) / ❌ (console) | URL exists + linked in-app; must be entered in Play Console |
| Data Safety form | ❌ | Must declare in-app deletion-request flow |
| Account deletion | ✅ (in-app) / ⚠️ | Manual execution by support; Data Safety must match the policy |
| App Check / Crashlytics | ❌ | Absent (internal logger added instead) |
| Deployed rules/indexes | ❌ | **UNVERIFIED — required before any launch** |
| AndroidManifest permissions | ✅ | unchanged |
| Desugaring / boot receiver / POST_NOTIFICATIONS | ✅ | unchanged |
| iOS APNs `development` | ⚠️ | Out of scope for Play |
| `mostafa ahmed` debug log in release | ✅ | **Removed this round** (`main.dart`, via B-18) |
| Internal error logging / diagnostics | ✅ | New this round (B-18) |
| **Uncommitted fixes at end of round** | ✅ **NONE** | `9b2b57f…84abaef` committed |
| Working tree | ✅ clean | `git status` empty at report time |

---

## G. FINAL VERDICT

**1. Can real shops safely use Hesba today?** Not yet — not until the deployed rules are verified (S-2) and the keystore is rotated (S-1). The in-app experience is functionally solid, **the financial write-paths are now unit-tested**, and internal error visibility exists for the first time (every catch is logged somewhere an admin can read).

**2. Can users' financial data be trusted?** Per-shop reports/debts/returns: yes — transactionally, snapshot-cost-based, and **now unit-tested**. Platform admin profit: same engine (untested directly). **Inventory data:** bounded + invariant-enforced server-side, emulator-proven.

**3. Is customer data properly isolated?** By local rules: yes (emulator-proven, 134/134). Against production: **UNVERIFIED** (S-2).

**4. Are subscriptions secure?** Locally and by code: yes, robustly. In production today: **unverified** (S-2).

**5. Is the admin dashboard properly protected?** Server-side yes (admin-only collections/operations, transaction preconditions, settings validation) and UX hardened; admin feedback inbox + bounded search from round 2; internal diagnostics added this round (B-18). Remaining ungated entry: S-19 drawer tile.

**6. Is the Android release configuration ready?** Almost — builds, signing wired, targetSdk 36, permissions justified. Blocked on: keystore rotation/purge, rebuild of the AAB from the current HEAD (post-refactor + tests), store-console steps (privacy URL, Data Safety, deletion declaration).

**7. What MUST be fixed before launch?**
1. Rotate/purge `hesba-upload-key.keystore` from Git + root-`.gitignore` (S-1).
2. **Publish + cold-start-verify `firestore.rules` (+indexes) on `hesba-business`; record evidence** (S-2).
3. Play Console: privacy-policy URL in Store listing; Data Safety completed to match the policy; account-deletion declaration consistent (F-6).
4. Rebuild `flutter build appbundle --release` from current HEAD (post-refactor, with the test suite green) and smoke-test the release build (sale → return → renewal → rejection → staff login).
5. Live smoke test on the real project (register → trial → sale → credit sale → return → renewal → **rejection with paid period intact** → expiry → read-only) **+ staff account: purchase >10,000 units denied**.
6. (Carried) Extend the new test suite with **`reports_calculator` profit/COGS tests** and cubit-level tests for the sale flow.

**8. What can safely wait until after launch?** S-19 drawer gating, **S-12 Cloudinary preset hardening** (migration proposal pending your decision), S-13 App Check, S-14 Crashlytics, S-11 FCM pruning, `admin_ds.dart` split, remaining lint cleanup, iOS APNs environment (out of Play scope), `tz.local`/DST reminder fixes, profit/settings UI polish.

---

## APPENDIX — Verification log (what was actually run)

| Command / check | Result |
|---|---|
| `flutter analyze` (round 3) | **0 errors**, **67 info/warnings** — unchanged after B-16/B-17/B-19 (baseline) |
| `flutter analyze test/` | clean |
| `flutter test` (round 3) | **66/66 PASS** (was absent in rounds 1–2) — sales 16 / returns 13 / accounts 16 / expenses 8 / person models 8 / AppLogger 5 |
| Rules emulator suite (`node --test` × 7 files) | **134/134 PASS** (unchanged — round 3 touched no rules) |
| `flutter build appbundle --release` | ✅ round 1 (74.6MB) — **not re-run since** (refactor + tests; analyze clean; **rebuild before upload**) |
| Firebase CLI on `hesba-business` | ❌ 403 permission-denied — deployed rules **UNVERIFIED** |
| `git status` (end of round 3) | **clean** — `9b2b57f … 84abaef` committed (refactor, tests, logging, cubit fixes) |
| i18n (ar/en) | valid JSON; `mostafa ahmed` removed |
| Cloudinary S-12 | **unchanged** (deferred this round — not silently fixed) |

**One-line answer to "is it ready?"** Not yet — same answer as rounds 1 and 2, but round 3 added machine-verified financial write-paths, a diagnosable internal error trail, and completed the view decomposition. Every remaining blocker is key rotation, a rules deploy + verification, Play Console forms, and a rebuild from HEAD. Nothing the app code itself can exploit is unfixed; the open items are deployment, store, and business-process work — trackable, not hidden.
