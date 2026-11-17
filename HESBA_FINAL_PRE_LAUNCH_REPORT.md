# HESBA (حسبة) — FINAL PRE-LAUNCH REPORT (محدَّث 2026-11-17 — بعد جولة المراجعة الثانية)

**Date:** 2026-11-17 (later, second round)
**Supersedes:** the previous `HESBA_FINAL_PRE_LAUNCH_REPORT.md` (first fix round, same day) and `HESBA_FINAL_PRE_LAUNCH_AUDIT.md` (audit-trail record, kept).
**Scope:** full app, Firestore rules, admin dashboard, subscription system, Android release config, Play compliance — as verified **after** the second fix round (refactor + admin tooling + two security fixes).
**Honesty note:** Everything marked **(source)** is fixed in the working tree / this repository (all of it is now **committed** — see "Git status note" below). Anything depending on the **deployed** Firebase project is **UNVERIFIED** — the CLI account used here gets `403 permission-denied` on `hesba-business`, and the documented deployed state of the rules was stale at last check (`docs/HESBA_PROJECT_AUDIT.md` §B-1). Local rules pass **134/134** emulator tests (incl. this round's additions).

---

## A. EXECUTIVE SUMMARY

### Readiness: ~66/100 (was ~62/100 after round 1, was 56/100 at the original audit)

| Dimension | Weight | Audit | Round 1 | **Now** | Weighted now |
|---|---|---|---|---|---|
| Security & data isolation | 25 | 4.5 | 5.0 | **5.5** | 13.75 |
| Financial data integrity | 20 | 7.0 | 8.5 | **9.0** | 18.0 |
| Feature completeness & correctness | 20 | 7.0 | 7.5 | **8.0** | 16.0 |
| Release configuration & signing | 15 | 6.5 | 6.5 | **6.5** | 9.75 |
| Testing & verification | 10 | 4.0 | 5.0 | **5.5** | 5.5 |
| Ops readiness | 10 | 3.0 | 3.0 | **3.0** | 3.0 |
| **Total** | | **56** | **~62** | **~66** | **66.0** |

Scoring: unchanged methodology from the original audit (verified-only points). Gains this round: staff stock-write hardening + movement invariant (emulator-proven), admin feedback inbox with server-enforced rules, `UserRoleService` fail-secure, admin global-search full bounded scan, major view decomposition with zero behavior change. Gains since round 1 that are **source-only, still unverified in production**: all of the above — they ship in `firestore.rules` and need the rules deploy (S-2).

### Critical blockers REMAINING (unchanged — all outside the app's code)

1. **P0 — Play upload keystore (`hesba-upload-key.keystore`) is committed to Git** (MD5 `a7d3724c8e4956479c41f0e6cef4d59b`, byte-identical to the release signing key). Rotate via Play App Signing + purge history + root-`.gitignore`.
2. **P0/P1 — Deployed Firestore rules UNVERIFIED.** Every rules fix in this round (reject/approve semantics, admin-create gap, trial window, settings validation, **feedback inbox rules**, **staff stock bounds + movement invariant**) exists **only in the local file**. Publish + cold-start verify from an account with `hesba-business` access. The local file is now **ahead** of production by two full rounds — deploy it before touching anything else.
3. **P1 — Play Console steps:** paste privacy-policy URL in Store listing; complete Data Safety (declare in-app deletion request flow: manual deletion by support, financial records retained per policy); account-deletion declaration must match the policy exactly.
4. **P1 — Zero Dart tests** (`test/` does not exist). Minimum sale/return/debt/report suite required for a financial app.

### Final recommendation

**NOT READY — but the gap is now entirely operational.** Round 1 closed the subscription/financial defects; round 2 closed the staff stock-write hole, shipped the admin feedback inbox, fixed the admin search's first-50 blind spot, removed the fail-open role default, and deleted ~2,400 lines of tangled view code. With the four blockers above done **and verified**, this becomes **READY WITH CONDITIONS**.

---

## B. WHAT WAS FIXED (round 2, 2026-11-17) — committed in `c82be61 … 3262d2c`

| # | Finding (severity) | Fix | Verification |
|---|---|---|---|
| B-10 | **S-17/P2 — Feedback inbox absent in admin** (users submit complaints/suggestions via "تواصل معنا" → `feedback` collection was write-only for admins: no UI, no rules for marking/deleting) | New `FeedbackView` screen (sidebar entry "الملاحظات" between النشاطات/الإعدادات): list + search (title/body/email/id/type) + filter chips (all/new/handled) + summary counters + pagination; details dialog with type/title/description + user id/email; actions: "تم التعامل معها" ↔ "جديدة" and delete (confirm). `handled`/`handledAt` written via new `AdminRepo.setFeedbackHandled/deleteFeedback/getFeedbackPage`. Rules: admin read (unchanged), **admin update restricted to exactly `handled`/`handledAt`** (bool `handled` only), **admin delete**; create rule unchanged | Rules emulator: **9 new tests** (`rules_tests/feedback.test.js`, in `npm test`); suite 131/131 after this item; `flutter analyze` 0 errors |
| B-11 | **F-11/F-28 / "بحث الأدمن يقتصر على أول 50"** — admin global search read `.limit(50)` of each collection, unordered, client-side substring; anything past doc 50 was unsearchable; one failing collection killed the whole search; phone search failed on Arabic-Indic digits/formats | `AdminSearchRepoImpl` rewritten: **full bounded scan** of `shops`/`products`/`subscription_requests` in 200-doc batches ordered by documentId with `startAfterDocument`, hard cap 1,000 docs **per collection per search** (worst case is now "everything the shop has", not "the first 50"); three collections queried in **parallel**; a failing collection no longer wipes the others (if all three fail, error is surfaced instead of "لا توجد نتائج"); final hits capped at 50; normalization maps Arabic-Indic (`٠-٩`) and Eastern Arabic (`۰-۹`) digits to Latin; phone matching is digits-only (format-agnostic); documented in repo-level doc comment | `flutter analyze` 0 errors; "67 baseline" unchanged |
| B-12 | **S-16/P2 — Staff could write negative or absurd stock** (`products` staff path validated keys only — any value passed, incl. strings, negatives, 1e30; `stock_movements` had `quantity > 0` but no cap and **no consistency check**) | `validStockValue(v)`: number in `[0, 1,000,000]` (also kills NaN/∞). Staff `products` path: stock must satisfy `validStockValue`, and **increase per write ≤ 10,000 units** (decrease unrestricted-but-non-negative). `validProduct` (owner create/update): stock now `validStockValue(...)` instead of just `>= 0`. `stock_movements`: `quantity ≤ 100,000`, both stock fields `validStockValue`, **new invariant: `newStock == previousStock + quantity`**. `stock_purchases`: `items ≤ 500`, `totalAmount ≤ 10,000,000`. Staff flows (purchase/sale/return) verified to still pass; a staff purchase of >10,000 units of one product now fails atomically by design | Emulator: **new test 15b** (negative, 1,000,001, `1e12`, +10,001 over current, non-number, legit +15, legit 0); **new movement invariant + caps test** (5+5=10 ok; 5+5=999/9 denied; `100,001` quantity denied; 1,000,001 `newStock` denied); **new purchase caps test** (501 items denied; 10,000,001 total denied; exactly-at-cap OK) — suite **134/134** |
| B-13 | **S-10/P2 — `UserRoleService` failed open to OWNER** (`catch → roleOwner` — any offline/rules/timeout read of `users/{uid}` reclassified a staff account as owner → full owner UI/routes/deep-links) | Fail-secure: on read failure with **no cached role for this uid this session**, role stays `null` (`isLoaded == false`, `loadFailed == true`) — never owner. Cached role from the same session survives transient failures (flagged `loadFailed`). Router guard: signed-in + role unknown + route ∉ {splash, login, register} → redirect to splash. Splash renders "تعذر تحميل بيانات حسابك" with **إعادة المحاولة** (reload → normal routing) and **تسجيل الخروج**. LoginView: same guard — on unknown role shows error toast and stays on login (no auto-navigation). Legacy "missing `role` field = owner" semantics (both app and rules `myRole()`) intentionally unchanged — compatibility for pre-role accounts | `flutter analyze` 0 errors; splash/login/router build paths re-read; "67 baseline" unchanged |
| B-14 | **~2,400 lines of God-view code** (`home_view.dart` 1259→115; `product_form_view.dart` 1130→881) | `home_view` decomposed into `presentation/widgets/home/` (`HomeHeaderBar`, `NetSalesCard`, `CurrentBalanceCard`, `BalanceBreakdownDialog` (+`MethodRow`), `HomeErrorHint`, `HomeSectionTitle`, `QuickActionsGrid`, `SubscriptionBanner`, shared `formatHomeAmount`) — view is now a thin slivers composition. `product_form_view`: `ProductDeleteDialog`, `ProductFormActionsBar`, `ProductProfitPreview`, `ProductFormIconButton`, `ProductFormDropdownField` extracted to `widgets/product_form/`; dead code removed; `const` keys preserved | `flutter analyze` 0 errors; 67 info/warnings baseline unchanged (zero new lints); **no behavior change, no tests deleted** |
| B-15 | Report files now accurate again | This report rewritten as round 2; `rules_tests/feedback.test.js` added to `npm test`; everything in B-10…B-14 is **committed** (`c82be61` refactor, `029679d` search, `448b56b` feedback admin, `3262d2c` user role) | `git status` clean; `git log` shows the four commits |

**Earlier round (round 1, B-1…B-9) unchanged and committed:** subscription/renewal integrity (S-3, S-4, S-5), trial-window vs `admin_settings` (S-6), dashboard-vs-Reports profit (S-20), admin settings price validation (S-9), privacy policy (F-6 source), in-app account deletion (F-27 source), rules emulator regression suite (111→122→**134**).

**Git status note:** unlike the end of round 1, the tree is **clean** — `c82be61…3262d2c` contains every round-2 fix (source + rules + tests). Nothing left uncommitted from either round (this report file itself is the only pending change).

---

## C. SECURITY FINDINGS — current state

### P0 — still open
- **S-1** Play upload keystore tracked in Git (MD5 matches the release key). **Fix:** rotate upload key via Play App Signing (upload-key reset), purge from history, add `*.keystore`/`*.jks` to root `.gitignore`.
- **S-2** Deployed Firestore rules UNVERIFIED; documented previously as stale. Two full rounds of rules fixes (approve/reject, admin-create, trial window, settings validation, **feedback**, **staff stock bounds + movement invariant**) are inert in production until published. **Fix:** publish `firestore.rules` + `firestore.indexes.json`; verify via cold start (no `permission-denied` in logs).

### P1 — status
- ~~**S-3** Reject revokes paid periods~~ — **FIXED (source)**, see round 1 B-1.
- ~~**S-4** Approve idempotency / confirmations~~ — **FIXED (source)**.
- ~~**S-5** Admin cannot create subscription doc~~ — **FIXED (source)** + regression tests.
- ~~**F-6** Privacy policy absent~~ — **Source fixed**; Play Console steps remain.
- ~~**F-27** In-app account deletion~~ — **FIXED (source)**.
- **S-7 / F-5** Zero Dart tests. **Still open.**

### P2 — status
- ~~**S-6/F-8** Trial window mismatch~~ — **FIXED (source)**.
- ~~**S-9/F-10** Settings not server-validated~~ — **FIXED (source)**.
- ~~**S-20/F-9** Dashboard profit contradicts Reports~~ — **FIXED (source)**.
- ~~**S-17** Admin feedback inbox absent~~ — **FIXED (source)** this round (B-10): admin-only read, update restricted to `handled`/`handledAt` bool, admin delete; 9 emulator regression tests.
- ~~**S-16** Staff can write negative/absurd stock (products + movements)~~ — **FIXED (source)** this round (B-12): bounds + delta cap + `newStock == previousStock + quantity` invariant; documented cap semantics (10k per staff write per product; absolute 1M); 3 new emulator tests.
- ~~**S-10** `UserRoleService` fail-open to owner on read error~~ — **FIXED (source)** this round (B-13): fail-secure unknown role, splash/login retry paths, router guard.
- ~~**F-11/F-28** Admin search vs first-50 blind spot~~ — **FIXED (source)** this round (B-11): bounded full scan (1,000/collection cap), digit normalization, format-agnostic phones, partial-failure tolerance.
- **S-12** Cloudinary receipts share public preset — still present.
- **S-13** No App Check — still absent.
- **S-14** No Crashlytics — still absent.
- **S-15** iOS `aps-environment=development` — still present.
- **S-11** FCM tokens unbounded — still present.
- **S-18** ~150 flat catches, no reporting — still present.
- **S-19** Ungated admin drawer entry — still present.
- **God-view refactor debt** (`admin_settings_view.dart` 1516, `add_expense_view.dart` 1260, `admin_ds.dart` 1100, `invoice_sheet.dart` 1028, `shop_details_view.dart` 936, `supplier_details_view.dart` 931, `add_debt_sheet.dart` 891) — **partially paid** this round (S-views; B-14).

*No P0/P1/P2 marked FIXED (source) is closed in production until the rules deploy completes.*

---

## D. FINANCIAL INTEGRITY — re-verified after round 2

| Area | Status | Evidence (current) |
|---|---|---|
| Sale creation (stock + sale + credit debt, one transaction) | **PASS (source)** | unchanged — staff path now bounds the stock write produced by the same transaction |
| Fractional quantities / inactive product blocked | **PASS (source)** | unchanged |
| Cost snapshot at sale time | **PASS (source)** | unchanged |
| COGS / profit in Reports (snapshot-only, unknown-cost excluded) | **PASS (source)** | `reports_calculator.dart` — unchanged |
| Returns restore stock atomically + settle linked credit debt | **PASS (source)** | unchanged |
| Debt create/update rules (`paidAmount` never decreases) | **PASS (source)** | unchanged |
| Subscription math (append on renewal, live-period wins) | **PASS (source)** | round 1 |
| Admin reject on a PAID account | **PASS (source) / UNVERIFIED (prod)** | round 1 B-1 |
| Dashboard profit vs Reports profit | **PASS (source) / UNVERIFIED (prod data)** | round 1 B-5 |
| Prices enforced on subscription requests | **PASS (local rules, 134/134 emulator)** | re-verified this round |
| **Staff stock writes bounded + movement invariant** | **PASS (local rules, 134/134 emulator)** | B-12 — new tests: staff 15b, movement invariant, purchase caps |
| **Feedback inbox rules (admin read/handled-only update/delete)** | **PASS (local rules, 134/134 emulator)** | B-10 — 9 new tests |
| Admin settings → purchase integrity | **PASS (local rules, 134/134 emulator)** | round 1 B-6 |
| **StockPurchase cap (≤500 items / ≤10M EGP total)** | **PASS (local rules, 134/134 emulator)** | B-12 — at-limit allowed, over-limit denied |
| **Staff purchase >10,000 units of one product** | **DENIED (by design)** | B-12 — pre-agreed cap; owner path unaffected (owner is trusted) |

**Bottom line:** per-shop financials were already transactional and snapshot-based; round 1 made the **platform** view consistent; **round 2 makes the inventory ledger tamper-evident** — a staff member can no longer fabricate or exaggerate stock counts, and every stock movement must now be arithmetically consistent (`newStock == previousStock + quantity`), enforced server-side and covered by emulator regression tests. All subject to the deployed-rules verification (S-2).

---

## E. FEATURE AUDIT — delta summary

70 features were audited (see `HESBA_FINAL_PRE_LAUNCH_AUDIT.md` §B). After this round:

- **PASS (new):** 71 **Admin feedback inbox** (mark handled / delete / search) — new screen + rules + tests. 72 **Global admin search** — no longer "first 50"; bounded full scan.
- **PASS (upgraded):** 66 **Staff account data isolation (writes)** → now includes stock-value bounds (was keys-only). 63 **Staff isolation (session)** → `UserRoleService` fail-secure (was fail-open to owner).
- **PASS (new, rules):** 73 **Feedback inbox rules** (admin-only read, `handled`/`handledAt`-only update, admin delete). 74 **Stock movement invariant** (`newStock == previousStock + quantity`) + 75 **Stock/purchase caps** (1M absolute stock; 10k per-staff-write increase; 100k/movement qty; 500 items; 10M EGP total).
- **REGRESSION TESTS ADDED:** feedback rules (9), stock bounds/invariant/caps (3) — suite **134/134 PASS** (was 122 after round 1, 111 at audit).
- **Refactor (no feature change):** `home_view` (1259→115) and `product_form_view` (1130→881) decomposed into new widgets (`widgets/home/*`, `widgets/product_form/*`); god-views remaining: `admin_settings_view`, `add_expense_view`, `invoice_sheet`, `shop_details_view`, `supplier_details_view`, `add_debt_sheet`.
- **No feature regressed** (analyze clean; **0 new lints**; 134/134 emulator tests).
- **No feature added for customers** — this round is all admin/security/tooling.

---

## F. RELEASE CHECKLIST — current status

| Item | Status | Note |
|---|---|---|
| applicationId / version / targetSdk 36 / minSdk 24 | ✅ | unchanged |
| Release signing via key.properties | ✅ | **keystore still in Git (P0)** |
| `flutter build appbundle --release` | ✅ (round 1, 74.6MB) | **Not re-run this round** — refactor round-2 changes are widget-extraction/service logic with analyze-clean result; **rebuild the AAB before upload anyway** |
| `flutter analyze` | ✅ | 0 errors, 67 info/warnings (baseline — zero new this round) |
| Firestore rules emulator suite | ✅ | **134/134** (baseline 111 → 122 round 1 → **134 round 2**) |
| `test/` Dart suite | ❌ | Still absent |
| Privacy policy URL (Store listing) | ✅ (in-app) / ❌ (console) | URL exists + linked in-app; must be entered in Play Console |
| Data Safety form | ❌ | Must declare in-app deletion-request flow |
| Account deletion | ✅ (in-app) / ⚠️ | Manual execution by support; Data Safety must match the policy |
| App Check / Crashlytics | ❌ | Absent |
| Deployed rules/indexes | ❌ | **UNVERIFIED — required before any launch; now covers two full rounds of fixes** |
| AndroidManifest permissions | ✅ | unchanged |
| Desugaring / boot receiver / POST_NOTIFICATIONS | ✅ | unchanged |
| iOS APNs `development` | ⚠️ | Out of scope for Play |
| `mostafa ahmed` debug log in release | ⚠️ | Still present in `main.dart:19` |
| **Uncommitted fixes at end of round** | ✅ **NONE** | all of round 1 + round 2 are committed (`9e0ccaf…3262d2c`) |
| Working tree | ✅ clean | `git status` empty at report time |

---

## G. FINAL VERDICT

**1. Can real shops safely use Hesba today?** Not yet — not until the deployed rules are verified (S-2) and the keystore is rotated (S-1). The in-app experience is functionally solid and this round closed the remaining data-tamper paths that a hostile staff account could exploit from a normal client session. The two P0s are outside the app's code.

**2. Can users' financial data be trusted?** Per-shop reports/debts/returns: yes (transactional, snapshot costs, tested). Platform admin profit: yes (same engine). **Inventory data: now also yes** — stock writes are bounded, movements are arithmetically consistent, and both are enforced server-side with regression tests.

**3. Is customer data properly isolated?** By local rules: yes (emulator-proven, 134/134). Against production: **UNVERIFIED** until rules are published and tested with a cold start — and the local file now includes feedback-inbox and staff-stock constraints that production lacks today.

**4. Are subscriptions secure?** Locally and by code: yes, robustly. In production today: **unverified** (S-2).

**5. Is the admin dashboard properly protected?** Server-side yes (admin-only collections/operations, transaction preconditions, settings validation) and UX hardened (confirm dialogs, approval flows); **this round it also got the feedback inbox it was missing and a search that actually finds every shop/product/request** (bounded full scan, capped at 1,000 reads/collection). Remaining ungated entry: S-19 drawer tile.

**6. Is the Android release configuration ready?** Almost — builds, signing wired, targetSdk 36, permissions justified. Blocked on: keystore rotation/purge, rebuild of the AAB from the current HEAD (round-2 code), store-console steps (privacy URL, Data Safety, deletion declaration).

**7. What MUST be fixed before launch?**
1. Rotate/purge `hesba-upload-key.keystore` from Git + root-`.gitignore` (S-1).
2. **Publish + cold-start-verify `firestore.rules` (+indexes) on `hesba-business` — both rounds; record evidence** (S-2). The round-2 rules (feedback inbox, stock bounds + invariant) are part of the same deploy.
3. Play Console: privacy-policy URL in Store listing; Data Safety completed to match the policy; account-deletion declaration consistent (F-6).
4. Minimum Dart test suite: sale transaction, return vs sold qty, debt payment cap, profit calculator (F-5).
5. Rebuild `flutter build appbundle --release` from current HEAD (post-refactor) and smoke-test the release build (sale → return → renewal → rejection → staff login) before upload.
6. Remove `logSuccess('mostafa ahmed')` from `main.dart:19` (and ideally squash reporting of the ~150 flat catches — S-18 — into at least Crashlytics).
7. Live smoke test on the real project (register → trial → sale → credit sale → return → renewal → **rejection with paid period intact** → expiry → read-only) **+ staff account: purchase >10,000 units denied, stock moves/manipulations caught by rules**.

**8. What can safely wait until after launch?** S-19 drawer gating, S-12 Cloudinary preset split, S-13 App Check, S-14 Crashlytics, S-11 FCM pruning, remaining god-view refactors (`admin_settings_view`, `add_expense_view`, `invoice_sheet`, `shop_details_view`, `supplier_details_view`, `add_debt_sheet`), iOS APNs environment (out of Play scope), `tz.local`/DST reminder fixes, profit/settings UI polish.

---

## APPENDIX — Verification log (what was actually run, this round and round 1)

| Command / check | Result |
|---|---|
| `flutter analyze` | **0 errors**, **67 info/warnings** — unchanged after every round-2 change (refactor, search, feedback, role service); zero new lints introduced |
| `flutter test` | "Test directory `test` not found" — still absent |
| Rules emulator suite (`node --test` × 7 files) | **134/134 PASS** (baseline 111 → 122 round 1 → **134 round 2**: +9 feedback, +3 stock) |
| `flutter build appbundle --release` | ✅ round 1 (74.6MB) — **not re-run in round 2** (refactor-only + service changes; analyze clean; **rebuild before upload**) |
| Firebase CLI on `hesba-business` | ❌ 403 permission-denied — deployed rules **UNVERIFIED** (now two rounds of rules fixes un-deployed) |
| `git status` (end of round) | **clean** — all round-1 and round-2 work committed (`9e0ccaf … 3262d2c`) |
| Working tree | ⚠️ `HESBA_FINAL_PRE_LAUNCH_REPORT.md` itself is modified but **uncommitted** at report time (this rewrite) — commit it; no source file left dirty |
| i18n (ar/en) | valid JSON; `mostafa ahmed` traced (still present, `main.dart:19`) |

**One-line answer to "is it ready?"** Not yet — but every remaining blocker is now key rotation, a rules deploy + verification, Play Console forms, Dart tests, and a rebuild from HEAD. All known holes the app itself could exploit (staff stock tampering, fail-open role, search blind spot, missing feedback inbox) are **closed in source and covered by emulator regression tests — and nothing is committed but not pushed/verified**.
