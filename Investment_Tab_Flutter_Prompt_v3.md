# Flutter Investment Tab — Complete Feature Prompt (v3)

> **Reference UI screenshots provided:** Image 1 = Expense main screen. Image 2 = Expense History list (date-grouped collapsible). Image 3 = Expense Settings (lower half: Download Sample Excel, Import Excel, Categories, Banks, Delete Data). Image 4 = Expense Settings (upper half: Export card with Time range + Format dropdowns + Download button, Import card). All Investment UI must pixel-match these screenshots in layout, card style, typography, colors, spacing, border radius, and button shapes. Do not invent any new visual style.

---

## Role & Scope

You are a senior Flutter developer on an existing personal finance app. Current tab order: **Credentials → Expense → Task → Settings**. Add a new **Investment** tab between Task and Settings:

**Final order: Credentials (0) → Expense (1) → Task (2) → Investment (3) → Settings (4)**

Investment is a **structural and visual clone of the Expense tab** — same screens, same widgets, same navigation patterns — but for a different data domain. Wherever this prompt says "same as Expense", replicate that widget exactly. Zero new visual patterns.

### Must NOT change
- Global Settings tab (one additive change only — see Section 14)
- Credentials, Expense, Task tabs
- App theme, color scheme, font family, or nav structure

---

## 1. Bottom Navigation

- Tab icon: `Icons.show_chart` (trending/investment icon — match style of existing nav icons)
- Tab label: `Investment`
- Active state: same teal pill highlight as seen on Expense tab in Image 1

---

## 2. Investment Main Screen

### App Bar
Exact copy of Expense app bar (Image 1 top):
- Large bold title `Investment` (same size/weight as `Expense` in Image 1)
- Right icons: analytics icon (the `+∕∼` trending icon from Image 1) + gear icon — same size, same spacing, same color

### Top Controls Row
Copy the row below the app bar in Image 1 exactly:
- **Left**: `Filter by category` dropdown (dark rounded pill, same style as "Axis" bank dropdown in Image 1). Options: All categories + each investment category.
- **Right**: `+ Add Investment` button (teal/mint filled rounded pill, same style as `+ Add Expense` in Image 1)

### Summary Card
Exact copy of the Summary card from Image 1:
- Outer card: dark rounded container, same border radius, same shadow
- Header row: bold `Summary` on left, teal `All transactions` link text on right — clicking opens filter
- First row (full width): single highlighted card with blue outline border (`Total Net` equivalent → label: `Total Invested`, value: computed sum of all buyAmt in selected filter range)
- Second row (2 columns): `Total Sell Value` | `Total P/L` — same dark card style, same font sizes as `Total Credit` / `Total Debit` in Image 1
- Third row (2 columns): `Total P/L %` | `Open Positions` (count of entries with no sell) — same style as `Total Lent` / `Total Borrowed` in Image 1
- Number formatting: Indian locale, no currency symbol (1,00,000 / 10.50 L / 1.00 Cr). Positive P/L = green, negative P/L = red.

> ⚠️ CRITICAL: All values computed live. Never read P/L, Tax, PAT, Days, P/L% from stored DB or imported files. See Section 6.

### Search + Date Picker Row
Copy the row below Summary in Image 1 exactly:
- Left: dark rounded search bar `Search investments` (same icon, same placeholder style)
- Right: circular dark icon button with calendar icon (same teal-border circle style as Image 1)
- Tapping the calendar opens the date filter — options: **All | Month | Year | 3 Years | Custom** — same picker UI as Expense

### Investment History List
Below the search row, a section header row: bold `History` on left, teal `All Entries` on right — same as Image 2.

**List structure — NOT date-grouped. Symbol/Name grouped instead:**

Each list item is a collapsed/expandable card like Image 2 date-group tiles, but keyed by **Symbol Name** not date:

```
┌─────────────────────────────────────────────────┐
│  RELIANCE INDUSTRIES           ▾                │
│  3 transactions          +12,450  (green)       │
│  Status badge: [Partial] or [Sold] or [Open]    │
└─────────────────────────────────────────────────┘
```

