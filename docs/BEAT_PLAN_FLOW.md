# How Weekly Beat Plans Work (Non‑Technical Guide)

---

## 1. Concepts

- **Account**: Customer record (name, business, contact, pincode, area).
- **Weekly Beat Plan**:
  - One **salesman**.
  - One **week** (Mon–Sun).
  - **Total Accounts**: total customers allotted that week.
  - **Pincodes**: pincodes covered by this plan.
- **Daily Plan (Mon–Sun)**:
  - For each day: a list of **accounts** assigned to that day.
  - **Status**: `PLANNED`, `IN_PROGRESS`, `COMPLETED`, `MISSED`.

### High-level flow

```mermaid
flowchart LR
  Admin[Admin]
  Mgmt[Beat Plan Management]
  Select[Select Accounts]
  Create[Create Plan]
  Details[Beat Plan Details]
  Salesman[Salesman]
  Today[Today Beat Plan]
  Complete[Mark Complete]

  Admin --> Mgmt
  Mgmt -->|"Select accounts"| Select
  Select --> Create
  Create --> Mgmt
  Mgmt -->|View| Details
  Salesman --> Today
  Today --> Complete
  Complete --> Mgmt
```

---

## 2. Admin Flow – Creating a Beat Plan

### 2.1 Entry point

- Admin opens **Beat Plan Management**.
- Clicks **"Select accounts"** (FAB) to start a new beat plan.

### 2.2 Select Salesman and Accounts

1. **Select Salesman**
   - Choose the salesman for whom the plan is being created.

2. **Select Accounts (Customer-based)**
   - Filter by **pincode** (single or multiple, chips).
   - For each pincode:
     - **Select all accounts** in that pincode, or
     - Enter **N** to select first N accounts, or
     - Manually tick individual accounts.
   - Global selection is tracked as a set of account IDs across all pincodes.
   - The **Allot / Next** button shows the **total selected accounts**.

3. **Confirm Selection**
   - When done selecting, proceed to beat plan creation.
   - Backend receives:
     - `salesmanId`
     - `weekStartDate`
     - `selectedAccountIds[]`

### 2.3 Distribute Accounts by Day (Auto / Manual)

1. **Auto distribution (current behavior)**
   - Backend splits the selected account IDs across **7 days** (Mon–Sun).
   - For each day:
     - Builds `dayAssignments[day] = [accountIds...]`.

2. **Generate Weekly Plan**

Backend (`BeatPlanService.generateFromCustomers`):

- Creates a **WeeklyBeatPlan**:
  - `salesmanId`, `salesmanName`
  - `weekStartDate`, `weekEndDate` (Mon–Sun)
  - `pincodes` (unique pincodes from assigned accounts)
  - `totalAreas` = total **accounts** (semantic = accounts, not areas)
  - `status = ACTIVE`
- For each day `1..7`:
  - Creates **DailyBeatPlan**:
    - `dayOfWeek` (1=Mon…7=Sun)
    - `dayDate`
    - `assignedAreas` (derived from account areas – legacy support)
    - `plannedVisits` = number of accounts for that day
    - `status = PLANNED`
- Updates each **Account**:
  - `assignedToId = salesmanId`
  - `assignedDays = [dayOfWeek]` for the day it is allotted.

Result: a weekly plan with 7 days, each day having N accounts.

### Admin creation flow (detailed)

```mermaid
flowchart TD
  Start[Open Beat Plan Management]
  FAB[Tap Select accounts FAB]
  PickSalesman[Select Salesman]
  FilterPincode[Filter by pincode]
  AddPincodes[Add one or more pincodes]
  SelectAccounts[Select all or N or manual]
  Allot[Tap Allot]
  Backend[Backend generateFromCustomers]
  CreateWeekly[Create WeeklyBeatPlan]
  CreateDaily[Create 7 DailyBeatPlans]
  UpdateAccounts[Update Account assignedToId and assignedDays]
  Done[Return to Management list]

  Start --> FAB
  FAB --> PickSalesman
  PickSalesman --> FilterPincode
  FilterPincode --> AddPincodes
  AddPincodes --> SelectAccounts
  SelectAccounts --> Allot
  Allot --> Backend
  Backend --> CreateWeekly
  CreateWeekly --> CreateDaily
  CreateDaily --> UpdateAccounts
  UpdateAccounts --> Done
```

