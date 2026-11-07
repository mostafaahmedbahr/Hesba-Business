# Hesba — Suppliers Management (الموردون) Implementation Report

Feature: a shop-scoped supplier directory with a live list, search, add/edit
form, details screen with linked products, and optional linking from the
product form. Data + Presentation layers only (no Domain layer), Cubit state
management, **no `setState` anywhere in the feature code**.

---

## 1. Scope and design decisions

- Suppliers are **administrative data only**: name, phones, company, address,
  city, notes. **No financials** anywhere in the feature — the list header
  summary shows the **total supplier count only** (no money, no totals).
- Firestore collection `suppliers`, shop-scoped like `products`/`sales`:
  server-side `where('shopId', == myShopId)` + strict local re-check, and
  writes require `shopId == myShopId && ownerId == uid` (creator/admin only).
- Duplicate phone prevention is **normalized client-side** (Latin digits,
  punctuation stripped) and scoped to the same shop — same number in another
  shop is allowed. See §12 for the race-window limitation.
- A supplier **cannot be deleted while products link to it**: the repo blocks
  with `supplierErrLinkedProducts` and **never** silently modifies or deletes
  the linked products.
- Product↔supplier link is optional and legacy-safe: `supplierId` +
  `supplierName` (a display snapshot) on `Product`, both `null` = no supplier.
  Old documents without those keys keep working.
- Renaming a supplier syncs `supplierName` on linked products (chunked
  `WriteBatch`, best-effort — see §12).
- Errors follow the repo convention `Exception('supplierErr*')`; the UI runs
  them through the extended `translateError` (`supplierErr` prefix added in
  `lib/core/utils/error_message.dart`).
- All mutation entry points call `SubscriptionGate.ensureCanModify(context)`
  first (same gating as products/expenses).
- Visual accent: violet gradient (`AppTheme.violetDeep` / `violetSoft`) to
  distinguish the section, reusing existing theme tokens and components.

## 2. Files created — data layer

| File | Purpose |
|---|---|
| `lib/features/suppliers/data/models/supplier_model.dart` | `SupplierModel` (id, ownerId, shopId, name*, phone*, companyName, secondaryPhone, email, address, city, notes, createdAt, updatedAt), `fromJson`/`toJson` (editable fields only)/`toFirestore` (adds id + ownership + `Timestamp`s), `copyWith`, `displayName`, `normalizePhone`. |
| `lib/features/suppliers/data/repos/suppliers_repo.dart` | Abstract repo: `getShopId`, `watchSuppliers`, `getSuppliers`, `getSupplierById`, `addSupplier`, `updateSupplier`, `deleteSupplier`, `searchSuppliers`, `getLinkedProducts`, `watchLinkedProductCounts`. |
| `lib/features/suppliers/data/repos_impl/suppliers_repo_impl.dart` | Firestore implementation: shop-scoped queries, required-field + phone-shape validation (`_assertPhoneShape`: 7–15 digits after normalization), normalized duplicate-phone check (`_assertPhoneIsFree`), server timestamps (`FieldValue.serverTimestamp()`), cross-shop modify/delete blocked, linked-product delete guard, chunked rename sync (`_syncLinkedProductNames`, batches of 400). |

## 3. Files created — presentation layer

