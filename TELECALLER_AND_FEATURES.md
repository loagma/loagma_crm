# Loagma CRM – Features & Telecaller Side

Short overview of what’s built, existing features, and how the **telecaller** side works.

---

## What’s Done

- **Flutter** app (Android, iOS, Web) with **Node.js/Express** backend.
- **PostgreSQL** + **Prisma**; **JWT** + OTP login; **RBAC** (admin, salesman, telecaller, manager).
- End-to-end flows: accounts, attendance, beat plan, leave, expenses, notifications, approvals.

---

## Existing Features (High Level)

| Area | What Exists |
|------|-------------|
| **Auth** | OTP login, JWT, role-based redirect to dashboard |
| **Accounts** | Create/edit accounts, pincode-based location, stages (Lead → Verified → Customer) |
| **Approval** | Account: telecaller verify → admin approve; Leave / Late punch / Early punch / Expense approvals |
| **Attendance** | Punch in/out, photo, location, bike km; late/early approval workflows |
| **Beat plan** | Weekly/daily beat plans for salesmen, territory management |
| **Leave** | Apply leave, admin approve, balance |
| **Expenses** | Submit claims, admin approve |
| **Notifications** | Role-targeted in-app notifications |
| **Live tracking** | Salesman location tracking (see `LIVE_TRACKING_README.md`, `COMPLETE_TRACKING_FLOW.md`) |

---

## Telecaller Side – Overview

Telecallers work on **leads/accounts**: call them, log outcomes, verify accounts, and manage follow-ups. Admin later approves verified accounts to **Customer**.

### Telecaller Menu (Sidebar)

- **Dashboard** – Summary stats (calls today, interested, follow-ups, sales closed).
- **Account Master** – Add new accounts/leads.
- **Manage Accounts** – View/filter all accounts.
- **Verify Accounts** – Review pending accounts: call, log outcome, verify or reject.
- **Call History** – List of all call logs (last 200) for the logged-in telecaller.
- **Follow-up Management** – Today / overdue / upcoming follow-ups from logged calls.

---

## Telecaller Workflow (One Example)

End-to-end flow for one lead: from **pending** to **verified** (then admin approves to Customer) or **rejected**, with optional follow-ups.

```
1. Login as telecaller
   → Dashboard shows today’s stats (calls, interested, follow-ups, sales closed).

2. Open "Verify Accounts"
   → See list of pending accounts (optionally filter by salesman/telecaller).

3. Pick a pending account
   → Tap "Call" to open dialer and call the contact.

4. After the call – "Log call"
   → Choose outcome: e.g. Follow-up – Interested / Not Interested / Sale Closed / etc.
   → Optionally: duration, notes, next follow-up date + notes (for Interested / Call back later).
   → Call is saved; if "Sale Closed", account stage is updated.

5a. If lead is genuine and verified
   → Tap "Verify", add verification notes.
   → Account moves to "Verified"; admin can later approve it to "Customer".

5b. If lead is invalid or not interested
   → Tap "Reject", add rejection notes.
   → Account stays rejected; no admin approval.

6. Follow-ups
   → When outcome was "Follow-up – Interested" or "Call back later", "Follow-up Management"
     shows the lead under Today / Overdue / Upcoming.
   → Telecaller calls again on the scheduled date, logs another call, and can Verify/Reject
     or schedule another follow-up.
```

**Summary:** Pending → Call → Log outcome → Verify (admin approves to Customer) or Reject; optional follow-up loop until Verify/Reject/Sale closed.

---

## How Telecaller Features Work

### 1. Dashboard

- **API:** `GET /telecaller/dashboard/summary`
- Returns for the logged-in telecaller:
  - **todayCalls** – Calls made today
  - **interestedLeads** – Calls today with status “Follow-up – Interested”
  - **followupsToday** – Follow-ups scheduled for today
  - **salesClosed** – Total calls with “Sale Closed”

### 2. Verify Accounts

- Screen shows **pending** (and optionally verified/all) accounts.
- Filters: status (pending/verified/all), salesman, telecaller.
- For each account the telecaller can:
  - **Call** – Open dialer (contact number).
  - **Log call** – Open bottom sheet to record:
    - **Call status** (see below)
    - Duration, notes, optional recording URL, optional **next follow-up date** and notes.
  - **Verify** – Mark account as telecaller-verified (add verification notes). Admin can then do final approval to Customer.
  - **Reject** – Reject with notes.
- **Admin** can see telecaller verification notes and perform final approval to move account to Customer.

### 3. Call statuses (outcomes)

| UI Label | API value | Meaning |
|----------|-----------|--------|
| DNP – Not Reachable | `DNP_NOT_REACHABLE` | Could not reach |
| DNP – RNR (Ring No Response) | `DNP_RNR` | No answer |
| Follow-up – Interested | `FOLLOWUP_INTERESTED` | Interested; schedule follow-up |
| Wrong Number | `WRONG_NUMBER` | Invalid number |
| Not Interested | `NOT_INTERESTED` | Not interested |
| Call Back Later | `CALL_BACK_LATER` | Call again later |
| Done / Sale Closed | `SALE_CLOSED` | Sale closed; account can move to Customer/Won |

For **Follow-up – Interested** and **Call Back Later**, telecaller can set **next follow-up date** and notes; these drive **Follow-up Management**.

### 4. Call log (backend)

- **API:** `POST /telecaller/leads/:id/calls`
- Body: `status`, optional `durationSec`, `notes`, `recordingUrl`, `calledAt`, `nextFollowupAt`, `followupNotes`.
- Creates a **TelecallerCallLog** linked to account and telecaller. If status is `SALE_CLOSED`, account’s `customerStage`/`funnelStage` are updated.

### 5. Call History

- **API:** `GET /telecaller/call-history`
- Returns last **200** call logs for the telecaller with account summary (name, business, contact). Ordered by `calledAt` desc.

### 6. Follow-up Management

- **API:** `GET /telecaller/followups`
- Returns follow-ups (calls that have `nextFollowupAt` set), grouped as:
  - **today** – due today
  - **overdue** – past due
  - **upcoming** – future
- Each item includes account (person name, business name, contact) and follow-up date/notes.

---

## Telecaller API Summary

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/telecaller/dashboard/summary` | Dashboard counts |
| POST | `/telecaller/leads/:id/calls` | Log a call for account `:id` |
| GET | `/telecaller/followups` | Today / overdue / upcoming follow-ups |
| GET | `/telecaller/call-history` | Call history (200 recent) |

All require **JWT** (logged-in user); counts and lists are **scoped to the telecaller** (`req.user.id`).

---

## Data (relevant to telecaller)

- **Account** – `customerStage`, `funnelStage`, `approvedById`, `verificationNotes`, `rejectionNotes` (telecaller verify/reject; admin approve).
- **TelecallerCallLog** – `accountId`, `telecallerId`, `calledAt`, `durationSec`, `status`, `notes`, `recordingUrl`, `nextFollowupAt`, `followupNotes`.

For full schema and tables see **Data_doc.md**.
