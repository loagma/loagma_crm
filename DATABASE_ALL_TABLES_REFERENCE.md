# Database Quick Reference - ALL 101 Tables

## Complete Table List with Counts

| # | Table Name | Purpose | Approx Records | Primary Key |
|-|-|---|---|---|
| **CRM CORE (10)** |
| 1 | LeadsAccount_crm | Accounts/Leads | 58 | id (UUID) |
| 2 | LoginUser_crm | Employees | 31 | id (UUID) |
| 3 | LoginUserRoles_crm | Roles | 5 | id (String) |
| 4 | department_crm | Departments | ? | id |
| 5 | EmployeeArea | Employee-Area Mapping | 0 | id (AI) |
| 6 | AreaAssignment | Salesman Assignments | 0 | id (UUID) |
| 7 | TaskAssignment | Task Assignments | 4 | id (UUID) |
| 8 | Notification | System Alerts | 0 | id (UUID) |
| 9 | BusinessType | Business Categories | 10 | id |
| 10 | Calling_staff | Telecaller Teams | 28 | id (AI) |
| **GEOGRAPHIC (7)** |
| 11 | Country | Countries | 0 | country_id (AI) |
| 12 | State | States | 0 | state_id (AI) |
| 13 | Region | Regions | 0 | region_id (AI) |
| 14 | District | Districts | 0 | district_id (AI) |
| 15 | City | Cities | 0 | city_id (AI) |
| 16 | Area | Areas | 0 | area_id (AI) |
| 17 | Zone | Zones | 0 | zone_id (AI) |
| **BEAT PLANNING (4)** |
| 18 | WeeklyBeatPlan | Weekly Plans | 0 | id (UUID) |
| 19 | DailyBeatPlan | Daily Plans | 0 | id (UUID) |
| 20 | BeatCompletion | Completion Records | 0 | id (UUID) |
| 21 | WeeklyAccountAssignment | Account Scheduling | 2 | id (UUID) |
| **ATTENDANCE (4)** |
| 22 | Attendance | Punch In/Out | 0 | id (UUID) |
| 23 | LatePunchApproval | Late Arrivals | 0 | id (UUID) |
| 24 | EarlyPunchOutApproval | Early Departures | 0 | id (UUID) |
| 25 | SalesmanTrackingPoint | GPS Tracking | 0 | id (UUID) |
| **LEAVE & COMPENSATION (3)** |
| 26 | Leave | Leave Requests | 0 | id (UUID) |
| 27 | LeaveBalance | Leave Allocation | 2 | id (UUID) |
| 28 | SalaryInformation | Salary Structure | 30 | id (UUID) |
| **EXPENSE & TELECALLING (3)** |
| 29 | Expense | Expense Claims | 0 | id (UUID) |
| 30 | TelecallerCallLog | Call Records | 0 | id (UUID) |
| 31 | TelecallerPincodeAssignment | Telecaller Routes | 0 | id (UUID) |
| **PRODUCTS & CATALOG (7)** |
| 32 | product | Products | Large | product_id (AI) |
| 33 | categories | Categories | 300K+ | cat_id (AI) |
| 34 | brand | Brands | 0 | brand_id (AI) |
| 35 | product_photos | Product Images | ? | photo_id (AI) |
| 36 | units_master | Units | ? | unit_id (AI) |
| 37 | hsn_codes | HSN/GST Codes | ? | hsn_id (AI) |
| 38 | supplier_products | Supplier Pricing | ? | supplier_product_id (AI) |
| **PRICING & OFFERS (6)** |
| 39 | product_taxes | Product Taxes | ? | product_id |
| 40 | taxes | Tax Config | ? | tax_id (AI) |
| 41 | promo | Discounts | ? | promo_id (AI) |
| 42 | promo_log | Promo Usage | ? | log_id (AI) |
| 43 | offer_log | Offer Usage | ? | log_id (AI) |
| 44 | offers | Offer Config | ? | offer_id (AI) |
| **ORDERS (5)** |
| 45 | orders | Master Orders | ? | order_id (AI) |
| 46 | orders_item | Order Items | ? | order_item_id (AI) |
| 47 | master_orders | Bulk Orders | ? | master_order_id (AI) |
| 48 | sales_invoices | Invoices | ? | invoice_id (AI) |
| 49 | order_zone_overrides | Zone Exceptions | ? | override_id (AI) |
| **INVENTORY (7)** |
| 50 | physical_stock | Current Stock | ? | product_id |
| 51 | daily_book_stock | Daily Stock | ? | id (AI) |
| 52 | stock_count | Audit Records | ? | stock_count_id (AI) |
| 53 | stock_audit_log | Audit History | ? | log_id (AI) |
| 54 | stock_notify | Low Stock Alerts | ? | notify_id (AI) |
| 55 | stock_count_master_session | Audit Sessions | ? | session_id (AI) |
| 56 | stock_count_assignments | Audit Assignments | ? | assignment_id (AI) |
| **PROCUREMENT (8)** |
| 57 | suppliers | Suppliers | ? | supplier_id (AI) |
| 58 | purchase_orders | POs | ? | po_id (AI) |
| 59 | purchase_order_items | PO Items | ? | po_item_id (AI) |
| 60 | purchase_vouchers | Purchase Invoices | ? | voucher_id (AI) |
| 61 | purchase_voucher_items | Voucher Items | ? | voucher_item_id (AI) |
| 62 | purchase_returns | Return Documents | ? | return_id (AI) |
| 63 | purchase_return_items | Returned Items | ? | return_item_id (AI) |
| 64 | product_purchase | Purchase History | ? | purchase_id (AI) |
| **SHOPPING (2)** |
| 65 | cart | Shopping Carts | 0 | cart_id (AI) |
| 66 | cart_type | Cart Categories | 4 | cart_tid (AI) |
| **MANUFACTURING (6)** |
| 67 | bom_master | BOM Master | 3 | bom_id (AI) |
| 68 | bom_items | BOM Components | 6 | bom_item_id (AI) |
| 69 | issue_to_production | Material Issues | ? | id (AI) |
| 70 | issue_to_production_items | Issue Items | ? | id (AI) |
| 71 | receive_from_production | Production Receipts | ? | id (AI) |
| 72 | receive_from_production_items | Receipt Items | ? | id (AI) |
| **FLEET & TRIPS (5)** |
| 73 | trips | Trip Records | ? | trip_id (AI) |
| 74 | trip_cards | Trip Assignments | ? | trip_card_id (AI) |
| 75 | trip_card_pincode | Trip Pincodes | ? | id (AI) |
| 76 | driver_rating | Driver Ratings | ? | rating_id (AI) |
| 77 | driver_accountability_log | Driver Audit | ? | log_id (AI) |
| **TIME SLOTS (3)** |
| 78 | time_slots | Delivery Slots | ? | slot_id (AI) |
| 79 | timing_slot_groups | Slot Groups | ? | group_id (AI) |
| 80 | timing_slot_group_categories | Group-Category Map | ? | map_id (AI) |
| **USERS (2)** |
| 81 | users | Customers | ? | user_id (AI) |
| 82 | user_addresses | Delivery Addresses | ? | address_id (AI) |
| **ADMIN & STAFF (2)** |
| 83 | admin | Admin Accounts | 9 | userid (AI) |
| 84 | deli_staff | Delivery Staff | ? | id (AI) |
| **AUTH & SESSIONS (3)** |
| 85 | user | Portal Users | ? | user_id (AI) |
| 86 | sessions | Active Sessions | ? | session_id (String) |
| 87 | password_reset_tokens | Reset Tokens | ? | token (String) |
| **CACHE (2)** |
| 88 | cache | Query Cache | ? | key (String) |
| 89 | cache_locks | Cache Locks | ? | key (String) |
| **SECURITY (1)** |
| 90 | otp | OTP Management | ? | otp_id (AI) |
| **JOBS (2)** |
| 91 | jobs | Job Queue | ? | id (AI) |
| 92 | job_batches | Batch Processing | ? | id (String) |
| **MIGRATIONS (2)** |
| 93 | migrations | Laravel Migrations | ? | id (AI) |
| 94 | _prisma_migrations | Prisma Migrations | ? | id (String) |
| **UTILITIES (4)** |
| 95 | search | Search Index | ? | id (AI) |
| 96 | inventory_op | Inventory Operations | ? | id (AI) |
| 97 | failed_jobs | Failed Tasks | ? | id (AI) |
| 98 | trip_audit_log | Trip History | ? | log_id (AI) |
| 99 | roles | Role Definitions | ? | role_id (AI) |
| 100 | stock_voucher | Stock Adjustments | ? | voucher_id (AI) |
| 101 | stock_voucher_items | Voucher Items | ? | voucher_item_id (AI) |

