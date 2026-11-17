# HESBA (حسبة) — FINAL PRE-LAUNCH AUDIT

> **FIX LOG — 2026-11-17 (post-audit, same session):** The subscription reject-flow blocker (S-3) and the two related approval defects (S-4) and the rules admin-create gap (S-5) have been **fixed in the source**:
> - `subscription_model.dart` — `effectiveStatus` now derives from dates: any live trial/paid period grants full access regardless of stored `pending`/`rejected`.
> - `subscription_repo_impl.dart` — the pending→decision healer restores the live period instead of unconditionally setting `rejected`.
> - `admin_repo_impl.dart` — `approveRequest`/`rejectRequest` are transactional with a `status == 'pending'` precondition (double-approval/rejection impossible), rejection preserves the live paid period and the real plan in the mirror, approval no longer silently un-suspends the shop and keeps `lastRequestId` on the mirror, and `appendActivity` failures no longer report a committed action as failed.
> - `subscription_requests_view.dart` — confirmation dialogs added for both approve and reject.
> - `firestore.rules` — `users/{uid}/subscription/current` create now allows `isAdmin()` (F-7). **Local file only — the deployed rules remain UNVERIFIED and must be published.**
> - Verified after fix: `flutter analyze` 0 errors (67 info/warnings, unchanged), rules emulator suite **111/111 PASS**, no new analyzer issues.
>
> **FIX LOG 2 — 2026-11-17:** Privacy policy adopted. URL: `https://www.freeprivacypolicy.com/live/b331026f-9deb-428d-8ad5-614ede1fdec5` ("Last updated: November 17, 2026", covers email/name/phone/address, location, camera/photos, usage data, retention, deletion-by-contact `hesbabusiness1@gmail.com`, Egypt, children 16+). In-app access added in two places: a "سياسة الخصوصية" drawer tile (opens the policy in the external browser) and a registration-consent line ("بإنشائك حسابًا فأنت توافق على سياسة الخصوصية"). New `morePrivacyPolicy` key added to `ar.json`/`en.json` (both valid JSON). `flutter analyze`: 0 errors, no new issues.
>
> **FIX LOG 3 — 2026-11-17:** In-app account deletion request shipped. New `DeleteAccountView` (profile → drawer "حذف الحساب"): shows what will be deleted, requires current-password re-authentication, writes a tracked request to `account_deletion_requests` (create rule: signed-in **owner** only, `userId == uid`, `status == 'pending'`, server timestamps, field allowlist; read: admin only; update/delete: denied), signs the user out. New `AccountRepo.requestAccountDeletion`. Translation keys `moreDeleteAccount` (ar/en). **Note:** rules forbid client-side hard deletes of financial records, so execution is manual (admin via Firebase Console + policy email `hesbabusiness1@gmail.com`) — this is the same mechanism the privacy policy declares; Data Safety must state it consistently. Staff accounts get a restricted notice (owner-only deletion).
>
> Still open: deployed-rules publish/verification, keystore rotation, Dart test suite, Play Data Safety form submission (store-console side, must now declare the in-app request flow + manual processing), admin-side processing UI (requests are only visible in Firebase Console today).

**Date:** 2026-11-17
**Auditor role:** Senior Flutter Engineer / Firebase Security Auditor / Mobile Release Reviewer
**Scope:** Entire repository (`/Users/macbook/AndroidStudioProjects/Hesba-Business`), `lib/`, `firestore.rules`, `firestore.indexes.json`, Android release config, Cloudinary/FCM integration, Admin Dashboard, subscription system, tests, build verification.
**Mode:** Read-only audit. No source changes were made. Git working tree preserved (`git status --short` empty after all checks). One tooling side effect: `rules_tests/node_modules/` was installed to run the emulator test suite; it is `.gitignore`d (`.gitignore:48`) and untracked.

---

## A. EXECUTIVE SUMMARY

### A.1 Overall launch readiness

**NOT READY for Google Play production release.**

