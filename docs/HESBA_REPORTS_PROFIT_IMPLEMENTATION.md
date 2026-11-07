# Hesba — Reports & Profit Implementation Report

**Date:** 2026-11-07
**Scope:** Accurate financial reports (Gross/Net Profit) + removal of the silent 300-record truncation.
**Deployed?** No. No Firestore rules were deployed, no production data/settings changed, no Cloud Functions added.

---

## 1. Initial findings (before any code)

### Data model
| Collection | Date field used for periods | Money fields | Notes |
|---|---|---|---|
| `sales` | `createdAt` | `subtotal`, `discount`, `total` (after discount), `items[].costPrice` | `costPrice` is a **historical snapshot** written at sale time. Legacy sales (before the snapshot feature) have **no `costPrice` field → parsed as 0**. Sales are immutable from clients (`update/delete: isAdmin()` only). |
| `returns` | `createdAt` | `subtotal`, `total` (net refunded amount after discount distribution) | Separate documents with `originalSaleId` linking to the source invoice; quantities are validated at creation (already-returned quantities capped), so **no double-return is possible at write time**. |
| `expenses` | **`date`** (not `createdAt`) | `amount` | Filtered by the business date the user picks. |

### Key findings
- **No cancellation concept exists.** `SaleModel` has no `status`/`cancel` field and the rules make sales immutable from clients — therefore *eligibility = date scope only*; every fetched sale in the period is counted.
- **The 300-cap was real and silent.** `watchSales/watchReturns/watchExpenses` used `limit(500)` and the old Cubit did `sublist(0, 300)` — totals beyond 300 records were dropped **without any indication**.
- The old `balance` (labelled "الرصيد الحالي") was actually `netSales − expenses` — it ignored cost of goods entirely, i.e. it was **not** a profit figure.
- The old date filter used `start − 1s … end + 1day + 1s` tolerance; boundaries were fuzzy.
- Firestore indexes already exist for `(shopId, createdAt DESC)` on `sales`, `returns`, `expenses` (plus `(shopId, date ASC)` on expenses) — cursor pagination needs **no new indexes**.
- Read rules require queries scoped by `shopId` (`isAdmin() || ownerId == me || sameShop(shopId)`) — all report queries are `where('shopId' == …) + orderBy('createdAt' desc)`.
- `SaleItemModel.profit` getter existed but was never used by the reports screen.

## 2. Files inspected

- `lib/features/reports/presentation/cubit/{reports_cubit,reports_state}.dart` and all 7 widgets/views under `presentation/{widgets,views}`
- `lib/features/{sales,returns,expenses}/data/repos/*.dart` + `repos_impl/*.dart` (all 3 pairs, full read)
- `lib/features/{sales,returns,expenses}/data/models/*.dart`
- `lib/core/di/service_locator.dart`, `lib/core/constants/app_constants.dart`
- `firestore.rules` (sales/expenses/returns read+write rules, helpers), `firestore.indexes.json`
- `assets/translations/{ar,en}.json`, `test/` conventions, `rules_tests/` conventions

## 3. Files changed and why

### New files
| File | Why |
|---|---|
| `lib/core/utils/paged_fetch.dart` | Generic cursor pager (`fetchAllPages`) with `isComplete` flag, cursor-advance guard, page cap, optional id-dedup. Single place for the "never silent-partial" contract. |
| `lib/features/reports/data/report_metrics.dart` | Immutable `ReportMetrics` value object (all 7 metrics + cost-coverage counters + `isProfitEstimated`/`netMargin` getters). |
| `lib/features/reports/data/reports_calculator.dart` | Pure, testable financial formulas — **the only place calculations happen** (no duplication in widgets). |
| `test/reports_calculator_test.dart`, `test/reports_paging_test.dart` | Unit tests (see §9). |
| `rules_tests/pagination.test.js` | Emulator tests for pagination completeness, shop isolation and period filtering. |

### Modified files
| File | Why |
|---|---|
| `sales_repo.dart` / `sales_repo_impl.dart` | + `fetchAllSales` (cursor pages of 300) and `watchLatestSale` (limit-1 trigger stream). |
| `returns_repo.dart` / `returns_repo_impl.dart` | + `fetchAllReturns`, `watchLatestReturn`. |
| `expenses_repo.dart` / `expenses_repo_impl.dart` | + `fetchAllExpenses`, `watchLatestExpense`. |
| `reports_state.dart` | Holds **complete** lists (`allSales/allReturns/allExpenses`) + precomputed `ReportMetrics` + `dataComplete`; `endExclusive` boundary; getters now delegate to metrics (no per-build math). |
| `reports_cubit.dart` | Rewritten: full paged fetch (no `sublist`), mask-based concurrent-reload guard (busy + pending bitmask), instant `setPeriod` recompute, limit-1 trigger subscriptions for live updates. |
| `reports_stats.dart` | Grid labels → `.tr()` keys; balance card now shows the full equation (sales − returns − COGS − expenses = **net profit**); new `ReportsProfitCard` (COGS/gross/net + estimated-profit warning) and `ReportsIncompleteBanner`. |
| `reports_header.dart` | Second glass tile: "الرصيد الحالي" → `صافي الربح` (same value, correct name). |
| `reports_view.dart` | Inserts profit card + incomplete banner. |
| `assets/translations/{ar,en}.json` | +13 keys (`reportsTotalSales` … `reportsDataIncompleteBody`); both files verified in sync (649 keys each). |
| `rules_tests/package.json` | test script runs both files sequentially (`--test-concurrency=1` — the two files share one emulator and must not race `clearFirestore`). |