---

## Essential SQL Queries

### CRM Queries

**1. Get all accounts pending approval**
```sql
SELECT id, accountCode, businessName, personName, pincode, createdAt
FROM LeadsAccount_crm
WHERE isApproved = 0
ORDER BY createdAt DESC;
```

**2. Get all employees and their departments**
```sql
SELECT lu.id, lu.employeeCode, lu.name, lu.email, lu.roleId, lu.departmentId
FROM LoginUser_crm lu
WHERE lu.isActive = 1
ORDER BY lu.employeeCode;
```

**3. Get today's attendance records**
```sql
SELECT a.id, a.employeeId, a.employeeName, a.punchInTime, a.punchOutTime,
       a.totalWorkHours, a.isLatePunchIn, a.status
FROM Attendance a
WHERE DATE(a.date) = CURDATE()
ORDER BY a.punchInTime DESC;
```

**4. Get leave requests pending approval**
```sql
SELECT l.id, l.employeeId, l.employeeName, l.leaveType, l.startDate, 
       l.endDate, l.numberOfDays, l.reason, l.status, l.requestedAt
FROM Leave l
WHERE l.status = 'PENDING'
ORDER BY l.requestedAt DESC;
```

**5. Get accounts by salesman**
```sql
SELECT waa.accountId, la.accountCode, la.businessName, waa.salesmanId, 
       waa.weekStartDate, waa.assignedDays
FROM WeeklyAccountAssignment waa
JOIN LeadsAccount_crm la ON waa.accountId = la.id
WHERE waa.salesmanId = ?
AND waa.weekStartDate >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
ORDER BY waa.weekStartDate DESC;
```

