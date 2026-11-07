# Hesba — Stock Replenishment (زيادة المخزون) Implementation Report

Feature: purchase invoice that increases product stock and updates the
weighted-average purchase cost, with full audit records and historical
sale protection. Data + Presentation layers only (no Domain layer), Cubit
state management, no `setState` in the feature code.

---

## 1. Initial findings and design decisions (before any code)

- `Product.stock` and `Product.costPrice` (`lib/core/models/product.dart`)
  are THE existing fields — the feature updates them in place. **No second
  competing cost field was introduced.**
- There was no pre-existing `stock_purchases` / `stock_movements`
  collection → both are created by this feature.
- Purchases are **inventory acquisition, not an operating expense**: the
  purchase total is never written to `expenses`; reports keep computing
  COGS from the `costPrice` snapshots stored on each sale line.
- Accounting/history rule: **historical sales are never modified** — new
  sales snapshot the (then-current) weighted average through the existing
  sale flow, and returns keep the original sale's historical cost.
- Duplicate protection revision (important): reading a missing document
  inside a transaction is denied by the security rules
  (`resource.data` on a null document), so an in-transaction
  `tx.get(purchaseRef)` duplicate check was replaced with a
  **pre-transaction query** + a **rules backstop** (see §7/§8).

## 2. Files inspected

Product model & repos, sales/returns transactions (`sales_repo_impl.dart`,
returns flow), expenses cubit/form (form conventions), `firestore.rules`,
`firestore.indexes.json`, DI (`service_locator.dart`), routing, both
translation files, existing test conventions (`rules.test.js`,
`pagination.test.dart`, `reports_*` unit tests), theme colors, and the
existing `SaleProductCard` / `ProductListHeader` widget patterns.

## 3. New files — data layer

| File | Purpose |
|---|---|
| `lib/features/purchases/data/models/stock_purchase_item.dart` | One invoice line with before/after snapshots (`previousStock`, `newStock`, `previousCost`, `purchaseUnitCost`, `newAverageCost`, `lineTotal`) + shared `parseFirestoreDate`. |
| `lib/features/purchases/data/models/stock_purchase_model.dart` | `StockPurchase` invoice (supplier/phone/invoice no. optional, `purchaseDate`, `totalAmount`, `items[]`, `createdAt`). |
| `lib/features/purchases/data/models/stock_movement_model.dart` | `StockMovement` audit row (`movementType = 'purchase'`, `quantity`, `previousStock`, `newStock`, `unitCost`, `referenceId`). |
| `lib/features/purchases/data/stock_purchase_calculator.dart` | Pure formulas + validation: `StockPurchaseCalculator.compute/computeNewStock/computeAverageCost/roundMoney`, `PurchaseLineInput`, `ProductSnapshot`, `ProductUpdate`, `ComputedPurchase`. No Firestore/UI dependencies. |
| `lib/features/purchases/data/repos/stock_purchase_repo.dart` | Abstract repo: `generatePurchaseId()`, `addPurchase(...)`. |
| `lib/features/purchases/data/repos_impl/stock_purchase_repo_impl.dart` | Duplicate pre-check query + single atomic `runTransaction` (reads → recalculate from trusted values → writes). |

## 4. New files — presentation layer

| File | Purpose |
|---|---|
| `presentation/cubit/stock_purchase_state.dart` | `StockPurchaseStatus`, `PurchaseLine` (raw qty/cost text + `validationErrorKey` + `lineTotal`), state with `totalAmount`/`itemCount`/`hasSelection`/`isSaving`. |
| `presentation/cubit/stock_purchase_cubit.dart` | Product stream (active products only), add/remove/select/clear line, line text edits, date, `reset`, `submit` (double-tap guard + per-session idempotent purchase id + `AppEvents.productChanged()` after success). |
| `presentation/views/stock_purchase_view.dart` | Full screen: `SubscriptionGate`, invoice details section, product lines, confirm dialog, live-total bottom save bar, loading/empty product states. |
| `presentation/widgets/purchase_header.dart` | Gradient header with live invoice total, item count, purchase date. |
| `presentation/widgets/purchase_line_card.dart` | Per-line card: product `Autocomplete`, current stock/cost chips, qty + unit-cost fields, inline errors, line total. |
| `presentation/widgets/purchase_confirm_dialog.dart` | Pre-save review dialog (items, total, date). |