| File | Purpose |
|---|---|
| `lib/features/suppliers/presentation/cubit/suppliers_cubit.dart` | List screen: live stream + linked-count stream, local search (name/company/city/normalized phone), debounced remote search (400 ms) for the picker, delete. |
| `lib/features/suppliers/presentation/cubit/supplier_form_cubit.dart` | Add/Edit form: field setters, `validate()` (name → phone, never both at once), `initForEdit`, `submit()` → `SupplierModel?` (null = failure, so the picker can auto-select a newly created supplier), duplicate-submit guard (`isSaving`). |
| `lib/features/suppliers/presentation/cubit/supplier_details_cubit.dart` | Details: `load` (supplier + linked products), `saveNotes`, `delete` with busy-flag re-entrancy guard. |
| `lib/features/suppliers/presentation/states/suppliers_state.dart` | `SuppliersStatus` + list/search/count state, `totalCount`, `filtered`, `pickerResults`. |
| `lib/features/suppliers/presentation/states/supplier_form_state.dart` | Form fields, `SupplierFormStatus`, `isSaving`, error key. |
| `lib/features/suppliers/presentation/states/supplier_details_state.dart` | Supplier + linked products, `busy`, status, error key. |
| `lib/features/suppliers/presentation/views/suppliers_view.dart` | List screen: header (count only), search bar, loading/empty/error/search-empty states, pull-to-refresh, FAB add, cards. |
| `lib/features/suppliers/presentation/views/supplier_form_view.dart` | Reusable Add/Edit form: 8 fields, RTL-aware, validation, loading, Cubit-driven. |
| `lib/features/suppliers/presentation/views/supplier_details_view.dart` | Info + linked products (name/image/price/stock + count) + editable notes + actions (edit, delete-with-confirm, call, WhatsApp, copy phone). |
| `lib/features/suppliers/presentation/widgets/supplier_list_header.dart` | Summary header — total count only. |
| `lib/features/suppliers/presentation/widgets/supplier_list_search.dart` | Search field (clearable). |
| `lib/features/suppliers/presentation/widgets/supplier_list_card.dart` | Card: name/company/phone/city/linked count + call/WhatsApp actions. |
| `lib/features/suppliers/presentation/widgets/supplier_list_placeholders.dart` | Loading skeleton + empty/error/search-empty states. |
| `lib/features/suppliers/presentation/widgets/supplier_delete_dialog.dart` | Delete confirmation (and linked-products message path). |
| `lib/features/suppliers/presentation/widgets/supplier_contact.dart` | `SupplierContact.dialablePhone`: Arabic digits → Latin, Egyptian `0…` → `20…` for `tel:` / `wa.me`. |
| `lib/features/suppliers/presentation/widgets/supplier_field.dart` | Labeled text field used by the form. |
| `lib/features/suppliers/presentation/widgets/supplier_picker_sheet.dart` | Searchable supplier picker sheet for the product form (shop-scoped, clearable, create-new shortcut), including `SupplierPickerSearchField` (clear button via `ValueListenableBuilder` — no `setState`). |

## 4. Files created — tests, rules tests, tooling

| File | Purpose |
|---|---|
| `test/suppliers/supplier_model_test.dart` | Model round-trip, ownership exclusion from `toJson`, legacy/wrong-typed fallbacks, `copyWith` sentinel, `normalizePhone` variants (12 tests). |
| `test/suppliers/suppliers_repo_test.dart` | Add/validate/duplicate-phone/shop-isolation/update/rename-sync/delete-guard/linked products on `fake_cloud_firestore` (21 tests). |
| `test/suppliers/product_integration_test.dart` | Product model supplier fields (legacy-safe, `toJson` always writes both keys, `copyWith` clear/keep) + `ProductsRepoImpl` reference validation (10 tests). |
| `test/suppliers/suppliers_cubit_test.dart` | All 3 cubits: streaming, states, local/remote search + debounce, validation order, double-submit guard, delete guard, busy flags (22 tests). |
| `test/smoke_test.dart` | Infra smoke tests for `fake_cloud_firestore` + `mocktail` (4 tests). |
| `rules_tests/suppliers.test.js` | 22 emulator tests for supplier rules + product↔supplier reference rules (§6). |
| `tool/check_i18n.js` | Verifies every `'key'.tr()` used in `lib/` exists in **both** `ar.json` and `en.json`. |
| `tool/add_supplier_i18n.js` | One-off helper that added the 76 supplier keys to both files. |

## 5. Files modified