- **Title**: Symbol / Name (bold, same weight as date text in Image 2)
- **Subtitle**: `X transactions` (same grey style as "1 transaction" in Image 2)
- **Trailing top**: Total P/L of all buy-sell pairs for this symbol (green/positive or red/negative, same color style as Image 2 amounts)
- **Trailing bottom** — Status badge (pill chip):
  - `Open` — grey badge — all qty unsold
  - `Partial` — orange/amber badge — some qty sold, some still open
  - `Sold` — green badge — all qty sold (100% of total bought qty has a matching sell)
- Tap the row → **Entry Detail Screen** (full page push, do not expand inline)
- The chevron `▾` icon on the right matches Image 2 style

**Status badge computation:**
```
totalBoughtQty = sum of qty across all buy entries for this symbol
totalSoldQty   = sum of sellQty across all sell entries for this symbol
if totalSoldQty == 0           → Open
if totalSoldQty < totalBoughtQty → Partial
if totalSoldQty >= totalBoughtQty → Sold
```

**Sorting**: Alphabetically A→Z by Symbol name. No date grouping.

**Deduplication / HashSet behaviour:**
When adding a new buy entry for a Symbol that already exists in the list, do NOT create a new top-level list item. Instead, link the new buy entry to the existing Symbol group. The list always shows one row per unique Symbol name regardless of how many buy entries exist for it. Internally this is a Map<String, List<InvestmentEntry>> keyed by Symbol.

**FAB**: same teal circular FAB as Expense — opens Add Investment (Buy Entry) screen.

---

## 3. Entry Detail Screen

Opened by tapping any Symbol row in the list. Full-page push navigation (same as tapping an expense detail).

### App Bar
- Back arrow + title = Symbol name
- Right: three-dot menu or inline text buttons

### Content

**Section: Buy Information**
Display as label-value rows (same style as credential detail fields):
- Symbol / Name
- Category
- Total Quantity Bought
- First Buy Date
- Average Buy Rate
- Total Buy Amount

**Section: Sell History** (shown only if any sell entries exist)
List of all sell transactions in **descending order (latest sell first)**:
Each sell entry shows:
- Sell Date
- Sell Qty
- Sell Rate
- Sell Amount
- Days Held (computed from linked buy date)
- P/L for this sell (green/red)
- Tax (if broker linked)
- PAT

If no sell entries exist: show a card with text "No sell entries yet. Position is Open."

**Section: Summary** (if any sells exist)
- Total Sold Qty
- Total Sell Value
- Total P/L
- Total P/L %
- Total Tax
- Total PAT

**Bottom Action Buttons** — three text buttons in a row at the bottom of the screen, same style as described:

```
[ View ]     [ Edit ]     [ Delete ]
```

- **View**: scrolls to / expands the Sell History section (or if already visible, does nothing — it is always visible on this screen). The "View" here means the user can see the full detail — this button is already the detail screen itself. Alternatively: "View" opens a dedicated full-page Sell History list screen sorted latest-first.
- **Edit**: opens Edit Buy Entry screen (full page, pre-filled form)
- **Delete**: confirm dialog → deletes the buy entry AND all linked sell entries for this symbol. Show warning: "This will delete the buy entry and X linked sell records."

**Add Sell Entry button** (separate from the three buttons above, only shown if position is Open or Partial):
- Teal filled button `+ Add Sell Entry` — opens Add Sell Entry screen (full page)

---

## 4. Add / Edit Screens (All Full-Page — Never Bottom Sheet)

All forms are full-page push navigation screens. Same form layout, same input field style, same spacing, same validation, same save button placement as the Expense add/edit screen.

### 4A. Add Buy Entry Screen
Title: `Add Investment`

Fields in order:
1. **Category** — dropdown (same style as Expense category dropdown)
2. **Symbol / Name** — text field
3. **Quantity** — number field
4. **Buy Date** — date picker (reuse exact Expense date picker widget)
5. **Buy Rate** — decimal field
6. **Buy Amount** — auto-calculated (Qty × Buy Rate), displayed read-only; small lock/edit icon to override manually
7. **Broker** — optional dropdown (from broker profiles; preselects app default)
8. **Notes** — optional multiline text field

Save button: same teal filled rounded button as Expense.