Architecture respected: Data + Presentation only, no Domain layer, no `setState`, Cubit for state, existing DI (`sl<SalesRepo>()` etc.) unchanged, no new dependencies.

## 4. Exact financial formulas implemented

All computed once per (data × period) in `ReportsCalculator.calculate(sales, returns, expenses, start, end)`:

```
inRange(dt)      = !dt.isBefore(start) && dt.isBefore(end)     // [start, end) — end EXCLUSIVE

grossRevenue     = Σ sale.total                       for sales with inRange(createdAt)
returnsTotal     = Σ ret.total                        for returns with inRange(createdAt)
netSales         = grossRevenue − returnsTotal

cogsSold         = Σ (costPrice > 0 ? costPrice × quantity : 0)   over in-range sale items
cogsReturned     = Σ (matched cost > 0 ? cost × qty : 0)          over in-range return items
                   (cost looked up from the ORIGINAL sale via originalSaleId,
                    matched by productId, then by productName)
cogs             = cogsSold − cogsReturned

grossProfit      = netSales − cogs
expensesTotal    = Σ expense.amount                   for expenses with inRange(date)
netProfit        = grossProfit − expensesTotal
```

Rounding: each component is rounded to 2 decimals first, then `netSales/grossProfit/netProfit` are derived from the rounded components — so the equation displayed in the UI matches exactly.

## 5. How returns are handled

- Each `returns` document is read **once** → its `total` is subtracted exactly once (no double counting, verified by test with 2 returns on the same invoice).
- **Full return:** netSales and COGS both go to zero for that invoice (revenue − refund = 0, cost − cost = 0).
- **Partial return:** only the refunded amount is subtracted from revenue, and only the returned quantity's cost is removed from COGS.
- **Return of a previous-period sale:** the refund (and its cost, looked up from the original sale in the *full* sales list) lands in the *current* period — this can make period COGS **negative** (assumption, see §12).
- Orphan returns (missing `originalSaleId` or missing original sale) do **not** invent a cost — their cost line is marked unknown and profit becomes "estimated".
- Cost lookup for a return line: match `productId` first, fall back to `productName` (same convention as `ReturnsRepoImpl` verification).

## 6. How missing legacy costs are handled

- Only `costPrice > 0` counts as a **known** cost. Missing (field absent), zero, or negative values are treated as **unknown**, never as a confirmed zero cost.
- Unknown lines are counted (`saleLinesWithCost/saleLinesTotal`, `returnLinesWithCost/returnLinesTotal`, `unknownCostLines`) and drive:
  - `isProfitEstimated = true` → the profit card shows an amber warning: *"الربح تقديري — تكلفة شرائية مفقودة لـ N صنف… تغطية بيانات التكلفة: X%"*.
  - `costCoverage` = known lines / total lines (visible in the warning).
  - `netMargin` returns `null` when profit is estimated → **no misleading profit %** is displayed.
- Revenue and expense totals are always shown as exact, regardless of cost coverage.
- Historical sales are **never** modified to backfill costs (rules already forbid client updates to sales anyway).

## 7. How the 300-record limitation was removed

- Deleted the `sublist(0, 300)` truncation and the `limit(500)`-stream-as-source-of-truth pattern from the Cubit.
- Reports now fetch **every** document of the shop via `fetchAllPages` cursor pagination (page size 300 = `kReportPageSize`, safety cap `kDefaultMaxPages = 200` → 60 000 docs).
- If the cap or a stuck cursor is hit, `PagedResult.isComplete = false` → `ReportsState.dataComplete = false` → `ReportsIncompleteBanner` is shown and totals are explicitly presented as incomplete — **never silently as final**.
- Page errors propagate (state → failure), so partial data is never emitted as success.
- Live updates now use cheap `limit(1)` trigger streams per collection instead of subscribing to the whole (previously capped) list.

## 8. Pagination / aggregation strategy

1. **Fetch once, filter in memory.** Each collection is fetched completely (cursor pages, `where shopId == + orderBy createdAt desc + startAfterDocument`), then the period is filtered client-side. This keeps instant period switching (today/7/30/all) with zero extra reads.
2. **Cursor safety:** each page must advance the cursor; a repeated cursor stops the loop with `isComplete = false` (no infinite loop).
3. **Dedup:** items are deduplicated by id (`saleId/returnId/expenseId`) so a shifted page boundary can never double-count.
4. **Ordering:** single `orderBy createdAt desc` — stable order across pages; existing composite indexes already cover it (no index deployment needed).
5. **Aggregation independence:** totals are computed from the complete in-memory lists, never from a displayed page (verified in both unit and emulator tests).
6. **UI list pagination** (if ever added) stays separate from this aggregation path — the report widgets only consume `ReportMetrics`.
7. **Consistency:** one `inRange` definition (`[start, endExclusive)`) is used by the calculator and by `ReportsState` (charts/lists), so every metric and chart covers the same window. The old ±1s tolerance was dropped — a negligible boundary change (records within 1 second of a boundary now resolve to the strict rule).