**6. Get employee salary information**
```sql
SELECT lu.employeeCode, lu.name, si.basicSalary, 
       (si.basicSalary + COALESCE(si.hra, 0) + COALESCE(si.travelAllowance, 0)) as totalEarnings,
       si.effectiveFrom
FROM LoginUser_crm lu
JOIN SalaryInformation si ON lu.id = si.employeeId
WHERE si.isActive = 1;
```

**7. Get pending expense claims**
```sql
SELECT id, employeeId, expenseType, amount, expenseDate, status, approvedBy, approvedAt
FROM Expense
WHERE status IN ('Pending', 'Submitted')
ORDER BY expenseDate DESC;
```

**8. Get leave balance**
```sql
SELECT lu.name, lb.year, lb.sickLeaves, lb.casualLeaves, lb.earnedLeaves,
       (lb.sickLeaves - COALESCE(lb.usedSickLeaves, 0)) as sickAvailable,
       (lb.casualLeaves - COALESCE(lb.usedCasualLeaves, 0)) as casualAvailable,
       (lb.earnedLeaves - COALESCE(lb.usedEarnedLeaves, 0)) as earnedAvailable
FROM LeaveBalance lb
JOIN LoginUser_crm lu ON lb.employeeId = lu.id
WHERE lb.year = YEAR(CURDATE());
```

**9. Get late punch approvals pending**
```sql
SELECT lpa.id, lpa.employeeId, lpa.employeeName, lpa.punchInDate, 
       lpa.reason, lpa.status, lpa.approvalCode, lpa.codeExpiresAt
FROM LatePunchApproval lpa
WHERE lpa.status = 'PENDING'
ORDER BY lpa.requestDate DESC;
```

**10. Get beat completion records**
```sql
SELECT bc.id, bc.salesmanId, bc.areaName, bc.accountsVisited, bc.completedAt,
       bc.isVerified, bc.verifiedBy
FROM BeatCompletion bc
WHERE bc.completedAt >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
ORDER BY bc.completedAt DESC;
```

---

### E-Commerce Queries

**11. Get product inventory**
```sql
SELECT p.product_id, p.name, ps.quantity_on_hand, p.unit_type
FROM product p
LEFT JOIN physical_stock ps ON p.product_id = ps.product_id
WHERE ps.quantity_on_hand > 0
ORDER BY p.name;
```

**12. Get pending purchase orders**
```sql
SELECT po.po_id, po.supplier_id, s.name as supplier, po.order_date, 
       po.total_amount, po.status
FROM purchase_orders po
JOIN suppliers s ON po.supplier_id = s.supplier_id
WHERE po.status NOT IN ('Received', 'Cancelled')
ORDER BY po.order_date DESC;
```

**13. Get order details**
```sql
SELECT o.order_id, o.userid, oi.product_id, oi.quantity, oi.price,
       (oi.quantity * oi.price) as line_total, o.status
FROM orders o
JOIN orders_item oi ON o.order_id = oi.order_id
WHERE o.order_id = ?;
```

**14. Get top selling products**
```sql
SELECT oi.product_id, p.name, SUM(oi.quantity) as total_qty, 
       SUM(oi.quantity * oi.price) as total_sales
FROM orders_item oi
JOIN product p ON oi.product_id = p.product_id
WHERE oi.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY oi.product_id
ORDER BY total_sales DESC LIMIT 20;
```

**15. Get low stock products**
```sql
SELECT p.product_id, p.name, ps.quantity_on_hand, sn.min_quantity
FROM product p
LEFT JOIN physical_stock ps ON p.product_id = ps.product_id
LEFT JOIN stock_notify sn ON p.product_id = sn.product_id
WHERE COALESCE(ps.quantity_on_hand, 0) <= COALESCE(sn.min_quantity, 10)
ORDER BY ps.quantity_on_hand ASC;
```