> On save, if an entry with the same Symbol already exists, add this buy record to the existing Symbol group (HashSet/Map behavior — do not create duplicate symbol in the main list).

### 4B. Edit Buy Entry Screen
Title: `Edit Investment`
Identical to Add Buy Entry, pre-filled. Derived fields (P/L, Tax, PAT) NOT shown here — only on detail screen.

### 4C. Add Sell Entry Screen
Title: `Add Sell Entry`
Full-page form. Fields:
1. **Sell Date** — date picker (same Expense widget)
2. **Sell Rate** — decimal field
3. **Sell Quantity** — number field (default = remaining unsold qty, editable for partial)
4. **Sell Amount** — auto-calculated (Sell Qty × Sell Rate), overridable

Below fields — live preview card (same style as summary cards, dark rounded container):
```
Estimated P/L     :  +X,XX,XXX
Estimated P/L %   :  +12.5%
Estimated Tax     :  X,XXX
Estimated PAT     :  +X,XX,XXX
```
Updates in real-time as user types. Not stored.

Save button: same style as Expense.

---

## 5. Investment Categories (CRUD)

### Default Pre-Seeded Categories
```
1. Equity / Stocks     icon: Icons.trending_up      color: blue
2. IPO (Allocation)    icon: Icons.new_releases      color: orange
3. Mutual Fund         icon: Icons.account_balance   color: purple
4. Gold                icon: Icons.star              color: amber
5. Bond / Debt         icon: Icons.receipt_long      color: teal
6. Fixed Deposit       icon: Icons.savings           color: green
```

All defaults are fully editable and deletable — no lock on defaults (same as Expense).

Deleting a category with linked entries → dialog: "X entries use this category. Reassign to another category first." with a reassign dropdown.

### Data Model
```dart
class InvestmentCategory {
  String id;
  String name;
  String icon;
  Color color;
  DateTime createdAt;
}
```

---

## 6. Calculation Rules — Always Computed, Never Stored

```dart
// Raw stored fields only — never store computed values
class InvestmentEntry {
  String id;
  String categoryId;
  String symbol;
  double qty;
  DateTime buyDate;
  double buyRate;
  double buyAmt;           // = qty * buyRate, user override allowed
  String? taxProfileId;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;
}

class SellEntry {
  String id;
  String buyEntryId;       // FK → InvestmentEntry
  String symbol;           // denormalized for fast grouping
  double sellQty;
  DateTime sellDate;
  double sellRate;
  double sellAmt;          // = sellQty * sellRate, user override allowed
  DateTime createdAt;
}

// Computed on every read — NEVER stored:
int    days   = sellDate.difference(buyDate).inDays;
double pl     = sellAmt - (buyRate * sellQty);
double plPct  = (pl / (buyRate * sellQty)) * 100;
double tax    = taxProfileId != null ? calculateTax(...) : 0;
double pat    = pl - tax;
double patPct = (pat / (buyRate * sellQty)) * 100;
```

Tax calculation:
```dart
double calculateTax({required TaxProfile p, required double buyAmt, required double sellAmt}) {
  double turnover       = buyAmt + sellAmt;
  double brokerage      = p.brokerageMinOfBoth
      ? min(p.brokerageFlat, turnover * p.brokeragePct)
      : (p.brokeragePct > 0 ? turnover * p.brokeragePct : p.brokerageFlat);
  double exchangeCharge = turnover * p.exchangeChargePct;
  double sebiCharge     = turnover * p.sebiChargePct;
  double gst            = (exchangeCharge + sebiCharge + brokerage) * p.gstPct;
  double stt            = (buyAmt * p.sttBuyPct) + (sellAmt * p.sttSellPct);
  double stampDuty      = buyAmt * p.stampDutyPct;
  double dpCharge       = p.dpChargePerScrip;
  return stt + exchangeCharge + sebiCharge + gst + brokerage + stampDuty + dpCharge;
}
```

---

## 7. Number Formatting Rules

- **Zero currency symbols** — no ₹, Rs, INR anywhere in Investment tab
- Indian locale commas: 1,00,000 / 10,50,500.75
- Abbreviations for large numbers (same as Expense): `10.50 L` for lakhs, `1.00 Cr` for crores
- P/L numbers: prefix `+` green for positive, `-` red for negative (same color tokens as Expense uses)
- Font: 100% identical TextStyle to Expense equivalent element — no new font sizes, weights, or letter-spacing