---

## 3. Admin – Managing Beat Plans

### 3.1 Beat Plan Management Screen

- Lists **WeeklyBeatPlans** with summary card:

  - **Header**: salesman name, week range, status chip (e.g. ACTIVE).
  - **Stats row**:
    - **Accounts**: `totalAreas` (total accounts in the week).
    - **Done**: completion % (based on completions vs total accounts).
    - **Pincodes**: count of unique pincodes in the plan.
  - **Day preview row**:
    - Mon..Sun with numbers = **accounts/areas per day**.
  - Actions:
    - **View** – open **Beat Plan Details**.
    - **Delete** – remove weekly plan (and all daily plans/completions).

### 3.2 View / Edit Beat Plan Details

- **Top card**:
  - Salesman name, week range, status chip.
  - `Total Accounts` (total allotted accounts).
  - `Completion %`.
  - `Assigned Pincodes` as chips.

- **Daily Plans** section:
  - For each day (Mon–Sun):

    - **Header row**:
      - Day name + date.
      - Status chip (PLANNED, IN_PROGRESS, COMPLETED, MISSED).
    - **Count line**:
      - `Accounts: X` where `X = dailyPlan.accounts.length`.
    - **Account list** (if X > 0):
      - Flat list of accounts with:
        - Name / business name.
        - Contact number.
        - Address (area, pincode).
    - If no accounts:
      - `Accounts: 0` and no list.

- **Data source for per-day accounts**:
  - Backend `getWeeklyBeatPlanDetails`:
    - For each `dailyPlan.dayOfWeek`:
      - Primary query (customer-based):
        - `assignedToId = salesmanId`
        - `assignedDays` contains `dayOfWeek`
        - `isActive = true`
      - If such accounts exist ⇒ **use them**.
      - If none and there are **no customer assignments at all** ⇒ fallback to:
        - `area in dailyPlan.assignedAreas` OR `pincode in weeklyPlan.pincodes`.

- **Result**:
  - Counts and account lists per day **match** the distribution seen in Beat Plan Management.
  - Days with no assigned accounts show **0** and no list.

### How per-day accounts are loaded (Details)

```mermaid
flowchart TD
  Req[GET beat-plans id]
  ForEachDay[For each DailyPlan day 1 to 7]
  QueryAssigned[Query Account by assignedToId and assignedDays contains dayOfWeek]
  HasRows{Accounts found?}
  UseAssigned[Use these accounts for this day]
  HasCustomer{Plan has any customer assignments?}
  Fallback[Fallback: query by assignedAreas OR pincodes]
  UseFallback[Use fallback accounts]
  Empty[Return empty list for this day]
  Merge[Return dailyPlans with accounts]

  Req --> ForEachDay
  ForEachDay --> QueryAssigned
  QueryAssigned --> HasRows
  HasRows -->|Yes| UseAssigned
  HasRows -->|No| HasCustomer
  HasCustomer -->|Yes| Empty
  HasCustomer -->|No| Fallback
  Fallback --> UseFallback
  UseAssigned --> Merge
  Empty --> Merge
  UseFallback --> Merge
```

---

## 4. Salesman Flow

### 4.1 Today's Beat Plan

- Salesman opens **Today's Beat Plan** screen.
- Backend `getTodaysBeatPlan`:

  1. Determine today's `dayOfWeek` (1–7).
  2. Find this week's **WeeklyBeatPlan** (by salesman, weekStartDate).
  3. Try to get a **DailyBeatPlan** for today.
  4. Fetch accounts:
     - For area-based plans:
       - Accounts by `assignedAreas` and/or `pincodes`.
     - For customer-based plans (no weekly plan or no daily plan):
       - Fallback: query accounts where:
         - `assignedToId = salesmanId`
         - `assignedDays` contains today's `dayOfWeek`.