---

### Telecalling Queries

**16. Get call log summary**
```sql
SELECT tcl.telecallerId, lu.name, COUNT(*) as calls, 
       SUM(CASE WHEN tcl.status = 'Connected' THEN 1 ELSE 0 END) as connected,
       AVG(tcl.durationSec) as avg_duration_sec
FROM TelecallerCallLog tcl
JOIN LoginUser_crm lu ON tcl.telecallerId = lu.id
GROUP BY tcl.telecallerId
ORDER BY calls DESC;
```

**17. Get accounts due for follow-up**
```sql
SELECT tcl.accountId, la.businessName, la.contactNumber,
       MAX(tcl.calledAt) as last_call, tcl.nextFollowupAt
FROM TelecallerCallLog tcl
JOIN LeadsAccount_crm la ON tcl.accountId = la.id
WHERE tcl.nextFollowupAt <= CURDATE()
GROUP BY tcl.accountId
ORDER BY tcl.nextFollowupAt;
```

---

### Manufacturing Queries

**18. Get BOM details**
```sql
SELECT bm.bom_id, bm.product_id, bm.bom_version, bm.status,
       bi.raw_material_id, bi.quantity_per_unit, bi.unit_type
FROM bom_master bm
LEFT JOIN bom_items bi ON bm.bom_id = bi.bom_id
WHERE bm.status = 'APPROVED'
ORDER BY bm.product_id, bm.bom_version DESC;
```

---

### Stock Management Queries

**19. Get stock audit summary**
```sql
SELECT scms.session_id, COUNT(*) as products_audited,
       SUM(CASE WHEN sal.variance > 0 THEN 1 ELSE 0 END) as discrepancies
FROM stock_count_master_session scms
LEFT JOIN stock_count sc ON scms.session_id = sc.session_id
LEFT JOIN stock_audit_log sal ON sc.stock_count_id = sal.stock_count_id
GROUP BY scms.session_id
ORDER BY scms.start_date DESC;
```

**20. Get stock movement summary**
```sql
SELECT p.product_id, p.name, ps.quantity_on_hand,
       COALESCE(dbs.closing_stock, 0) as yesterday_stock
FROM product p
LEFT JOIN physical_stock ps ON p.product_id = ps.product_id
LEFT JOIN daily_book_stock dbs ON p.product_id = dbs.vendor_product_id 
                                AND dbs.date = DATE_SUB(CURDATE(), INTERVAL 1 DAY)
WHERE ps.quantity_on_hand > 0
ORDER BY p.name;
```

---

## Connection String

```
Host: gateway01.ap-southeast-1.prod.aws.tidbcloud.com
Port: 4000
Database: loagma_new
User: root
Charset: utf8mb4
Collation: utf8mb4_unicode_ci
Driver: MySQL
TLS: Required (for TiDB Cloud)
```

---

## Validation Rules (Sample)

| Field | Validation | Table |
|---|---|---|
| contactNumber | 10-digit, unique | LoginUser_crm, LeadsAccount_crm |
| email | Valid format, unique | LoginUser_crm |
| pincode | 6-digit format | LeadsAccount_crm, AreaAssignment |
| businessType | From BusinessType table | LeadsAccount_crm |
| status | ENUM values depend on context | Multiple |
| amount | Positive decimal | Expense, SalaryInformation |
| createdAt | AUTO CURRENT_TIMESTAMP | Most tables |
| isActive | Binary (0/1) | Most master tables |

---

## Best Practices

✅ DO:
- Use parameterized queries to prevent SQL injection
- Always check status before critical operations (approvals, payments)
- Use UUID for cross-service references
- Set appropriate timezone (UTC+00:00 in TiDB)
- Index frequently filtered columns (status, createdAt, employeeId)
- Archive old attendance and tracking data quarterly

❌ DON'T:
- Don't perform transactions without proper locking
- Don't assume default values in JSON fields
- Don't mix TIMESTAMP and DATETIME types carelessly
- Don't use string IDs where numeric would suffice
- Don't store sensitive data without encryption
- Don't leave failed_jobs unmonitored

---

## Common Troubleshooting

| Issue | Solution |
|---|---|
| Table doesn't exist | Check for migrations - run `_prisma_migrations` |
| Foreign key constraint fails | Verify parent record exists first |
| JSON parsing errors | Validate JSON format before INSERT/UPDATE |
| Timezone mismatch | Ensure application uses same timezone as DB |
| Duplicate entry on unique key | Check existing data before INSERT |
| Permission denied | Verify user credentials and tables are accessible |