---

## 8. Analytics Screen

Full-page screen, opened from analytics icon in app bar. Same page structure as Expense analytics.

Date filter at top: **All | Month | Year | 3 Years | Custom** — same widget as Expense analytics.

Charts (use same chart library as Expense — no new dependencies):
1. **P/L Over Time** — Line chart. X = sell date, Y = cumulative P/L.
2. **Investment by Category** — Pie/donut. Value = total buyAmt per category.
3. **Monthly Buy vs Sell** — Grouped bar. Buy bar vs Sell bar per month.
4. **P/L % by Symbol** — Horizontal bar. Top symbols by P/L%. Green = positive, red = negative.
5. **Category P/L Summary** — Table/card. Per category: Total Invested, Total Sell, P/L, P/L%.

All chart styling (font, colors, grid, axis labels) matches Expense analytics exactly.

---

## 9. Broker / Tax Profiles (CRUD)

### Default Pre-Seeded Profiles (fully editable and deletable — same as categories)

**Zerodha**
```
STT Buy: 0.1%   STT Sell: 0.1%   Exchange: 0.00345%   SEBI: 0.0001%
Stamp Duty: 0.015%   GST: 18% of (Exchange + SEBI + Brokerage)
Brokerage: min(₹20 flat, 0.03% of turnover)   DP Charge: ₹15.93/scrip/sell
```
**Angel One**
```
STT Buy: 0.1%   STT Sell: 0.1%   Exchange: 0.00345%   SEBI: 0.0001%
Stamp Duty: 0.015%   GST: 18%   Brokerage: 0 (free delivery)
DP Charge: ₹20/scrip/sell
```
**Motilal Oswal**
```
STT Buy: 0.1%   STT Sell: 0.1%   Exchange: 0.00345%   SEBI: 0.0001%
Stamp Duty: 0.015%   GST: 18%   Brokerage: min(₹20 flat, 0.5% of turnover)
DP Charge: ₹13.5/scrip/sell
```
**Groww**
```
STT Buy: 0.1%   STT Sell: 0.1%   Exchange: 0.00345%   SEBI: 0.0001%
Stamp Duty: 0.015%   GST: 18%   Brokerage: ₹20 flat
DP Charge: ₹19/scrip/sell (₹13.5 + ₹5.5 CDSL)
```
**Upstox**
```
STT Buy: 0.1%   STT Sell: 0.1%   Exchange: 0.00345%   SEBI: 0.0001%
Stamp Duty: 0.015%   GST: 18%   Brokerage: min(₹20 flat, 2.5% of turnover)
DP Charge: ₹18.5/scrip/sell
```

### Broker Edit UI
Full-page form (same style as Add Category form). Each charge component = numeric input field. Live preview card at bottom: "Estimated charges on 1,00,000 buy + 1,05,000 sell = X,XXX" — updates as user types.

### Data Model
```dart
class TaxProfile {
  String id;
  String brokerName;
  double sttBuyPct;
  double sttSellPct;
  double exchangeChargePct;
  double sebiChargePct;
  double stampDutyPct;
  double gstPct;
  double brokeragePct;
  double brokerageFlat;
  bool brokerageMinOfBoth;
  double dpChargePerScrip;
  DateTime createdAt;
  DateTime updatedAt;
}
```

---

## 10. Investment Settings Screen

Full-page screen opened from gear icon in Investment app bar. Title: `Investment Settings`.

**Visual spec: pixel-match Images 3 and 4 (Expense Settings screenshots).** Same card containers, same section header typography, same button shapes and colors, same spacing between sections.

Layout top-to-bottom:

---

### Section: Investment Export (card — same as "Expense Export" card in Image 4)
- Section header: `Investment Export` (bold, same style as Image 4)
- **Time range** dropdown: `All` (options: All / This Month / This Year / Custom) — same outlined dropdown as Image 4
- **Format** dropdown: `PDF` (options: PDF / Excel) — same outlined dropdown as Image 4
- Download button: teal filled rounded button `⬇ Download PDF` / `⬇ Download Excel` — same style as Image 4 Download button. Label updates based on Format selection.