| File | Change |
|---|---|
| `pubspec.yaml` / `pubspec.lock` | dev_dependencies only: `fake_cloud_firestore: ^3.1.0`, `mocktail: ^1.0.5`. No new runtime packages. |
| `lib/core/constants/app_constants.dart` | `suppliersCollection = 'suppliers'`. |
| `lib/core/di/service_locator.dart` | `_initSuppliers()` registering repo + 3 cubits. |
| `lib/core/router/app_routes.dart` | `suppliersView` route constant. |
| `lib/core/router/app_router.dart` | `case AppRoutes.suppliersView` + entry in `_requiresAuth`. |
| `lib/core/utils/error_message.dart` | `supplierErr` prefix routed to translation. |
| `lib/features/main/presentation/widgets/drawer_items_list.dart` | Drawer entry (إدارة المتجر). |
| `lib/features/main/presentation/views/more_view.dart` | "الموردون" tile in إدارة المتجر. |
| `lib/core/models/product.dart` | Optional `supplierId` / `supplierName`, `hasSupplier`, `toJson` always writes both keys, `copyWith` sentinel (explicit `null` clears). |
| `lib/features/products/data/repos_impl/products_repo_impl.dart` | `_assertSupplierInShop()` on create + update (same-shop or absent). |
| `lib/features/products/presentation/states/product_form_state.dart` | Supplier fields in state (sentinel-based `copyWith`). |
| `lib/features/products/presentation/cubit/product_form_cubit.dart` | `setSupplier()` / `buildProduct()` wiring. |
| `lib/features/products/presentation/views/product_form_view.dart` | Supplier selector + live name re-resolution `_refreshSupplierSnapshot()` on save. |
| `lib/features/products/presentation/widgets/product_form/product_form_supplier_field.dart` | *(new)* Reusable selector field (searchable, clearable, create-new shortcut without losing form data, auto-select after create). |
| `lib/features/products/presentation/widgets/product_card.dart` | Supplier chip on product cards. |
| `lib/features/admin/presentation/views/product_details_view.dart` | Supplier row in admin product details. |
| `assets/translations/ar.json`, `en.json` | +76 supplier keys each (750 keys per file, in sync). |
| `firestore.rules` | Supplier rules + product supplier-reference validation (§6). |
| `firestore.indexes.json` | 2 composite indexes (§7, **not deployed**). |
| `rules_tests/package.json` | `suppliers.test.js` added to the test script. |

Navigation entry points: drawer + more-view tiles → `AppRoutes.suppliersView`
(auth-gated); add/edit are pushed as form routes from the list; details from a
card tap; the picker is opened from the product form.

## 6. Firestore structure

```
suppliers/{docId}
  id: string            // == docId
  ownerId: string       // creator uid (immutable)
  shopId: string        // owning shop (immutable)
  name: string          // required, non-empty, ≤200
  phone: string         // required, 7..30 dialable chars
  companyName, secondaryPhone, email, address, city, notes: string (optional, bounded)
  createdAt, updatedAt: Timestamp  // FieldValue.serverTimestamp()

products/{docId}  (existing docs extended, optional)
  supplierId: string|null   // → suppliers/{id}, same shop
  supplierName: string|null // display snapshot, synced on rename
```

Queries (all shop-scoped, server-side `where('shopId', == myShopId)` + strict
local re-check):

- list/streams: `suppliers` where shopId, orderBy `createdAt` desc (page limit 500)
- `getSupplierById` / single reads: doc fetch + `shopId`/`ownerId` verification
- search: shop-scoped query then normalized matching locally
- linked products: `products` where `shopId` + `supplierId`
- linked counts: shop-scoped product stream aggregated per `supplierId`

## 7. Firestore security rules changes

Added helpers (`firestore.rules`) — **no unrelated rule was weakened or
removed**:

- `optionalString(d, key, maxLen)` — bounded optional strings.
- `validSupplier(docId)` — full-document check: `id == docId`,
  `ownerId == myUid()`, `shopId == myShopId()`, required `name` (non-empty,
  ≤200, contains a non-whitespace char) and `phone` (7–30 of
  `[0-9٠-٩+()\- ]`), all optional fields bounded.