No `setState` anywhere in the feature: view owns only top-level
`TextEditingController`s (supplier/phone/invoice/notes) and each line card
owns its two field controllers; every value change goes through the Cubit.

## 5. Modified files

| File | Change |
|---|---|
| `lib/core/constants/app_constants.dart` | `stockPurchasesCollection = 'stock_purchases'`, `stockMovementsCollection = 'stock_movements'`. |
| `lib/core/router/app_routes.dart` + `app_router.dart` | Route `/stockPurchaseView`, import, `case`, added to `_requiresAuth`. |
| `lib/core/di/service_locator.dart` | `_initPurchases()` registers `StockPurchaseRepo` → `StockPurchaseRepoImpl`. |
| `lib/core/utils/error_message.dart` | `translateError` now translates the `purchaseErr*` key prefix (raw Arabic repo exceptions still pass through untouched). |
| `lib/features/products/.../product_list_header.dart` + `products_view.dart` | Restock button in the products header (`Icons.add_shopping_cart_rounded`, tooltip «زيادة المخزون») → `onRestock`. |
| `lib/features/main/.../more_view.dart` | «زيادة المخزون» item under «إدارة المتجر». |
| `assets/translations/ar.json` + `en.json` | 26 new `purchase*` keys, added to **both** files in sync. |
| `firestore.rules` | New `stock_purchases` + `stock_movements` matches (§9). **Local file only — NOT deployed.** |
| `firestore.indexes.json` | Two composite indexes (§9). **Local file only — NOT deployed.** |
| `rules_tests/package.json` | Test script now also runs `stock_purchase.test.js`. |

## 6. Exact formulas implemented

```
roundMoney(v)          = (v × 100).round() / 100        // 2-decimal money rounding

newStock               = currentStock + receivedQty

if currentStock == 0:  newAverageCost = roundMoney(purchaseUnitCost)
else:                  newAverageCost =
      roundMoney(((currentStock × currentCost) + (receivedQty × purchaseUnitCost))
                 / (currentStock + receivedQty))        // weighted average

lineTotal              = roundMoney(receivedQty × purchaseUnitCost)
totalAmount            = roundMoney(Σ lineTotal)
```

Validated inside the calculator (any failure aborts the whole purchase):

- `receivedQty` finite and `> 0` (fractions allowed — kg/litre shops);
- `purchaseUnitCost` finite and `≥ 0`; `currentStock`/`currentCost` finite
  and `≥ 0`; non-finite (NaN/Infinity/overflow) values rejected;
- no division by zero (zero-stock branch), product must exist, must belong
  to the same shop, no duplicate product inside one invoice;
- `shopId` required; invoice needs ≥ 1 line.

Client-side pre-validation in the Cubit uses `purchaseErr*` translation
keys; repo/calculator throw raw Arabic `Exception` messages that pass
through `translateError` untouched (same pattern as sales).

## 7. Historical sale protection (verified)

The purchase transaction writes **only** to:

1. `products/{id}` → `stock`, `costPrice` (the same existing field, now the
   new weighted average), `updatedAt`;
2. `stock_purchases/{purchaseId}` (new doc);
3. `stock_movements/{movementId}` (new docs).

It never touches `sales` or `returns`, so:

- **historical sales keep their `costPrice` snapshots exactly** — old
  profit/COGS numbers never change;
- a **new** sale snapshots the updated weighted average through the
  existing sale flow (unchanged code path);