---

### Section: Investment Import (card — same as "Expense Import" card in Image 4)
- Section header: `Investment Import` (bold)
- Description text: "Download a sample Excel file, fill it row by row, then import it. Nothing is saved unless every filled row is valid." (same grey body text as Image 4)
- `⬇ Download Sample Excel` — dark outlined rounded button (same as Image 3/4)
- `⬆ Import Excel` — teal filled rounded button (same as Image 3/4)

---

### Section: Investment Settings (card — same as "Expense Settings" card in Images 3/4)
- Section header: `Investment Settings`
- Subtitle: `Manage investment categories and broker profiles.`

**Categories** subsection (same layout as Categories in Image 3):
- Label: `Categories`
- Two buttons side by side:
  - `View category` — teal text button (left, same style as Image 3)
  - `+ Add category` — dark outlined rounded button (right, same style as Image 3)

Horizontal divider (same as Image 3 divider between Categories and Banks)

**Broker Profiles** subsection (same layout as Banks in Image 3):
- Label: `Broker Profiles`
- Two buttons side by side:
  - `View broker profiles` — teal text button (left)
  - `+ Add broker` — dark outlined rounded button (right)

---

### Section: Preferences (card)
- **Default Broker** — dropdown tile: `Select default broker`
- **Date Format** — toggle tile: DD/MM/YYYY ↔ MM/DD/YYYY

---

### Section: Delete Investment Data (card — same as "Delete Expense Data" card in Image 3)
- Section header: `Delete Investment Data` (bold, same style as Image 3)
- Description text: "This clears all investment entries, sell records, and resets broker profiles and categories to defaults."
- `🗑 Delete Data` button — red/salmon background, white icon and text — **exact copy of the Delete Data button in Image 3** (same rounded shape, same icon, same red-tinted background, same font). Do NOT use a text-only button; match the button from Image 3 pixel-for-pixel.
- Tap → confirmation dialog → on confirm, delete all investment data from local DB and Firebase (if sync enabled).

---

## 11. Import Pipeline (Excel → UI)

### Step 1 — File Pick
User taps `Import Excel` → file picker opens → user selects `.xlsx` file.

### Step 2 — Parse Raw Fields Only

| Import ✅ | Skip ❌ |
|---|---|
| Symbol | Sr. No. |
| Qty | Days |
| Buy Date | P/L |
| Buy Rate | P/L % |
| Buy Amt | Tax |
| Sell Date (optional) | PAT |
| Sell Rate (optional) | PAT % |
| Sell Amt (optional) | Any totals / blank / header rows |

### Step 3 — Auto-Detect Category Sections

| Row keyword | Category |
|---|---|
| `Share Market` | Equity / Stocks |
| `IPO Allocation` | IPO (Allocation) |
| `Mutual Fund` | Mutual Fund |
| `Gold` | Gold |
| `Bond` / `Debt` | Bond / Debt |
| `FD` / `Fixed Deposit` | Fixed Deposit |

Unrecognized keyword → dialog: "Found section '[X]'. Which category?" with dropdown + "Create New".

Mutual Fund column remapping: `Fund Name` → Symbol, `Units` → Qty, `Order Date` → Buy/Sell Date based on `Type` column, `Amount` → Buy/Sell Amt.

### Step 4 — Import Preview Screen (full page)
- Total rows by category
- First 5 rows per category (imported columns only)
- Note: "Days, P/L, P/L%, Tax, PAT, PAT% are calculated by the app and not imported."
- Red highlight on rows missing required fields (Symbol, Qty, Buy Date, Buy Rate) + toggle "Skip invalid rows"
- ⚠️ Duplicate flag: matched by Symbol + Buy Date + Buy Rate + Qty → options: Skip / Overwrite / Add Anyway

### Step 5 — Save & Refresh
- Save only raw fields to local DB
- Group by Symbol (HashSet/Map) — existing symbols get new buy records appended, not duplicated in list
- Navigate back to Investment main screen
- Recompute all summary cards immediately
- Snackbar: "Imported X entries across Y categories"

---

## 12. Export