- `onlySupplierEditableFields()` — `diff().affectedKeys().hasOnly([...editable,
  'updatedAt'])`, so `id`/`ownerId`/`shopId`/`createdAt` can never be changed
  by a client (no cross-shop reassignment).
- `validSupplierRef()` (products) — `supplierId`/`supplierName` **both present
  or both null**; when present, `supplierInShop()` (`exists()` + `get()`)
  proves the supplier exists in the product's shop. Wired into product
  `create` and `update`.
- New `match /suppliers/{docId}` block: read = signed-in + (admin | creator |
  same shop); create = `validSupplier` + `createdAt`/`updatedAt == request.time`
  (server-owned timestamps, no back-dating) + `mayWriteShopData`; update =
  creator only, content fields only, same `shopId`; delete = creator/admin.
  Writes keep the existing live-subscription gate; reads stay open for
  suspended shops (same as products).

**Rules tests: 62/62 pass** (40 pre-existing + 22 new in
`rules_tests/suppliers.test.js`), executed locally only:

```
firebase emulators:exec --only firestore --project hesba-business \
  "node --test --test-concurrency=1 rules_tests/rules.test.js \
   rules_tests/pagination.test.js rules_tests/stock_purchase.test.js \
   rules_tests/suppliers.test.js"
# tests 62 / pass 62 / fail 0
```

New coverage: own-shop CRUD, guest denial, required/shape validation,
ownership/id immutability, back-dating rejection, subscription gating,
cross-shop isolation (read/update/delete/query), coworker read-but-not-write,
admin override, same-shop product link allowed, cross-shop/missing supplier
rejected, paired clear of `supplierId`/`supplierName`, legacy products still
updatable, shop-scoped linked-products query.

## 8. Composite indexes (NOT deployed)

Appended to `firestore.indexes.json` (JSON validated):

1. `suppliers`: `shopId ASC, createdAt DESC` (list/stream order)
2. `products`: `shopId ASC, supplierId ASC` (linked-products query)

**Neither rules nor indexes were deployed** — see §11/§13.

## 9. Product integration

- `Product.supplierId` / `supplierName` are optional; legacy JSON without the
  keys reads as `null`/`null`; `toJson()` always writes both keys (explicit
  `null` unlinks).
- Add/Edit product form: searchable, shop-scoped selector — no free text.
  "Create new supplier" opens the supplier form as a shortcut **without
  losing any entered product data**, auto-selects the new supplier on return,
  and never writes a supplier outside the shop.
- Edit product: view / change / remove the supplier; `null`/`null` clears.
- `ProductsRepoImpl._assertSupplierInShop()` runs before every create/update:
  a missing or foreign-shop supplier throws `supplierErrNotAuthorized` and
  nothing is written. Ownership checks (`_assertOwnership`) still run first.
- The form re-resolves the live supplier name on save
  (`_refreshSupplierSnapshot()`), so a stale picker value can't persist.
- Supplier rename → linked products' `supplierName` updated in chunked
  batches (≤400/batch), best-effort with `logWarning` on partial failure.
- UI extras: supplier chip on `product_card`, supplier row in the admin
  `product_details_view`.

## 10. Localization

- **76 supplier keys** added to **both** `assets/translations/ar.json` and
  `en.json` (750 keys each, in sync), flat keys, natural Egyptian Arabic.
- No hardcoded user-facing strings in the new code; repo errors are
  `supplierErr*` keys rendered via `translateError`.
- Verified: `node tool/check_i18n.js` →
  *"All used keys exist in both ar.json and en.json."* (592 used keys,
  76 supplier, 0 missing, 0 unused).

## 11. Tests and results (all actually executed)

**Flutter — `flutter test`: 69/69 pass**