- a **return** keeps the original sale's historical cost (unchanged code
  path).

Emulator proof (`stock_purchase.test.js`):

- `sales/s1` (cost 7) and `returns/r1` (cost 7) are deep-equal before and
  after purchases;
- after a restock the average becomes 15 → new sale `s2` stores 15;
  a further restock moves the average to 18.33, while `s1` still shows 7
  and `s2` still shows 15;
- COGS inputs stay exact: `s1` → 2×7 = 14, `s2` → 2×15 = 30.

## 8. Records written + accounting + duplicate protection

**`stock_purchases`** (one doc per invoice): `purchaseId`, `ownerId`,
`shopId`, optional `supplierName`/`supplierPhone`/`invoiceNumber`,
`purchaseDate`, `totalAmount` (recomputed inside the transaction from
trusted values), `notes`, `items[]` with before/after snapshots, `createdAt`.

**`stock_movements`** (one doc per invoice line): `movementType:
'purchase'`, `quantity > 0`, `previousStock`, `newStock`, `unitCost`,
`referenceId = purchaseId`, `shopId`, `ownerId`, `createdAt`.

**Atomicity** — one `runTransaction`: all product reads happen first, the
calculator recomputes everything from those trusted snapshots (the UI's
numbers are never trusted), then all writes commit together. Any failure
(unknown product, foreign-shop product, invalid value, rules denial)
aborts the whole transaction — **no partial updates**.

**Accounting** — the purchase total is never written to `expenses`
(emulator test asserts the `expenses` collection stays empty after a
purchase); reports keep deriving COGS from sale-line `costPrice`.

**Duplicate protection — four layers:**

1. **Pre-transaction query** `where(purchaseId ==) && where(shopId ==)`
   → friendly error «الفاتورة محفوظة مسبقاً — لم يتم تكرارها» before any
   write (query is shop-scoped so the read rules allow it);
2. **Rules backstop** — `set` on an existing `stock_purchases` doc is an
   *update*, which is admin-only → a racing client overwrite is rejected
   by the rules (emulator-tested);
3. **Cubit `isSaving` guard** — double-taps cannot start a second save;
4. **Idempotent purchase id** — `generatePurchaseId()` runs once per
   submit session (`_purchaseId ??= …`), reused across retries of the same
   invoice and cleared only after success.

## 9. Security rules + indexes (LOCAL FILES ONLY — NOT DEPLOYED)

Added to `firestore.rules` (no existing rule was weakened; admin paths
preserved):

```
match /stock_purchases/{docId} {
  allow read: if signedIn() && (isAdmin() || resource.data.ownerId == myUid()
    || sameShop(resource.data.shopId));
  allow create: if signedIn()
    && request.resource.data.ownerId == myUid()
    && request.resource.data.items is list
    && request.resource.data.items.size() > 0
    && nonNegative('totalAmount')
    && mayWriteShopData(request.resource.data.shopId);
  allow update, delete: if isAdmin();      // immutable audit trail
}

match /stock_movements/{docId} {
  allow read: if signedIn() && (isAdmin() || resource.data.ownerId == myUid()
    || sameShop(resource.data.shopId));
  allow create: if signedIn()
    && request.resource.data.ownerId == myUid()
    && request.resource.data.movementType == 'purchase'
    && request.resource.data.quantity is number
    && request.resource.data.quantity > 0
    && nonNegative('previousStock')
    && nonNegative('newStock')
    && mayWriteShopData(request.resource.data.shopId);
  allow update, delete: if isAdmin();
}
```

`mayWriteShopData` keeps the existing server-side subscription gate
(own shop + live trial/active subscription, admins exempt).

Added to `firestore.indexes.json` (both `(shopId ASC, createdAt DESC)`):

- `stock_purchases`
- `stock_movements`

### ⚠️ Manual deployment instructions (I did NOT deploy anything)