### Export to Excel
- Filename: `Investment_Export_YYYY_MM_DD.xlsx`
- One sheet per category (matching user's Excel format)
- Columns per sheet: Symbol, Qty, Buy Date, Buy Rate, Buy Amt, Sell Date, Sell Rate, Sell Amt, Days (computed), P/L (computed), P/L% (computed), Tax (computed), PAT (computed), PAT% (computed)
- Final Summary sheet: totals per category + grand totals

### Export to PDF
- Filename: `Investment_Report_YYYY_MM_DD.pdf`
- Summary cards at top, per-category tables below
- Table headers in app primary color

### Download Sample Excel
- Filename: `Investment_Sample_Format.xlsx`
- 2–3 rows per section (Share Market, IPO Allocation, Mutual Fund)
- Note row at top: "Do not fill: Days, P/L, P/L%, Tax, PAT, PAT% — these are calculated by the app"

---

## 13. Firebase Sync

- All investment data syncs to Firebase by default: `investment_entries`, `sell_entries`, `investment_categories`, `investment_tax_profiles`
- Follows same sync logic, conflict resolution, and offline queue as Expense/Credential
- Disabling sync (Global Settings) → removes investment data from Firebase after confirmation, same as other tabs

---

## 14. Global Settings — Additive Change Only

Locate the Firebase/Sync section in Global Settings (where "Sync Credential Data" exists). Add these toggles below it — all **ON by default** — using the same toggle tile style as the existing credential sync toggle:

```
[Toggle ON]  Sync Credentials       ← existing, keep as-is
[Toggle ON]  Sync Expense Data      ← new
[Toggle ON]  Sync Task Data         ← new
[Toggle ON]  Sync Investment Data   ← new
[Toggle ON]  Sync App Defaults      ← new (categories, broker profiles, user preferences)
```

Each toggle turning OFF → confirmation dialog: "This will remove [type] from Firebase. Your local data is not affected." → on confirm, delete from Firebase, stop syncing. Turning ON → immediately uploads local data to Firebase.

Do not change any other part of Global Settings.

---

## 15. Screen Reference Table

| Screen | Navigation Pattern | Visual Reference |
|---|---|---|
| Investment main | Bottom tab | Image 1 (Expense main) |
| Investment history list | Scroll on main | Image 2 (grouped by Symbol, not date) |
| Entry detail (buy + sell history) | Full page push | Expense detail |
| Add buy entry | Full page push | Expense add screen |
| Edit buy entry | Full page push | Expense edit screen |
| Add sell entry | Full page push | Expense add screen |
| Analytics | Full page push | Expense analytics |
| Investment settings | Full page push | Images 3 & 4 (Expense settings) |
| View categories | Full page push | Expense category list |
| Add/Edit category | Full page push | Expense add category |
| View broker profiles | Full page push | Credential tile list |
| Add/Edit broker | Full page push | Expense add category |
| Import preview | Full page push | Clean full-page table |

---

## 16. Absolute Rules (Non-Negotiable)

1. Investment tab is a visual and structural clone of Expense — no new design patterns
2. No currency symbol (₹, Rs, INR) anywhere in Investment tab
3. Font 100% consistent: every TextStyle matches its Expense equivalent exactly
4. Main list: grouped by Symbol name (A→Z), NOT by date
5. Status badge per symbol: Open / Partial / Sold — computed from qty math
6. Tapping a symbol → full-page detail screen (never inline expand, never bottom sheet)
7. Add/Edit/Sell → full-page screens (never bottom sheets)
8. Sell entries linked to buy entry (FK), shown in detail as history sorted latest-first
9. Adding a buy for an existing Symbol → appends to that Symbol group (no duplicate symbol rows)
10. All derived values (P/L, Tax, PAT, Days) computed on every read — never stored, never imported
11. Settings Delete Data button = red background button matching Image 3 exactly
12. Settings layout matches Images 3 & 4 exactly: Export card → Import card → Settings card (Categories + Broker Profiles) → Preferences card → Delete Data card
13. No new libraries for charts, date pickers, or form widgets — reuse Expense tab's existing widgets
14. Firebase sync ON by default; per-data-type toggles in Global Settings only