| File | Tests | Result |
|---|---|---|
| `test/suppliers/supplier_model_test.dart` | 12 | pass |
| `test/suppliers/suppliers_repo_test.dart` | 21 | pass |
| `test/suppliers/product_integration_test.dart` | 10 | pass |
| `test/suppliers/suppliers_cubit_test.dart` | 22 | pass |
| `test/smoke_test.dart` | 4 | pass |

**Firestore rules — 62/62 pass** (command in §7; emulator only, nothing
deployed).

**Formatting** — `dart format` run on every created/changed file (20 new
supplier files + 15 modified + tests); re-run clean (0 changes).

**Analyzer** — `flutter analyze`: **46 issues**, exactly the pre-existing
baseline (all info/warning in unrelated files, **0 errors, 0 warnings from
this feature's code**).

## 12. Known limitations

1. **Duplicate-phone race**: the normalized duplicate check is a client-side
   query before the write — two simultaneous creates with the same number can
   both pass. Closing it needs a transactional/aggregate index strategy (or a
   `phone_{shopId}_{normalized}` lookup doc). Rules validate phone *shape*,
   not uniqueness.
2. **Supplier rename → product `supplierName` sync is best-effort**: chunked
   batches (≤400) are not atomic; a mid-sync failure logs a warning and leaves
   some snapshots stale. The product form re-resolves the live name on save,
   which self-heals on the next product edit.
3. **Composite indexes are required but not deployed**: without deploying
   `firestore.indexes.json`, the ordered supplier list and the linked-products
   query will fail on production Firestore (they pass on the emulator and in
   unit tests, which don't enforce indexes).
4. **Rules `get()`/`exists()` cost**: each product create/update performs one
   `exists()` + one `get()` on `suppliers/{id}` (plus the existing `users/{uid}`
   read). This adds access calls per product write when a supplier is set.
5. **Nothing was deployed or committed**: rules, indexes, and app builds are
   local only; the working tree is uncommitted on `main` per instructions.
6. **Page limit**: list/streams load up to 500 suppliers/products per session
   (same limit as the products feature); shops beyond that need pagination.
7. **`supplier_notes` collection was not created** — notes are a `notes` field
   on the supplier document (simpler, one read).

## 13. Manual deployment steps (for later, by the maintainer)

Nothing below was executed as part of this work.

1. Review `firestore.rules` diff, then deploy rules:
   `firebase deploy --only firestore:rules`
2. Review `firestore.indexes.json` diff, then deploy indexes:
   `firebase deploy --only firestore:indexes`
   (index creation is asynchronous — wait until both new indexes are `ENABLE`
   before exercising the ordered list / linked-products query in production.)
3. `flutter pub get` (dev-only test deps) and ship the app build as usual.
4. Smoke-check on a real device: drawer → الموردون → add/edit/delete a
   supplier, link one from Add Product, rename it and confirm linked product
   cards update, and confirm an old product without supplier fields still
   saves normally.
5. Verify both translation files still parse (`node tool/check_i18n.js`).

## 14. Final verification checklist

- [x] Data + Presentation layers only — **no Domain layer**
- [x] Cubit only — **zero `setState` in the new feature code** (search field
      uses `ValueListenableBuilder`)
- [x] `dart format` applied to all changed files
- [x] `flutter analyze` = 46 (pre-existing baseline, no new issues)
- [x] `flutter test` = 69/69 pass; rules tests = 62/62 pass
- [x] Routes + DI + drawer/more entries wired; `translateError` handles
      `supplierErr*`
- [x] All supplier queries/writes shop-scoped; cross-shop modify/delete
      blocked (unit + rules tests)
- [x] Linked products block deletion with a clear message; products never
      silently modified/deleted
- [x] Both translation files in sync (750 keys each, 76 new)
- [x] Existing product CRUD intact (product tests + analyzer baseline)
- [x] No commits, no pushes, no migrations, no data deletions, **no deploys**