The rules/indexes files are updated **locally only**. Deploy them yourself
when you are ready (they must be live **before** the app build that uses
this feature ships, otherwise invoice creation is denied by default-deny):

**Option A — Firebase Console (no CLI):**
1. Firestore → **Rules** → paste the contents of `firestore.rules` → **Publish**.
2. Firestore → **Indexes** → **Composite** → create the two indexes above
   (`stock_purchases` and `stock_movements`, fields `shopId ASC` +
   `createdAt DESC`) → **Create**.

**Option B — Firebase CLI (from the project root):**
```
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

Both commands publish to the project in `.firebaserc`
(`hesba-business`) — run them deliberately, review the diff first.

## 10. Test cases and actual results

### `flutter test` — **71/71 passed** (observed run, exit code 0)

- 39 pre-existing tests (regression),
- 32 new in `test/stock_purchase_calculator_test.dart`: newStock
  (existing/fractional/overflow), weighted average (zero stock, unequal
  weights, fractions, zero current cost, no division by zero, 2dp
  rounding), rounding (12.346 → 12.35), full invoice processing
  (single/multi product, totals, snapshots), and every rejection path
  (empty invoice, no product, duplicate product, foreign-shop product,
  missing product, empty shopId, qty ≤ 0, negative cost, corrupt product
  data, non-finite line total, no partial processing).

### Emulator tests — **40/40 passed** (observed run, exit code 0)

```
firebase emulators:exec --only firestore --project hesba-business ^
  "node --test --test-concurrency=1 rules_tests/rules.test.js rules_tests/pagination.test.js rules_tests/stock_purchase.test.js"
```

- 18 new in `rules_tests/stock_purchase.test.js`:
  - **9 rules tests** — owner create/read OK; cross-shop create/read/
    tamper denied; guests denied; empty `items` and negative `totalAmount`
    rejected; no-subscription writes denied; purchases immutable for
    clients but admin-fixable; movement shape validation (type, qty > 0,
    non-negative stocks, cross-shop/guest denied); movement immutability;
    list queries strictly scoped by `shopId` (unconstrained listing denied
    for regular users, allowed for admin);
  - **9 transaction tests** (JS mirror of `StockPurchaseRepoImpl`: pre-check
    query → reads-before-writes → same calculator → atomic writes):
    success updates stock + weighted average + invoice snapshots + linked
    movements; missing/foreign product ⇒ **zero partial writes**;
    duplicate `purchaseId` never doubles stock (friendly message, one
    invoice, movements not duplicated); client overwrite of an existing
    invoice rejected by rules; historical sale/return byte-identical;
    new sale snapshots the updated average and later purchases never
    rewrite it; `expenses` stays empty; no-subscription transaction fails
    with no partial writes; zero-stock uses the purchase cost and
    fractional lines round to 2 decimals;
  - 22 regression tests (`rules.test.js` + `pagination.test.js`) still pass.

## 11. Analyzer vs baseline, limitations and manual actions

**`flutter analyze` = exactly the baseline: 46 issues**
(0 errors, 1 warning `activity_view.dart:380`, 45 infos — the pre-existing
warning is untouched).

Remaining limitations / manual actions:

1. **Rules and indexes are NOT deployed** — follow §9 before releasing.
2. **Nothing was committed or pushed** — all feature changes remain
   uncommitted in the working tree (12 modified files + `lib/features/purchases/`
   + 2 new test files), per instructions.
3. There is **no purchase-history list screen** yet — invoices and movements
   are recorded for audit only (the requirement was the capture flow; a
   history view can be added later on top of the `stock_purchases` query).
4. The `if (!snap.exists) continue` branch inside the transaction is
   unreachable in production (the rules deny reads of missing documents, so
   the whole transaction fails atomically instead) — kept as a harmless
   defensive branch mirroring the calculator's "missing product" error.
5. Duplicate detection has a theoretical check→write race; it is closed by
   the rules backstop (layer 2 in §8), not by the query alone.