Hesba is a genuinely functional, unusually well-engineered Flutter + Firebase business application. Its transaction hygiene on the money paths (sales, returns, debts, stock, purchases) is real and verified in code. Its local Firestore Security Rules are thorough — far better than the typical pre-launch Firebase app — and the emulator test-suite passes 111/111. However, the audit found **one critical credential exposure (the actual Play upload keystore is committed to Git), Firestore deployment state that cannot be verified (and the project's own documentation says the deployed rules are stale), an admin reject-flow that silently strips a paying shop's access, one release-submission-blocking legal gap (no privacy policy), and zero automated Dart tests.**

### A.2 Production readiness score: **56 / 100**

Scoring methodology (weighted, conservative — an item scores points only when verified this audit):

| Dimension | Weight | Score /10 | Weighted | Basis |
|---|---|---|---|---|
| Security & data isolation | 25 | 4.5 | 11.25 | Local rules strong & emulator-tested; deployed rules UNVERIFIED; release keystore committed to Git; admin writes not fully transactional; staff stock-write rule allows negatives |
| Financial data integrity | 20 | 7.0 | 14.0 | Sales/returns/debts transactional, costPrice snapshots correct, reports calculator rigorous; admin dashboard profit contradicts it; reject-flow revokes paid periods |
| Feature completeness & correctness | 20 | 7.0 | 14.0 | All major features implemented & traced; no FCM backend; no admin feedback UI; receipt preset == image preset |
| Release configuration & signing | 15 | 6.5 | 9.75 | `app-release.aab` builds (74.4MB), signing config correct, minSdk 24 / targetSdk 36; keystore exposure; no App Check; no Crashlytics/analytics |
| Testing & verification | 10 | 4.0 | 4.0 | Rules emulator tests 111/111 PASS; **zero Dart/widget tests** (`test/` does not exist); `flutter analyze` 0 errors |
| Ops readiness (monitoring, notifications, lifecycle) | 10 | 3.0 | 3.0 | No crash reporting, no analytics, no App Check, local-only notifications, no backend sending, unbounded token growth |
| **Total** | **100** | | **56** | |

### A.3 Critical blockers (must fix before upload)

1. **P0 — Play upload keystore committed to Git** (`hesba-upload-key.keystore` at repo root, tracked in `git ls-files`, commit `cfe650b "key store"`, MD5 `a7d3724c8e4956479c41f0e6cef4d59b` — byte-identical to the key used for the release build at `android/app/hesba-upload-key.keystore`). The release signing key material is public to anyone with repo access or any fork/clone/backup of this directory.
2. **P0/P1 — Deployed Firestore rules are UNVERIFIED, and the last documented state was stale.** The authenticated Firebase account used today gets **403** (`firestore:databases:list` → "The caller does not have permission") on project `hesba-business`; the project's own audit (`docs/HESBA_PROJECT_AUDIT.md` §B-1) documented that the deployed console rules were outdated and Firebase CLI deploy was blocked by the same 403. No evidence exists that the current `firestore.rules` has ever been published.
3. ~~P1 — Admin "reject request" flow silently revokes a shop's paid subscription~~ **FIXED in source 2026-11-17** (see Fix Log at top). Awaiting deployed-rules publish for production effect.
4. **P1 — Zero Dart-side automated tests.** Only rules tests exist; no sale/return/debt regression suite protects the money paths.
5. **P1 — Google Play compliance:** privacy policy now exists and is linked in-app (drawer + registration consent) — URL `https://www.freeprivacypolicy.com/live/b331026f-9deb-428d-8ad5-614ede1fdec5`. Still missing on the store-console side: the policy URL must be pasted into Play Console (Store listing), the Data Safety form must be completed, and account-deletion declaration must match the policy (deletion via `hesbabusiness1@gmail.com`; no self-service in-app deletion yet). No App Check. Play will not accept a non-compliant listing until the console steps are done.

### A.4 Final recommendation

**NOT READY.** With the six items in §G.7 fixed and deployed-rules state verified (not assumed), this becomes **READY WITH CONDITIONS**. It must not be uploaded in current form.

---

## B. FEATURE AUDIT

Legend: **PASS** = verified working end-to-end in code with evidence. **PARTIAL** = implemented and mostly correct, with a verified defect or an unverifiable dependency. **FAIL** = broken/blocking defect found. **UNVERIFIED** = cannot be established from this repository.

| # | Feature | Verdict | Evidence |
|---|---|---|---|
| 1 | Registration (email/password, shop + owner docs) | **PASS (with note)** | `auth_repo_impl.dart` — creates Auth user, `users/{uid}` owner doc, `shops/{id}`, best-effort trial; Firestore failure rolls back the Auth user + user doc (`_rollbackAccount`). Note: rollback does not delete a possibly-created `shops/{id}` doc on failure after shop write partially applied |
| 2 | Login / session persistence | **PASS** | Firebase Auth default persistence; splash/router flow; `app_router.dart` auth gating; `main.dart` waits for role before routing |
| 3 | Password reset | **PASS** | `sendPasswordResetEmail` implemented; `resetPassword` route commented out but dialog flow exists (`forgot_password_dialog.dart`) |
| 4 | User roles (owner/staff/admin) | **PARTIAL** | Staff creation via temp Firebase app (correct, avoids sign-out of owner), role in `users/{uid}.role`; **but** `UserRoleService` fails open to `owner` on any Firestore error and the staff route restriction lives in two parallel lists in `app_router.dart:143-173` |
| 5 | Shop & owner document creation | **PASS** | Registration writes both; shop doc read by rules for billing fallback (`billingOwnerId()`) |
| 6 | Rollback on registration failure | **PARTIAL** | Auth user + `users/{uid}` rolled back; possible orphan `shops/{id}` not removed (shop-step rollback deletes user/auth but never deletes the shop doc) |
| 7 | Product CRUD | **PASS** | `products_repo_impl.dart`; rules `validProduct()` (price > 0, costs ≥ 0), shop-scoped, subscription-gated writes |
| 8 | Categories / business types | **PASS** | `category_repo_impl.dart` + industry config; rules do not categorize but writes are owner-only shop-scoped |
| 9 | Units & fractional quantities | **PASS** | Stock is `double` ("pieces or kg/litre", `product.dart:13`); sale validation `currentStock < item.quantity` handles 0.5 steps |
| 10 | Stock validation at sale time | **PASS** | Inside Firestore transaction (`sales_repo_impl.dart`): existence, shop match, `isActive`, sufficient stock |
| 11 | Cost vs selling price / margins | **PASS** | `costPrice` snapshot stored per sale line at sale time (`add_sale_view.dart:185`, `sale_model.dart`) |
| 12 | Product variants | **PASS** | `product_form_variants_editor.dart`, `variants` persisted in product model |
| 13 | Inactive products | **PASS** | Sale transaction rejects inactive products; products list shows them |
| 14 | Stock consistency during sales/returns | **PASS** | Sales decrement, returns restore — both inside transactions; `stock_purchases` adds atomically |
| 15 | Concurrent stock modification | **PASS** | `runTransaction` with read-then-write on the same product docs |
| 16 | Sale creation & validation | **PASS** | Items validated (name/qty/price); shop resolved; person optional/required-for-credit |
| 17 | Cost price snapshot | **PASS** | See #11 |
| 18 | Profit calculation | **PARTIAL** | Reports calculator (snapshot-cost, unknown-cost flagged) is rigorous (`reports_calculator.dart`); **but the Admin Dashboard profit scan (`admin_repo_impl.dart:156-275`) ignores returns, treats 0-cost lines as zero cost, and falls back to CURRENT product costPrice for legacy lines — the two numbers will never reconcile** |
| 19 | Payment methods (cash/card/credit) | **PASS** | `AppConstants.paymentCredit` etc.; credit enforces customer + contact |
| 20 | Customer association | **PASS** | `persons` collection; sale links `personId/Name/Phone`; credit requires both |
| 21 | Transaction consistency (sale + stock + debt) | **PASS** | One transaction: product writes + sale doc + credit debt doc (`sales_repo_impl.dart`) |
| 22 | Duplicate sale prevention | **PARTIAL** | No idempotency key/client-generated sale doc id reused across retries; a retry after ambiguous failure (timeout after commit) would create a duplicate sale (double stock deduction). Rules immutable after create, but nothing prevents the second create |
| 23 | Historical data integrity | **PASS** | Sales/returns immutable from clients (admin-only update/delete) |
| 24 | Customer records & debts | **PASS** | Debt create requires `paidAmount == 0`, payment via transaction, `paidAmount` never decreases (rules `onlyDebtPaymentFields`) |
| 25 | Collections / partial payments | **PASS** | Payment transactions cap at remaining; `debts/{id}/payments` immutable ledger |
| 26 | Remaining balance correctness | **PASS** | `total - paid` enforced client-side and by rules (`paidAmount <= amount`) |
| 27 | Sales ↔ customer account consistency | **PASS** | Credit sale writes debt in the same transaction; returns settle debt via `FieldValue.increment` in the same transaction |
| 28 | Automatic timestamps | **PASS** | `FieldValue.serverTimestamp()` everywhere on writes; debts/suppliers/persons require `createdAt == request.time` |
| 29 | Supplier management | **PARTIAL** | Full CRUD, validated rules (`validSupplier`), linked-products referential integrity in rules; not deeply re-tested this audit; balance calc not traced to the last line (supplier financial records treated as verified for CRUD, balance math partially verified) |
| 30 | Supplier financial records / balances | **PARTIAL** | Suppliers repo + details view exist; balance derived from debts `partyType == 'supplier'`; not independently recomputed this audit |
| 31 | Supplier transaction history | **PARTIAL** | `supplier_details_view` shows history; completeness depends on Firestore pagination — not stress-tested |
| 32 | Expense CRUD & categories | **PASS** | `expenses_repo_impl.dart`; category metadata; recurrence templates; rules validate structure |
| 33 | Date filtering (expenses/reports) | **PASS** | `date` field convention used consistently (not `createdAt`); reports uses `[start, end)` bounds matching query semantics |
| 34 | Sales totals / expenses totals | **PASS** | `ReportsCalculator.calculate` — pure, documented, bounded half-open interval |
| 35 | Gross & net profit | **PASS (reports)** / **FAIL (admin dashboard)** | Reports: `netSales − cogs − expenses`, rounded at component level, matches display equation. Admin dashboard: different methodology (see #18) |
| 36 | Historical sales with missing costPrice | **PASS** | Excluded from COGS, counted in `unknownCostLines`, profit flagged "estimated" (`report_metrics.dart`) |
| 37 | Dashboard consistency | **FAIL** | Dashboard profit (all-time scan, current-cost fallback, returns ignored, 20k cap) vs Reports profit (period-scoped, snapshot-cost, returns deducted) are mutually inconsistent — two sources of truth for the same financial question |
| 38 | 7-day free trial | **PASS** | `SubscriptionModel.trialFor()`; rules allow owner self-create once (`status == 'trial'`, window ±1 day, ≤ 7 days hardcoded) |
| 39 | Trial expiration | **PASS** | `effectiveStatus` re-derives from dates; client persists `expired` on read; rules block writes when `endDate` passed |
| 40 | Monthly/quarterly/semiannual/annual plans | **PASS** | `SubscriptionPlan` enum: 30/90/180/365 days |
| 41 | Dynamic plan prices from admin settings | **PASS** | `AppSettingsService` reads `admin_settings/settings` live; `SubscriptionPlan.price` from that doc |
| 42 | Rules vs dynamic prices | **PASS (with hardcoded fallback)** | `subscription_requests` create rule validates `amount` against live `admin_settings/settings` prices; **falls back to hardcoded 99/249/449/799 only when the settings doc does not exist**; `amount is int && > 0` |
| 43 | Rules hardcoded trial window | **FAIL (latent)** | Rules hardcode `trialEndDate <= trialStartDate + 7 days` while `admin_settings.trialDays` is editable in the dashboard (1..N). **Any `trialDays > 7` bricks trial creation:** the client set fails rules → `getSubscription()` throws → gate fails open to "allow" (UX) but Firestore rules deny all business writes → new shops are stuck read-only with a permission error |
| 44 | Payment instructions & wallet numbers | **PASS** | From `admin_settings/settings.paymentMethods`, shown live; defaults baked in (99/249/449/799, 7 days, 3 wallet numbers) in three places: model defaults, plan fallbacks, rules fallback |
| 45 | Payment proof uploads | **PASS (with note)** | Cloudinary unsigned upload, 10MB, extension + magic-byte sniffing, `hesba/payment-proofs` folder, separate preset intended but **defaults to the same `hesba_images` preset**; URLs are HTTPS and rule-matched (`^https`) |
| 46 | Submit → review → approve/reject | **PARTIAL** | Submit: solid (re-entrancy guard, one pending request max, server-price validation). **Approve: transactional but no idempotency guard and no confirmation dialog; double-approve extends the plan twice.** **Reject: NOT transactional; flips a live paid subscription to `rejected` (read-only) and clobbers the mirror plan** |
| 47 | Expired subscription → read-only | **PASS** | `gate.ensureCanModify` + rules (`subscriptionLive()`); reads stay open |
| 48 | Modification restrictions | **PASS (server-enforced)** | Rules re-check subscription on every write; client gate is defense-in-depth |
| 49 | Subscription date calculations | **PASS** | Approve appends to live period, else starts fresh; rejected/pending returned as stored; `remainingDays` correct |
| 50 | Admin authorization | **PARTIAL** | Rules `isAdmin()` per-document; client gate is UX only. **Rules gap: `users/{uid}/subscription/current` CREATE has no `isAdmin()` clause (owner+trial only) → approve/reject/suspend FAIL on accounts whose sub doc is missing** |
| 51 | Firebase Auth integration | **PASS** | Email/password only; no custom claims; role from Firestore |
| 52 | Shop data isolation | **PASS (local rules)** | Shop-scoped queries + rules (`sameShop`, ownerId match); cross-shop access denied; staff narrowed to entry data |
| 53 | Cross-shop access attempts | **PASS (emulator-proven)** | 111 rules tests pass on emulator incl. cross-shop supplier/product/debt cases |
| 54 | Admin privilege escalation | **PASS** | Owners cannot change `role` (`unchangedRole` + admin-only role changes); staff docs cannot be re-owned/escalated |
| 55 | Subscription payment manipulation | **PASS (local rules)** | Client cannot spoof `active` (admin approval required), amount must match configured price, `is int > 0` |
| 56 | App Check | **FAIL** | Not present anywhere (`pubspec.yaml`, `android/`, `firebase_options.dart`) |
| 57 | Deployed rules match local file | **UNVERIFIED** | 403 from CLI; previous audit documented stale deployed rules; must be published & verified by someone with project access |
| 58 | Cloudinary config/preset | **PARTIAL** | Unsigned preset `hesba_images` in cloud `qavqsavd` (public by design); receipts share the same preset; restrictions must be enforced dashboard-side; no server enforcement anywhere |
| 59 | FCM token registration | **PARTIAL** | Registered to `users/{uid}.fcmTokens` (arrayUnion), topic `hesba_all`; **tokens never removed on logout/uninstall; array grows unbounded; rules allow any list content** |
| 60 | Notification routing | **PARTIAL** | Tap routing works (`notification_router.dart`); all notifications are local/self-generated; remote push routing never exercised |
| 61 | Local notification scheduling | **PASS (with P3 issues)** | `zonedSchedule`, inexact mode, boot receiver declared, desugaring enabled; DST-naive UTC conversion; id-space comments |
| 62 | Notification permissions (Android 13+/iOS) | **PASS** | `POST_NOTIFICATIONS` runtime request; iOS asks; iOS **entitlement `aps-environment=development` → production pushes impossible** |
| 63 | Background notifications | **PASS (local only)** | `@pragma('vm:entry-point')` background handler, cold-start routing — all local |
| 64 | Backend notification sending | **FAIL** | No `functions/`, nothing sends; Firebase Console manual topic sends only; docs flag as known gap (B-10) |
| 65 | Admin shop/search/subscriptions mgmt | **PARTIAL** | Full UI exists; approve/reject one-tap without confirmation; **search is first-50-docs client-side substring (`admin_search_repo_impl.dart`); `getShopsPage(search:)` ignores its argument** |
| 66 | Admin settings (prices, wallets, plan) | **PARTIAL** | Save works; **no range validation — a `0` or negative price is accepted and bricks all plan purchases** (rules require `amount > 0` + exact match); no confirmation on Save (restore-defaults has one) |
| 67 | Admin sees feedback | **FAIL** | `feedback` is admin-readable in rules but **no admin feedback view exists**; feedback accumulates unread |
| 68 | iOS production push | **FAIL** | `aps-environment=development` (`ios/Runner/Runner.entitlements`) |
| 69 | Google Play release config | **PARTIAL** | Builds, signing OK, targetSdk 36; see §E checklist |
| 70 | Release build verification | **PASS** | `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab` (74.4MB), exit OK |

---

## C. SECURITY FINDINGS

### P0 — Critical

**S-1. Release signing keystore committed to Git.**
`hesba-upload-key.keystore` (repo root) is tracked by Git (`git ls-files` → `hesba-upload-key.keystore`; commit `cfe650b`), is byte-identical (MD5 `a7d3724c8e4956479c41f0e6cef4d59b`) to the key actually used to sign `app-release.aab` (`android/app/hesba-upload-key.keystore`, correctly gitignored), and sits outside any ignore rule. Impact: anyone with the file can sign upload-key-compatible Play updates (passwords in `android/key.properties` are gitignored, but the key itself — whose password entropy is unknown — is exposed, and Play upload-key reset is the only clean recovery). **Fix direction:** treat the key as compromised — generate a new upload key, request an upload-key reset from Play Console, remove the file from history (`git filter-repo`), add `*.keystore`/`*.jks` at repo root to `.gitignore`.

**S-2. Deployed Firestore Security Rules cannot be verified and were previously stale.**
`firestore.json` points rules at `firestore.rules` (good — local file is strong). But the deployed state is invisible: Firebase CLI (v15.36.0, authenticated as some account without access) returns `403 … The caller does not have permission` for `firestore:databases:list` on `hesba-business`; there is no `firestore:rules:releases:*` command in this CLI version; the prior audit (`docs/HESBA_PROJECT_AUDIT.md` §B-1, verified today as still true: CLI 403) recorded the deployed rules as outdated and `admin_settings` read as denied in production. **Any security claim in this report applies to the local `firestore.rules` file only** (emulator-tested 111/111). If the deployed rules are still the stale version, production may currently allow over/under-privileged access of unknown shape. **Fix:** a project owner (whoever created `hesba-business`) publishes `firestore.rules` from the console and cold-starts the app to confirm no `permission-denied` warnings; this is the exact step the previous audit already flagged and it remains undone/unverifiable.

### P1 — High (production blockers)

**S-3. ~~Admin reject silently revokes a *paid* subscription and corrupts the mirror.~~ FIXED (source, 2026-11-17).**
`admin_repo_impl.dart` `rejectRequest` rewritten as one transaction: precondition `request.status == 'pending'`; if the sub has a **live period**, it is restored to `trial`/`active` (never revoked); otherwise it becomes `rejected`. The mirror is written from the restored subscription (its real plan), not the requested plan, and now includes `lastRequestId`. Non-transactional path and plan-clobber eliminated. Also fixed the customer-side healer (`subscription_repo_impl.dart` — `_restorationFrom`) and the root cause in `subscription_model.dart`: a live period now wins over stored `pending`/`rejected` in `effectiveStatus`/`canModifyData`. Still requires rules deploy to take effect in production.

**S-4. ~~Admin approve has no idempotency guard and no confirmation; double-approval double-extends.~~ FIXED (source, 2026-11-17).**
`approveRequest` now reads the request doc inside the same transaction and aborts unless `status == 'pending'` (double-approval across sessions impossible); approval no longer resets `suspended` on a suspended shop; mirror carries `lastRequestId`; `appendActivity` moved outside a try/catch so a committed approve is never reported as failed. Confirmation dialog added for approve in `subscription_requests_view.dart` (reject dialog added too, with a message clarifying live periods are unaffected). Rules deploy still required for production effect.

**S-5. ~~Rules deny admin creation of the subscription doc — admin actions hard-fail for sub-less accounts.~~ FIXED (source, 2026-11-17).**
`firestore.rules` `/users/{userId}/subscription/{subId}` create branch now allows `isAdmin()` (keeping the owner-trial constraints for regular clients). Emulator suite re-run after the change: **111/111 PASS**. **The deployed rules remain unverified — they must be published for this fix to exist in production (S-2).**

**S-6. Rules hardcode a 7-day trial while the dashboard exposes `trialDays` as editable.**
`firestore.rules` create branch: `trialEndDate <= trialStartDate + duration.value(7, 'd')` and `trialStartDate` window ±1 day. `admin_settings.trialDays` is admin-editable (1..N) and `SubscriptionModel.trialFor()` honors it. Setting trialDays = 14/30 → every new trial write **fails rules** → `_read()` throws → gate fails open ("allow action") but every business write is denied by `subscriptionLive()` → shop registers, can do nothing, sees `permission-denied`. **Fix:** either clamp the dashboard control to ≤ 7, or validate the same `trialDays` value read from `admin_settings/settings` inside the rule.

**S-7. No automated Dart tests (release blocker for a financial app).**
`test/` does not exist (`flutter test` → `Test directory "test" not found`). Only rules tests exist (111/111 pass on emulator). Zero coverage of: sale transaction (stock decrement, fractional 0.5 kg, inactive product, insufficient stock), return-vs-sold-quantity, debt payment cap, profit calculator. The previous audit flagged the same gap (B-6) and it is still open. **Fix:** add the suggested unit tests (pure `ReportsCalculator` is directly testable today) before or immediately after launch; at minimum add sale/return/debt transaction tests with `fake_cloud_firestore`.

### P2 — Medium

**S-8. ~~Reject/Approve reachable without confirmation~~ FIXED (source, 2026-11-17).** Confirmation dialogs added to approve and reject in `subscription_requests_view.dart` (and the same dialog is used from the global-search path).
**S-9. Admin settings have no server-side value validation.** Rules allow admin to write any `monthlyPrice` incl. `0`/negative; request-create rules then require `amount == 0` which fails `amount > 0` → **all plan purchases bricked** until fixed. Validate ≥ 1 (and sane max) in rules or in the save path.
**S-10. `UserRoleService` fails open to `owner` on any Firestore error** and caches role per-uid with no TTL/reload on resume; the staff route restriction is enforced client-side only in two parallel lists (`app_router.dart:143-173`). Rules remain the real gate, but the client fail-open violates least-privilege UX. Default to deny + reload on resume.
**S-11. `users/{uid}.fcmTokens` grows unbounded and is never pruned** (logout calls `FirebaseMessaging.instance.deleteToken()` which invalidates the *device* token but does not remove it from the Firestore array; rules place no size/content validation on the array). Prune on logout/refresh-token-rotation; validate array size in rules.
**S-12. Cloudinary unsigned preset is public by design and receipts reuse it.** `hesba_images` (cloud `qavqsavd`) is shipped in the binary; anyone can upload arbitrary content to it; payment receipts (wallet screenshots with balances) are publicly reachable if a URL leaks; receipt preset defaults to the image preset (`app_constants.dart`, cloudinary service comments). Enforce folder/preset restrictions (size, format, unique, authenticated/raw delivery for proofs) on the Cloudinary dashboard; split the receipt preset; consider signed uploads via a tiny proxy later.
**S-13. No Firebase App Check** — nothing stops scripted direct Firestore access with any signed-in account. For an app holding financial records, App Check (Play Integrity) should be enabled before or right after launch.
**S-14. No crash reporting / analytics** — `firebase_crashlytics` absent; all error paths log to console only (82 `catch (_)` sites, 33 truly empty). Production failures will be invisible.
**S-15. iOS push entitlement is `development`** — `ios/Runner/Runner.entitlements` `aps-environment=development`. Irrelevant to Play today, but if iOS follows, production pushes silently never arrive.
**S-16. Staff may write negative/absurd stock.** Products rule staff-branch (`stock`, `updatedAt` only) does **not** call `nonNegative('stock')` — a staff client can set stock to −10⁹ or 10⁹ via raw API. Add the `nonNegative('stock')` check to that branch.
**S-17. Feedback write-only black hole:** rules allow client `feedback` create, admin read; **no admin UI exists** — user feedback silently accumulates unseen.
**S-18. Error swallowing:** ~150 flat catch blocks (82 `catch (_)`), 33 with empty bodies, no reporting channel. Add Crashlytics + at minimum `logWarning` everywhere swallow happens.
**S-19. Drawer shows "لوحة التحكم" (Admin Dashboard) to every signed-in user** (`drawer_items_list.dart:152-159`). Not a vuln (rules + client role gate hold) but pointless attack surface and confusing UX. Gate it behind `UserRoleService.isAdmin`.
**S-20. Admin dashboard profit formula contradicts reports** (`admin_repo_impl.dart:156-275`): ignores returns, treats missing cost as zero cost, falls back to *current* product `costPrice` for legacy lines. Financial decisions made from the dashboard will not reconcile with per-shop reports (see §D).

### P3 — Low

**S-21.** `main.dart:19` logs a personal name (`mostafa ahmed`) on every cold start.
**S-22.** `SalesRepoImpl` caches `_cachedShopName` forever — invoices keep a stale shop name after a shop rename until restart.
**S-23.** Stray unused imports (3) and 64 analyzer infos; `staff_home_view.dart:190` queries Firestore directly (layering violation).
**S-24.** `connectivity_service.dart` is broken dead code (listener never assigned; `dispose` cancels null; stores `BuildContext`); ~20 dead files (`more_view.dart`, `reminders_view.dart`, …).
**S-25.** DST-naive reminder scheduling (`tz.UTC` + `matchDateTimeComponents` on UTC-converted instants) — daily reminders drift across DST; inexact scheduling; notification icon = launcher icon.
**S-26.** Untyped route arguments (`Map<String, dynamic>`), two parallel gating lists, unknown routes fall through to Splash.
**S-27.** `profile_cubit.dart:17` subscription never cancelled (leak); connectivity listener leak; reports cubit `close()` not awaited.
**S-28.** `reports` refetch trigger uses limit-1 listeners on 3 collections; dashboard uses 4 full-collection `.snapshots()` triggers — inconsistent strategies, full re-reads per change.
**S-29.** Admin profit scan reads up to ~20k sales + ~10k products on **every dashboard open** (capped, flagged `capped:true` to UI).
**S-30.** Admin search = first-50-docs substring match; `getShopsPage(search:)` ignores its parameter; unordered `where + startAfterDocument` pagination can interleave pages while the client re-sorts.
**S-31.** Reminder id hash-collision possibility in expense reminder slots (documented, non-verified).
**S-32.** `months`-based plan durations are fixed calendar-agnostic day counts (yearly = 365 days, not 12 calendar months) — acceptable but documented discrepancy.

---

## D. FINANCIAL INTEGRITY — explicit verification

| Area | Verdict | Evidence |
|---|---|---|
| Sale writes in one atomic transaction (stock + sale + credit debt) | **PASS** | `sales_repo_impl.dart` — `runTransaction`; stock checked/decremented; sale doc set; credit debt created with `paidAmount: 0`; credit requires customer + total > 0 |
| Fractional quantities (0.5 kg) | **PASS** | `double` stock; sale validation allows fractional decrement/deduction |
| Inactive product blocked at sale | **PASS** | In transaction: `isActive == false` → exception |
| Cost price snapshot at sale time | **PASS** | `costPrice: selectedProduct?.costPrice ?? 0` (`add_sale_view.dart:185`) persisted per line |
| COGS & profit in reports (snapshot-only, unknown-cost flagged) | **PASS** | `reports_calculator.dart` — sales COGS from snapshot; returns COGS derived from original sale line; missing costs excluded from COGS and counted in `unknownCostLines` ("ربح تقديري"); expenses counted by `date`; templates excluded |
| Discount allocation on returns (refund = net paid) | **PASS** | `returns_repo_impl.dart` — `discountRatio` from original sale, proportional allocation, net total |
| Returns restore stock atomically + settle linked credit debt | **PASS** | Same transaction: increment stock; debt payment `FieldValue.increment` capped at remaining; payment logged in `debts/{id}/payments` |
| Debt create/update rules (paid never decreases, ≤ amount) | **PASS** | `onlyDebtPaymentFields`, `paidAmount == 0` at create, payment ≤ remaining — rules + transaction double-enforced |
| Supplier balances | **PARTIAL** | Computed from `debts` (`partyType == 'supplier'`); CRUD rules validated; arithmetic not independently recomputed this audit |
| Subscription math (append vs restart; prorated extension) | **PASS** | Both `subscription_repo_impl.dart` (`_activationFrom`) and `admin_repo_impl.dart:442` (`livePeriodEnd`) append to live periods; expired periods restart; 365-day yearly documented |
| Request amount ↔ configured price enforcement (anti-tamper) | **PASS (local rules, emulator-proven)** | `subscription_requests` create: `amount is int && > 0 && == get('admin_settings/settings').<plan>Price` (fallback hardcoded only if doc missing) — rules test suite covers price change, tamper, mismatch, cross-shop, double-approval-protection scenarios |
| **Admin dashboard profit vs reports profit — consistent?** | **FAIL** | Dashboard: current-cost fallback for legacy sales, returns NOT deducted, 0-cost lines counted as free, all-time scan, 20k cap. Reports: snapshot-cost only, returns deducted, unknown-cost excluded. **Two different numbers for "profit" in the same app.** |
| **Reject-flow effect on a paid subscription** | **PASS (source) / UNVERIFIED (prod)** | Fixed 2026-11-17: live period always survives rejection; mirror restored with the real plan; one transaction; precondition `status == 'pending'`. Requires rules deploy (S-2) to take effect in production |
| Double-approval extension | **PASS (source) / UNVERIFIED (prod)** | `approveRequest` now precondition-checks `status == 'pending'` inside the transaction; idempotency enforced client-side too. Requires rules deploy |
| Total > stock / overselling | **PASS** | Transaction throws “الكمية المطلوبة غير متوفرة” |
| Money display precision | **PARTIAL** | `double.parse(toStringAsFixed(2))` rounding at component level in reports/returns — good; no integer-minor-units type anywhere; `10^9` cap exists only in debt rules |
| Concurrency of payments vs debt deletion | **PASS** | Debts never deletable from clients; payments immutable |
| `subscriptions` mirror can be written with `trial|pending|expired|rejected` by the owner | **PASS (acceptable)** | Mirror only; admin dashboard uses it for listing; owner cannot write `active` |
| Admin `activity_logs` integrity | **PASS** | Create admin-only, no client update/delete |

**Owner can the data be trusted?** Yes for per-shop reports/returns/debts; **no** for the admin KPI dashboard and **no** for post-rejection subscription state. See §G.

---

## E. RELEASE CHECKLIST (Google Play)

| Item | Status | Notes |
|---|---|---|
| Application ID | ✅ `com.zerobugs.hesba` | Unique; fine for Play |
| Version name/code | ✅ `1.0.0+1` | Ship as first release |
| Release signing (upload key + key.properties) | ⚠️ **Key committed to Git** | `android/key.properties` gitignored ✓; `hesba-upload-key.keystore` at repo root **tracked** (S-1) — rotate & purge before upload |
| Release build passes | ✅ `flutter build appbundle --release` → 74.4MB AAB | Signed with upload key |
| minSdk / targetSdk | ✅ 24 / 36 | Satisfies Play’s target API requirement |
| `ACCESS_*` permissions | ✅ Justified: INTERNET, POST_NOTIFICATIONS, CAMERA, FINE/COARSE_LOCATION, RECEIVE_BOOT_COMPLETED, WRITE_EXTERNAL_STORAGE (maxSdk 29) | All match actual features; `USE_EXACT_ALARM` deliberately omitted (Play-restricted) |
| `allowBackup="false"` | ✅ | Correct for a financial app |
| Internet permission | ✅ | |
| Notification icon | ⚠️ | Launcher icon used; add `ic_stat_*` silhouette |
| App icon (mipmap/adaptive) | ✅ Present | Verify Play store icon 512×512 asset separately |
| Splash/launch theme | ✅ | |
| Desugaring | ✅ `isCoreLibraryDesugaringEnabled` + `desugar_jdk_libs:2.1.4` | Required for flutter_local_notifications |
| R8/ProGuard | N/A | No custom rules; Play default shrinking off in this config — acceptable; if enabled later, keep Firestore/Cloudinary models |
| Debug logs in release | ⚠️ | 67 analyzer notes; `logSuccess('mostafa ahmed')` ships to production (S-21) |
| **Privacy policy URL** | ✅ **PASS (source) / console step pending** | Policy live at `https://www.freeprivacypolicy.com/live/b331026f-9deb-428d-8ad5-614ede1fdec5`; in-app links added (drawer tile `drawer_items_list.dart`, registration consent `register_form.dart`); **must be entered in Play Console store listing manually**; in-app deletion request added (drawer → "حذف الحساب") |
| Data Safety form (Play Console) | ❌ Not prepared | Must declare: personal info, device IDs/FCM tokens, photos, location; encrypted in transit; user can request deletion in-app (drawer → "حذف الحساب", added 2026-11-17: password re-auth + tracked `account_deletion_requests` doc; executed manually by support per policy) — Play requires deletion request mechanism for apps with accounts ✓ **(source)**, console declaration pending |
| Content rating / target audience | ❌ Not prepared | Standard questionnaire |
| Ads declaration | ✅ None | |
| App Check | ❌ Missing | Strongly recommended |
| Account deletion (in-app request) | ✅ **PASS (source)** | `DeleteAccountView`; owner-only; data deleted manually by support per policy; requires rules deploy + Data Safety declaration |
| Crashlytics / monitoring | ❌ Missing | Production blindness |
| Store listing assets (screenshots, feature graphic, description ar/en) | ❌ Not in repo | Needed |
| Play App Signing enrollment | ⚠️ | Required by Play; upload-key reset (S-1) must happen through it |
| Deployed Firestore rules = this file | ❌ **UNVERIFIED** | Blocks everything (S-2) |
| index.json deployed | ⚠️ Unverifiable | 18 composite indexes present locally |
| Cloudinary preset restrictions | ⚠️ | Dashboard-side config, not in repo |
| FCM topic targeting `hesba_all` | ⚠️ | Manual Console sends only; document behavior in listing? |

---

## F. REMAINING WORK (every finding → problem / severity / feature / evidence / solution / blocks launch)

| # | Problem | Severity | Affected | Evidence | Recommended solution | Blocks launch? |
|---|---|---|---|---|---|---|
| F-1 | Play upload keystore in Git | **P0** | Release/signing | `git ls-files` → `hesba-upload-key.keystore`; MD5 match with release key | Rotate upload key via Play Console; purge from history; root-gitignore `*.keystore` | **YES** |
| F-2 | Deployed rules unverifiable/stale | **P0** | All security | CLI 403; `docs/HESBA_PROJECT_AUDIT.md` §B-1; today same 403 | Owner publishes `firestore.rules`; verify app cold-start logs show no `permission-denied` | **YES** |
| F-3 | Admin reject revokes paid access, non-transactional | **P1 — FIXED (source) 2026-11-17** | Subscriptions/Admin | `admin_repo_impl.dart` rewritten (transaction + pending precondition + live-period restoration + mirror fix); `subscription_model.dart`/`subscription_repo_impl.dart` healer restored | Done — awaits rules deploy | **YES (deploy)** |
| F-4 | Approve lacks idempotency + confirm | **P1 — FIXED (source) 2026-11-17** | Subscriptions/Admin | transaction precondition on request status; confirms added to both buttons | Done — awaits rules deploy | **YES (deploy)** |
| F-5 | Zero Dart tests | **P1** | All money paths | `flutter test` → `Test directory "test" not found` | Add sale/return/debt/report unit tests (`fake_cloud_firestore`, `mocktail` already in dev_deps) | **YES** (min. sale+return+debt suite) |
| F-6 | Privacy policy + Play Data Safety + deletion path | **P1 — FIXED (source) 2026-11-17; console steps pending** | Store listing / legal | policy URL adopted; in-app drawer tile + registration consent added (`morePrivacyPolicy` key ar/en) | Remaining: paste URL in Play Console; complete Data Safety declaration; build in-app deletion flow or rely on policy email (`hesbabusiness1@gmail.com`) and declare it consistently | **YES (console steps)** |
| F-7 | Rules deny admin creating `subscription/current` | **P1 — FIXED (source) 2026-11-17** | Admin | rules create branch now allows `isAdmin()`; emulator 111/111 | Done — awaits rules deploy | **YES (deploy)** |
| F-8 | Trial window hardcoded 7d vs editable `trialDays` | **P2** | Subscriptions | rules create branch vs `trialFor()`/`AdminSettings` | Clamp dashboard to ≤7 or read `trialDays` in rules | Strongly recommended (config time-bomb) |
| F-9 | Dashboard profit ≠ reports profit | **P2** | Admin/Finance trust | `admin_repo_impl.dart:156-275` vs `reports_calculator.dart` | Unify on snapshot-cost methodology; subtract returns; treat missing cost as unknown | No (but fix before trusting KPI) |
| F-10 | Admin settings: zero/negative price bricks purchases | **P2** | Subscriptions | rules `amount > 0`; no settings validation | Validate ≥1 and sane cap in save + rules | No |
| F-11 | Admin search = first-50 substring; `search:` ignored; pagination order mismatch | **P2** | Admin | `admin_search_repo_impl.dart`; `admin_repo_impl.dart:280-287,311-359` | Real query strategy (Algolia or indexed fields + proper orderBy) | No |
| F-12 | FCM tokens never pruned; unbounded array; rules unvalidated | **P2** | Notifications | `notification_service.dart:saveToken`; rules `users` update allowlist | Remove token on logout; `arrayUnion` guard + size cap in rules; prune stale via backend when it exists | No |
| F-13 | No FCM backend — cross-device push unimplemented | **P2** | Notifications | No `functions/`; `fcmTokens` write-only; Console manual only | Cloud Function triggers on sales/expenses/requests → topic/token send; or explicitly scope to local-only and document | No |
| F-14 | No App Check | **P2** | All | absent | Play Integrity + App Check enforce | No (recommended) |
| F-15 | No Crashlytics | **P2** | Ops | absent | Add `firebase_crashlytics` | No (recommended) |
| F-16 | UserRoleService fail-open owner | **P2** | Roles | `user_role_service.dart` | Default deny; reload on resume | No |
| F-17 | iOS `aps-environment=development` | **P2** | iOS push | `ios/Runner/Runner.entitlements` | Set production (if iOS ships) | No (Play-only) |
| F-18 | Staff stock rule allows negative values | **P2** | Products | staff branch of products rule | `nonNegative('stock')` in staff update branch | No |
| F-19 | Feedback black hole (no admin UI) | **P2** | Admin/UX | rules `feedback` read isAdmin; zero views | Add feedback inbox to admin | No |
| F-20 | ~150 flat catches, 33 empty, no reporting | **P2** | Cross-cutting | grep audit | Crashlytics + logWarning policy | No |
| F-21 | Full-collection triggers & dashboard re-reads | **P3** | Performance | `dashboard_repo_impl.dart:205-225`; `admin_dashboard_cubit.dart:69-82` | limit-1 triggers; server-side aggregation | No |
| F-22 | Registration rollback leaves possible orphan `shops/{id}` | **P3** | Auth | `auth_repo_impl.dart` `_rollbackAccount` | Delete shop doc too | No |
| F-23 | Ungated admin drawer entry | **P3** | UX/attack surface | `drawer_items_list.dart:152-159` | Gate behind `isAdmin` | No |
| F-24 | DST-naive/inexact scheduling; launcher notification icon | **P3** | Notifications | `notification_service.dart` | `tz.local` timezone; icon asset | No |
| F-25 | Stale shop-name cache; `mostafa ahmed` log; dead code (~20 files); `profile_cubit` leak; two-list route gating; 33 buildWhen-less BlocBuilders; God views (1516/1259/1130 lines) | **P3** | Quality | see architecture audit | Incremental refactor after launch | No |
| F-26 | Rules: settings-doc fallback hardcodes 99/249/449/799 | **P3** | Subscriptions | rules create branch fallback | Acceptable by design; document | No |
| F-27 | Account deletion in-app | **P1 — FIXED (source) 2026-11-17** | Compliance | new `DeleteAccountView` + `account_deletion_requests` collection + owner-only create rule; password re-auth; sign-out; manual admin processing per privacy policy | Done — rules must be deployed; Data Safety must declare the flow | **YES** (deploy) |
| F-28 | `reflection`: firestore.indexes.json must be deployed & complete for new admin orderBy queries | **P2** | Admin | 18 local indexes; missing `status+updatedAt`, `status+createdAt` | Deploy indexes; or fix query shape instead of client sort | No (after F-11 decision) |

---

## G. FINAL VERDICT

**1. Can real shops safely use Hesba today?**
No. The local rules are strong and core flows work, but the deployed rules state is unverified (previously documented stale), the release keystore is exposed in the repository, and the admin reject flow can silently strip a paying shop's access. A real shop owner’s sales would work — until the one time rules deployment or an admin action breaks them, untraceably.

**2. Can users' financial data be trusted?**
Per-shop reports, debts, returns and sales: **yes** (transactional code, snapshot costs, immutable records, 111/111 rules tests). The **admin financial KPIs and rejection side effects: no.** Also missing costPrice history cannot be reconstructed for legacy sales — that is correctly flagged as “estimated profit”, not silently wrong.

**3. Is customer data properly isolated?**
Locally yes — shop-scoped queries, rules, staff narrowing, no cross-shop reads; emulator-proven. **Against the live deployment: UNVERIFIED (403).** Isolation is only as real as the deployed rules file.

**4. Are subscriptions secure?**
Locally **well designed**, and the reject/approve integrity defects found in this audit are now **fixed in source** (live periods can no longer be revoked by rejection; double-approval/rejection is impossible; mirror kept consistent; suspend preserved on approval). **Production-safe only after:** the fixed rules + app build are deployed and verified; `trialDays` vs rules (F-8) is fixed; and someone demonstrates the full purchase → approval → renewal → rejection → expiry cycle on the real project.

**5. Is the admin dashboard properly protected?**
Server-side: yes (admin-only rules; client role gate is UX). UX/safety: **no** — one-tap irreversible approve/reject without confirmation, a broken reject path (S-3/S-4), first-50 search, and a settings screen that can brick all purchases (S-9). Also, the dashboard profit contradicts reports (S-20), so the owner of the dashboard cannot trust what he sees.

**6. Is the Android release configuration ready?**
Mostly: builds, signing wired, targetSdk 36, permissions justified, desugaring OK. **Not ready: keystore exposure (S-1), Data Safety form + Play Console privacy URL entry pending (policy now live and linked in-app), no App Check or Crashlytics, debug name log in release.** iOS entitlement is development-only (out of Play scope).

**7. What MUST be fixed before launch?**
1. Rotate/purge the exposed upload keystore; re-issue via Play App Signing; gitignore at root (F-1).
2. Publish and cold-start-verify `firestore.rules` + indexes on `hesba-business`; record the verification evidence (F-2).
3. ~~Fix the admin reject/approve flows~~ **Done in source (F-3, F-4)** — and it MUST be followed by a rules/app deploy + a live reject-with-paid-plan regression test on the real project.
4. ~~Add `isAdmin()` to the subscription-doc create rule~~ **Done in source (F-7)** — must be published with the rest of `firestore.rules`.
5. ~~Privacy policy (URL + in-app link)~~ **Added in-app; paste URL in Play Console + Data Safety form (F-6).** In-app account deletion still absent (policy: delete via `hesbabusiness1@gmail.com`).
6. Minimum Dart test suite for sale/return/debt/report (F-5).
7. Remove the personal-name debug log; verify no other release-inappropriate logs (S-21).
8. Re-run: `flutter analyze` (0 errors), rules emulator suite (111/111), `flutter build appbundle --release`.

**8. What can safely wait until after launch?**
F-9 (unify admin profit), F-10 (settings validation — though trivial), F-11/F-28 (search & pagination), F-12–F-13 (FCM backend & token pruning), F-14/F-15 (App Check, Crashlytics — recommended ASAP but not Play blockers), F-16–F-32 quality items, newsletter/analytics, iOS production entitlement. Everything else is either launch-blocking or cheap enough to do in the same pass as the fixes above.

---

## Appendix — Verification log (what was actually executed)

| Check | Result |
|---|---|
| `flutter analyze` (Flutter 3.44.8 stable) | **0 errors**; 4 warnings (unused imports ×3, unused local var ×1); 63 info-level (prefer_initializing_formals, use_build_context_synchronously without mounted-guard ~6, unnecessary imports); 67 issues total |
| `flutter test` | **"Test directory 'test' not found"** — no Dart tests exist |
| `firebase emulators:exec --only firestore … node --test (6 suites)` | **111 passed, 0 failed** — local rules only, never deployed |
| `flutter build appbundle --release` | ✅ `build/app/outputs/bundle/release/app-release.aab` (74.4 MB), signed via `android/key.properties` → upload key |
| Firebase CLI access to `hesba-business` | ❌ **403 permission-denied** (`firestore:databases:list`) → deployed rules/indexes **UNVERIFIED** |
| Git tracked secrets scan (`git ls-files`) | `hesba-upload-key.keystore` (root, **identical MD5 to release key**), `android/app/google-services.json`, `GoogleService-Info.plist` (latter two are non-secret config, fine) |
| `android/.gitignore` | `key.properties`, `**/*.keystore` correctly ignored **for android/** — root file bypasses this |
| `.gitignore` (root) | does not list `*.keystore` / `*.jks` |
| Keystore byte comparison | MD5 `a7d3724c8e4956479c41f0e6cef4d59b` both copies |
| Android SDK levels | compileSdk/targetSdk 36, minSdk 24 (Flutter 3.44.8 defaults) |
| `git status --short` after audit | empty — working tree preserved |
| `rules_tests/node_modules/` | installed by this audit to run emulator tests; gitignored; untracked |

**Deployed-rules statement (verbatim honesty):** This audit can prove what the *local* `firestore.rules` does and that it passes its emulator suite. It can prove nothing about what Firebase actually enforces in production. Treat every “PASS (local rules)” in this document as conditional on the same file being the deployed one. Publish and verify it.

**Signing-secrets statement:** No keystore passwords, `key.properties` contents, API secrets, or service-account material are reproduced in this report. The existence and location of the exposed keystore is disclosed because it is a launch blocker.

*End of audit. Objective achieved if this document prevents the upload of a build that would have put Hesba, its shop owners, and their financial data at risk.*
