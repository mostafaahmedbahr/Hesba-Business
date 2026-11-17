# HESBA Business App — Comprehensive Audit Handoff Report

## Context
- **Project:** HESBA (حسبة) — Flutter business app for shops (Arabic-first, RTL, easy_localization with `ar.json`/`en.json`).
- **Architecture constraint:** Data + Presentation only. **No Domain layer.** State management is **Cubit (flutter_bloc)**. No `setState` in business logic. DI via `get_it` (`sl()`).
- **Backend:** Firebase (Firestore, Auth, FCM) + Cloudinary for images. Firestore rules in `firestore.rules`; indexes in `firestore.indexes.json`.
- **Testing:** `flutter test` (fake_cloud_firestore + mocktail), plus Firebase emulator tests under `rules_tests/` (`@firebase/rules-unit-testing`).

## What was done
Six consecutive audit passes over the codebase:

1. **Profit & Reports correctness**
2. **Cubit / state management**
3. **Financial integrity & duplicate operations**
4. **Authorization & access control**
5. **Firestore performance & scalability**
6. **Network reliability & UX under failure**

---

## Confirmed bugs found and fixed

### Profit / reports
- Sale-created notification showed **gross line profit ignoring invoice discount** (100 instead of 50 on a discounted sale). Fixed by adding `ReportsCalculator.netProfitForSale()` as the single source of truth.
- Admin `profitSummary()` **duplicated the COGS/return-cost formulas** and rounded per document. Replaced with shared `ReportsCalculator.saleCogs/returnCogs` helpers.
- Return validation **overwrote sold quantities** when the same product appeared in two sale lines. Changed to accumulate.

### Cubits
- Missing re-entrancy guards on sale/return/expense/payment/subscription/auth writes → added.
- `AccountsCubit.refresh()` flipped `loading → success` immediately, showing stale debts as fresh → removed.
- `DebtDetailsCubit` stored a failure error the view never rendered → added error UI + retry.
- Stale results overwriting newer ones in global search, suppliers search, admin lists, admin dashboard → generation tokens / in-flight guards.
- Role/subscription caches not keyed by uid → fixed.
- `isClosed` guards on async emits added across critical Cubits.

### Financial integrity
- Concurrent subscription submits could both pass the pending-request pre-check (batch write) → moved into a transaction on the subscription doc.
- Admin could approve/reject an **old, superseded request** → added `lastRequestId` + status preconditions inside approve/reject transactions.
- Recurring-expense generation had a check-then-write race → deterministic document IDs (`templateId_microsecondsSinceEpoch`).

### Authorization (Firestore rules — **deployed to production**)
- Owner could self-activate a subscription with an **arbitrary approved request ID** and **arbitrary `endDate`** → now requires: transition from `pending`, same stored `lastRequestId` (legacy allowance for missing ID), request owned by that user, request approved, and `endDate <= max(stored end, now) + planDays(request.plan)`. Added `planDays()` / `laterTimestamp()` rule helpers.
- Suspended accounts could still write own profile / shops / subscription / mirror → added `isActiveAccount()`.
- Staff could create `subscription_requests` → added `isOwnerUser()`.
- Staff reached unrestricted owner-mode sale/return forms via named routes → router now forces `restricted: sl<UserRoleService>().isStaff`.
- Admin sign-in/out and forced staff logout left a stale role cache → reconciled in `AdminAuthCubit.checkSession()` and clear on logout.

### Performance
- Dashboard read `users/{uid}` **6× per load** → resolved shopId once and passed to the 6 metric methods.
- `profitSummary()` sales + returns scans were sequential → `Future.wait`.
- `countShopDocs` read up to 100 full docs → `.count()` aggregation.
- `ShopResolver.getShopName()` re-read the same user doc → reuse loaded doc.
- `_PendingBell` created a live Firestore listener **inside `build()`** → converted to StatefulWidget with one stream in `initState`.
- Recurring-sync N+1 (one query per occurrence) → one query per template.
- Added `memCacheWidth/Height` to product/admin thumbnails and `cacheWidth/Height` to invoice images.