## 9. Test cases and actual results

### `flutter test` — **39/39 passed** (observed run, exit code 0)
- `reports_calculator_test.dart` — **19 tests**: normal sale with known cost; multiple products with different costs; full return; partial return; multiple returns on one invoice (no double count); return of out-of-period sale (negative period COGS); orphan return; missing original sale; cost match by name fallback; expenses deducted; date-range boundaries (inclusive start / exclusive end); expense filtered by `date` not `createdAt`; empty range; missing legacy `costPrice`; explicit `costPrice: 0`; negative cost; mixed complete/incomplete coverage; 2-decimal display-equation identity; no-cancellation-model documentation test.
- `reports_paging_test.dart` — **11 tests**: 350 records over 2 pages (no truncation); totals independent of paging; exact-multiple termination (600 = 2 full pages); cursor sequence `[null, 299, 599]`; overlapping-page dedup; stuck cursor → `isComplete=false` (no infinite loop); `maxPages` cap → incomplete; page error propagates; empty source; empty ids kept; no-`idOf` behavior.
- `subscription_pricing_test.dart` — 9 tests (previous task, still green).

### Emulator tests — **22/22 passed** (observed run, exit code 0)
`firebase emulators:exec --only firestore --project hesba-business "node --test --test-concurrency=1 rules_tests/rules.test.js rules_tests/pagination.test.js"`
- `pagination.test.js` — **11 tests**: 350 sales complete across 2 pages with no duplicates and correct descending order; 320 expenses complete; paged totals == ground-truth totals; page size 100 robustness; u1 reads own shop ✓; u1 cannot read shop2 ✗; unscoped query rejected ✗; u2 cannot read shop1 expenses ✗; signed-out rejected ✗; period filter counts exact (100 sales / 40 expenses in Jan 2026); expense filter uses `date` ≠ `createdAt`.
- `rules.test.js` — 11 pricing-rules tests (previous task, still green).
- Debug logs (`firestore-debug.log`, `firebase-debug.log`) deleted after the run.

## 10. Analyzer results vs baseline

| | Baseline | After this change |
|---|---|---|
| Errors | 0 | **0** |
| Warnings | 1 (`activity_view.dart:380` unused_local_variable) | **1 (same, pre-existing)** |
| Infos | 45 | **45 (same set)** |
| Total | 46 | **46** |

No new analyzer issues introduced (the one new error found during development — `paged_fetch.dart` nullable invocation — was fixed before completion).

## 11. Remaining limitations / manual actions

1. **Live-update trigger granularity:** `watchLatest*` streams watch only the newest document of each collection. Editing/deleting an *older* record may not trigger a refetch — **pull-to-refresh** on the reports screen covers this. (Chosen over subscribing to whole collections, which was the old capped pattern.)
2. **Legacy expenses with empty `shopId`** are excluded from report queries (same as the current primary path — the old code also read with `where shopId ==`). They remain invisible in reports; backfilling them would be a data migration requiring business approval.
3. **Safety cap:** 200 pages × 300 = 60 000 documents per collection. Beyond that, `isComplete=false` and the incomplete banner appears (no silent truncation).
4. **First load cost:** reports now read the full history of 3 collections on open (paged). For very large shops this is more reads than the old capped stream — the tradeoff for correct totals. Instant period switching afterwards costs nothing.
5. **No manual deployment required for this task** (rules untouched by this change; indexes already exist). The previously prepared pricing-rules update still awaits manual Firebase Console publish (separate task).
6. Emulator tests must be run with `--test-concurrency=1` (both files share one emulator).

## 12. Financial assumptions needing business approval

1. **Negative period COGS allowed:** a return recorded this period against a sale from a previous period subtracts that cost from *this* period, which can make COGS (and gross profit) negative for the period. This is period-accurate for returns but differs from a "cost matched only against period sales" reading. *Confirm this is the desired accounting view.*
2. **`costPrice > 0` = known cost:** legacy items with no/zero/negative cost are excluded from COGS and flag the whole profit as *estimated* (revenue/expenses remain exact). The alternative (backfilling historical costs) was explicitly out of scope.
3. **Return cost = original sale's `costPrice`** (matched by productId, then name), not any current product cost — historical snapshot only.
4. **Discount handling:** sale `total` is used (after discount); return `total` is the net refunded amount — no separate re-proration.
5. **No cancellation concept:** all sales in the date range count (the model/rules have no cancellation state). If a cancellation flow is added later, eligibility rules must be revisited.
6. **Period boundaries:** `[start of day, start of next day)` per selected period (today/last-7/last-30/all-from-2020) using local device time — same convention as before, minus the old ±1s tolerance.
7. **"الرصيد" renamed conceptually:** the header figure previously labelled "الرصيد الحالي" is now labelled **صافي الربح** — same position in the UI, correct financial meaning.