- UI shows:
  - Summary of today (account count, status).
  - List/map of accounts to visit.

### 4.2 Marking Completion

- When salesman finishes visiting an area/day:
  - Calls `markBeatAreaComplete` with:
    - `dailyBeatId`, `areaName`, `accountsVisited`, location, notes.
  - Backend:
    - Creates **BeatCompletion** record.
    - Increments `actualVisits`.
    - If all areas for that day are completed:
      - Marks daily plan `status = COMPLETED`.

- Completion is reflected:
  - In **Beat Plan Management** as higher `Done %`.
  - In **Beat Plan Details**:
    - Status chip updates (e.g. PLANNED → COMPLETED).

### Salesman flow

```mermaid
flowchart TD
  Open[Salesman opens app]
  TodayScreen[Today Beat Plan screen]
  GetDay[Backend: get dayOfWeek 1-7]
  FindWeekly[Find WeeklyBeatPlan for this week]
  HasPlan{Weekly plan exists?}
  GetDaily[Get DailyBeatPlan for today]
  FetchByArea[Fetch accounts by assignedAreas or pincodes]
  FetchByAssigned[Fetch accounts by assignedToId and assignedDays]
  ShowList[Show account list to visit]
  Visit[Salesman visits accounts]
  MarkComplete[Call markBeatAreaComplete]
  CreateCompletion[Create BeatCompletion]
  UpdateStatus[Update daily plan status if all done]

  Open --> TodayScreen
  TodayScreen --> GetDay
  GetDay --> FindWeekly
  FindWeekly --> HasPlan
  HasPlan -->|Yes| GetDaily
  HasPlan -->|No| FetchByAssigned
  GetDaily --> FetchByArea
  FetchByArea --> ShowList
  FetchByAssigned --> ShowList
  ShowList --> Visit
  Visit --> MarkComplete
  MarkComplete --> CreateCompletion
  CreateCompletion --> UpdateStatus
```

---

## 5. Data Model Summary (simplified)

- **WeeklyBeatPlan**
  - `id`
  - `salesmanId`, `salesmanName`
  - `weekStartDate`, `weekEndDate`
  - `pincodes[]`
  - `totalAreas` (meaning: total accounts)
  - `status` (ACTIVE, LOCKED, COMPLETED, etc.)
  - `dailyPlans[]` (relation)

- **DailyBeatPlan**
  - `id`
  - `weeklyBeatId`
  - `dayOfWeek` (1–7)
  - `dayDate`
  - `assignedAreas[]` (legacy)
  - `plannedVisits` (accounts planned)
  - `actualVisits`
  - `status`
  - `beatCompletions[]` (relation)

- **Account**
  - `id`
  - `assignedToId` (salesman)
  - `assignedDays` (Int[]: days 1–7)
  - `personName`, `businessName`
  - `contactNumber`
  - `pincode`, `area`, `address`
  - `isActive`

### Entity relationship

```mermaid
erDiagram
  User ||--o{ WeeklyBeatPlan : "salesman"
  WeeklyBeatPlan ||--|{ DailyBeatPlan : "has"
  DailyBeatPlan ||--o{ BeatCompletion : "has"
  User ||--o{ BeatCompletion : "salesman"
  Account }o--|| User : "assignedTo"

  WeeklyBeatPlan {
    string id
    string salesmanId
    string salesmanName
    date weekStartDate
    date weekEndDate
    stringArray pincodes
    int totalAreas
    string status
  }

  DailyBeatPlan {
    string id
    string weeklyBeatId
    int dayOfWeek
    date dayDate
    stringArray assignedAreas
    int plannedVisits
    int actualVisits
    string status
  }

  Account {
    string id
    string assignedToId
    intArray assignedDays
    string personName
    string businessName
    string pincode
    string area
  }

  BeatCompletion {
    string id
    string dailyBeatId
    string salesmanId
    string areaName
    int accountsVisited
  }

  User {
    string id
    string name
  }
```