### Network reliability
- Raw `[cloud_firestore/unavailable]`, `deadline-exceeded`, `Exception: …` text reached users → added `friendlyError(Object)` in `core/utils/error_message.dart` mapping Firebase codes / `SocketException` / `TimeoutException` / Cloudinary codes to short Arabic messages; routed ~15 Cubits/views through it while preserving repo-authored Arabic validation messages.
- **Infinite loading spinners** in sales/returns/expenses list bootstraps when `getShopId()` threw → wrapped in try/catch.
- Cloudinary 90 s timeout covered only `send()` (headers), not `Response.fromStream()` → one deadline wraps the whole closure.
- Cloudinary exceptions embedded raw response bodies and live cloud name/preset → sanitized.
- Silent no-op writes (`if (shopId == null) return;`) reported as success → now throw.
- Recurring-sync failure after a committed expense made users retry → duplicate expense; sync is now best-effort.
- Dashboard listeners used `onError: (_) {}` → log via AppLogger.
- Unguarded activity write in event listener, `saveToken`, `setupFcm` → guarded; added remaining double-submit guards.

---

## Current verified state

| Check | Result |
|---|---|
| `git status` | clean (5 commits) |
| `flutter test` | **187/187 passed** (26 test files) |
| `flutter analyze` | **0 errors**, 66 pre-existing style infos |
| Firestore emulator tests | **142/142 passed** (8 files) |
| `firestore.rules` | **deployed to production** (user-confirmed) |

---

## Remaining risks (open items)

| Priority | Risk | Notes |
|---|---|---|
| **HIGH** | **No repository-level idempotency key** on sale / return / payment writes. Protection exists only at Cubit level plus Firestore transaction guards. A retry after a lost response or a second device can duplicate a financial write. | Needs an optional `requestId` used as document ID, returning the existing record if present. No workflow change desired. |
| MEDIUM | Reports fetch full history (up to 60k docs per collection) and filter by period in memory. | Server-side period filter would break the instant period-switch design. |
| MEDIUM | Admin global search scans only first 1,000 docs per collection. | Could use indexed `searchTokens` or disclose the cap. |
| MEDIUM | No client timeout on Firestore writes. | Intentionally omitted: a timeout does not cancel the write, so a late success + retry could duplicate money. |
| MEDIUM | Cloudinary receipt uploaded before subscription submit is confirmed → orphaned image on failure. | Defer upload to submit time. |
| MEDIUM | `updateProfile` (users + shops) and `setShopSuspended` (subcollection + mirror + log) are non-atomic. | Convert to transactions. |
| LOW | `SubscriptionGate` fails open when the subscription read fails; Firestore rules are the authoritative boundary (now deployed). | Accepted by design. |
| LOW | 66 analyzer infos (`prefer_initializing_formals`, unused imports). | Cosmetic. |

---

## What I want from you (ChatGPT)

1. Review the **HIGH** item first: propose the least invasive idempotency design for Flutter + Firestore that does **not** change the UI workflow, does **not** add a Domain layer, and stays compatible with the current data model (sales/returns/payments use auto-generated doc IDs; `toJson()` writes stable ids). Should the key be passed from Cubit, generated in repo, or derived from a payload hash? Consider retries after lost responses and multi-device double submits.
2. Sanity-check the Firestore rule hardening for the `active` subscription update — is `planDays()` + `laterTimestamp()` + `lastRequestId` binding sufficient, or is there a bypass I missed?
3. Prioritize the remaining MEDIUM items by real-world impact for a small shop app.
4. Flag any correctness regression risk introduced by the listed fixes, especially: the `friendlyError` mapping, the parallel `profitSummary()` scans, and the best-effort recurring sync.

**Please answer in Arabic, concise and practical, with concrete code-level suggestions where relevant.**
