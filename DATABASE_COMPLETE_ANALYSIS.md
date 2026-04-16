# Complete Database Analysis - Loagma CRM
**Database:** loagma_new  
**Type:** MySQL (TiDB Cloud v7.5.6-serverless)  
**Total Tables:** 101  
**Host:** gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000

---

## Database Overview

The loagma_new database is a comprehensive system supporting:
1. **Sales & CRM Operations** (31 tables) - Accounts, leads, beat planning, assignments
2. **E-Commerce/Orders** (20+ tables) - Orders, products, inventory, suppliers, pricing
3. **Manufacturing/BOM** (8 tables) - Bill of Materials, production, inventory operations
4. **Fleet/Delivery Management** (8 tables) - Trips, drivers, delivery tracking
5. **System Infrastructure** (20+ tables) - Users, roles, sessions, jobs, caching
6. **Stock Management** (10+ tables) - Stock counting, audits, vouchers

---

## SECTION 1: CRM & SALES TABLES (31 tables)

### Geographic Hierarchy
| Table | Purpose | Key Fields | Status |
|-------|---------|-----------|--------|
| Country | Countries master | country_id, country_name | Config |
| State | States per country | state_id, state_name, country_id | Config |
| Region | Regions per state | region_id, region_name, state_id | Config |
| District | Districts per region | district_id, district_name, region_id | Config |
| City | Cities per district | city_id, city_name, district_id | Config |
| Area | Areas per city | area_id, area_name, zone_id | Config |
| Zone | Zones per city | zone_id, zone_name, city_id | Config |

### User Management
| Table | Purpose | Records | Key Fields |
|-------|---------|---------|-----------|
| LoginUser_crm | Employees | 31 | id, employeeCode, email, contactNumber, roleId |
| LoginUserRoles_crm | Roles | 5 | id, name (Admin, Manager, Salesman, Telecaller, Test2) |
| department_crm | Departments | ? | id, name |
| EmployeeArea | Employee-Area Mapping | ? | employeeId, area_id, latitude, longitude |

### Accounts & Leads
| Table | Purpose | Records | Key Fields |
|-------|---------|---------|-----------|
| LeadsAccount_crm | Accounts/Leads | 58 | id, accountCode, businessName, personName, contactNumber |
| | | | customerStage, funnelStage, isApproved, pincode |

### Beat Planning & Execution
| Table | Purpose | Key Fields | Status |
|-------|---------|-----------|--------|
| WeeklyBeatPlan | Weekly plans | salesmanId, weekStartDate, pincodes, status | Planning |
| DailyBeatPlan | Daily breakdown | weeklyBeatId, dayOfWeek, assignedAreas, status | Execution |
| BeatCompletion | Completion records | dailyBeatId, salesmanId, accountsVisited, verifiedBy | Tracking |

### Assignment Management
| Table | Purpose | Key Fields | Notes |
|-------|---------|-----------|-------|
| AreaAssignment | Pincode assignments | salesmanId, pinCode, areas, businessTypes | Geographic |
| TaskAssignment | Task assignments | salesmanId, pincode, totalBusinesses, assignedDate | Legacy |
| WeeklyAccountAssignment | Account scheduling | accountId, salesmanId, weekStartDate, sequenceNo | Recurrence enabled |
| TelecallerPincodeAssignment | Telecaller areas | telecallerId, pincode, dayOfWeek | Day-based |

### Attendance & Time Tracking
| Table | Purpose | Records | Key Fields |
|-------|---------|---------|-----------|
| Attendance | Daily check-in/out | 0 | employeeId, punchInTime, punchOutTime (with GPS) |
| LatePunchApproval | Late arrivals | 0 | employeeId, punchInDate, reason, status, approvalCode |
| EarlyPunchOutApproval | Early departures | 0 | employeeId, punchOutDate, reason, approvalCode |
| SalesmanTrackingPoint | GPS tracking | 0 | employeeId, attendanceId, latitude, longitude, recordedAt |

### Leave & Compensation
| Table | Purpose | Records | Key Fields |
|-------|---------|---------|-----------|
| Leave | Leave requests | 0 | employeeId, leaveType, startDate, endDate, status |
| LeaveBalance | Annual allocation | 2 | employeeId, year, sickLeaves (12), casualLeaves (10), earnedLeaves (20) |
| SalaryInformation | Salary structure | 30 | employeeId, basicSalary, HRA, allowances, deductions |

### Expense Management
| Table | Purpose | Key Fields | Workflow |
|-------|---------|-----------|----------|
| Expense | Claim submissions | employeeId, expenseType, amount, status | Pending → Approved → Paid |

### Telecalling Operations
| Table | Purpose | Records | Key Fields |
|-------|---------|---------|-----------|
| TelecallerCallLog | Call logs | 0 | accountId, telecallerId, status (Connected/Not-Connected) |
| | | | durationSec, nextFollowupAt, followupNotes |

### Communication
| Table | Purpose | Records | Key Fields |
|-------|---------|---------|-----------|
| Notification | System alerts | 0 | title, message, type, targetRole/targetUserId |

### Business Configuration
| Table | Purpose | Records | Details |
|-------|---------|---------|---------|
| BusinessType | Types | 10 | Retail, Wholesale, Manufacturing, IT, Healthcare, Education, Finance, Real Estate, Hospitality, Logistics |

---

## SECTION 2: E-COMMERCE & ORDERS (20+ tables)

### Product Catalog
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| product | Products | product_id, name, category, HSN code, tax% |
| product_photos | Product images | product_id, image_name, img_last_updated |
| categories | Category tree | cat_id, name, parent_cat_id, type (subcategories/products) |
| brand | Brands | brand_id, name |
| units_master | Units | unit_id, unit_name |
| hsn_codes | GST/HSN mapping | hsn_id, code, gst_percent |

### Pricing & Taxes
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| supplier_products | Supplier pricing | supplier_product_id, product_id, supplier_id, cost |
| product_taxes | Product tax rules | product_id, tax_type, tax_rate |
| taxes | Tax structure | tax_id, tax_name, tax_percent |
| promo | Promotional offers | promo_id, name, discount%, validity |
| promo_log | Promo usage | promo_id, user_id, order_id, discount_applied |
| offer_log | Offer tracking | offer_id, applied_at |
| offers | Offer definitions | offer_id, type, discount% |

### Orders & Transactions
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| orders | Master orders | order_id, userid, status, total_amount |
| orders_item | Order items | order_item_id, order_id, product_id, quantity, price |
| master_orders | Bulk orders | master_order_id, details |
| sales_invoices | Sales invoices | invoice_id, order_id, amount, GST |
| order_zone_overrides | Zone exceptions | order_id, override_zone |

### Stock & Inventory
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| physical_stock | Current stock | product_id, quantity_on_hand |
| daily_book_stock | Daily closing | vendor_product_id, date, closing_stock |
| stock_count | Stock audit | stock_count_id, product_id, counted_qty |
| stock_audit_log | Audit history | log_id, stock_count_id, variance |
| stock_notify | Low stock alerts | product_id, min_quantity, notification_sent |
| stock_voucher | Stock adjustments | voucher_id, type (In/Out), total_value |
| stock_voucher_items | Voucher details | voucher_item_id, voucher_id, product_id, quantity |

### Suppliers & Purchasing
| Table | Purpose | Records | Key Fields |
|-------|---------|---------|-----------|
| suppliers | Vendor master | ? | supplier_id, name, contact, GST, location |
| purchase_orders | PO documents | ? | po_id, supplier_id, order_date, total_amount |
| purchase_order_items | PO items | ? | po_item_id, po_id, product_id, quantity, rate |
| purchase_vouchers | Purchase invoices | ? | voucher_id, supplier_id, total_value, GST |
| purchase_voucher_items | Voucher details | ? | voucher_item_id, product_id, quantity, rate |
| purchase_returns | Return documents | ? | return_id, voucher_id, reason |
| purchase_return_items | Returned items | ? | return_item_id, product_id, qty |
| product_purchase | Purchase history | ? | product_id, supplier_id, quantity, cost |

### Deals & Inventory Operations
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| inventory_op | Inventory movements | product_id, operation_type, quantity |

### Carts
| Table | Purpose | Key Fields | Note |
|-------|---------|-----------|------|
| cart | Shopping carts | userid, product_id, quantity, total | Multiple addresses |
| cart_type | Cart categories | cart_tid, type_name, ctype_id, delivery_charge | 4 types configured |

### Search Optimization
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| search | Search index | product_id, search_keywords |

### Time Slots
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| time_slots | Delivery slots | slot_id, start_time, end_time |
| timing_slot_groups | Slot grouping | group_id, name |
| timing_slot_group_categories | Group-Category link | group_id, category_id |

### Users (B2C)
| Table | Purpose | Records | Key Fields |
|-------|---------|---------|-----------|
| users | Customers | ? | user_id, name, email, phone |
| user_addresses | Delivery addresses | ? | user_id, address, city, pincode |

---

## SECTION 3: MANUFACTURING & BOM (8 tables)

### Bill of Materials
| Table | Purpose | Key Fields | Status |
|-------|---------|-----------|--------|
| bom_master | BOM versions | product_id, bom_version, status (DRAFT/APPROVED/LOCKED) | 3 records |
| bom_items | BOM components | bom_id, raw_material_id, quantity, unit_type | 6 records |

### Manufacturing Operations
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| issue_to_production | Material issues | product_id, quantity_issued, issued_at |
| issue_to_production_items | Issue details | issue_id, item_id, quantity |
| receive_from_production | Production receipts | product_id, quantity_produced, produced_at |
| receive_from_production_items | Receipt details | receipt_id, item_id, quantity |

---

## SECTION 4: FLEET & DELIVERY MANAGEMENT (8 tables)

### Trip Management
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| trips | Trip records | trip_id, driver_id, start_date, end_date, status |
| trip_cards | Trip assignments | trip_card_id, trip_id, order_assignment |
| trip_card_pincode | Pincode coverage | trip_card_id, pincode |
| trip_audit_log | Trip history | trip_id, event, timestamp |

### Driver Accountability
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| driver_rating | Driver ratings | driver_id, rating (1-5), feedback |
| driver_accountability_log | Driver audit | driver_id, event, timestamp, notes |

---

## SECTION 5: SYSTEM & INFRASTRUCTURE (20+ tables)

### User Management
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| user | Admin/Staff | user_id, username, email, password_hash |
| admin | Admin accounts | userid, username, org_name, delivery_manage_by |
| roles | Role definitions | role_id, role_name |
| calling_staff | Telecaller teams | id, name, contact_no, type |
| deli_staff | Delivery staff | (structure: name, contact) |

### Sessions & Authorization
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| sessions | Active sessions | session_id, user_id, ip_address, expires_at |
| password_reset_tokens | Reset tokens | token, user_id, expires_at |
| otp | OTP management | otp, user_email, created_at, expires_at |

### Cache & Performance
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| cache | Query cache | key, value, expiration timestamp |
| cache_locks | Cache locks | key, owner, expiration |

### Background Jobs
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| jobs | Job queue | job_id, queue, payload, status |
| job_batches | Batch processing | batch_id, name, total_jobs |
| failed_jobs | Failed tasks | job_id, payload, error, failed_at |

### Database Maintenance
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| migrations | Laravel migrations | id, migration, batch |
| _prisma_migrations | Prisma migrations | id, migration_name, status, checksum |

### Stock Count Sessions
| Table | Purpose | Key Fields |
|-------|---------|-----------|
| stock_count_master_session | Audit sessions | session_id, start_date, end_date, status |
| stock_count_assignments | Assignment records | assignment_id, session_id, staff_id |

---

## Database Statistics

### Data Distribution
- **CRM Tables:** 31 tables (23,000+ records in LeadsAccount_crm, 31 employees)
- **E-Commerce Tables:** 20+ tables (Extensive product catalog with 300K+ categories)
- **Manufacturing:** 8 tables (3 BOMs defined)
- **Fleet Management:** 8 tables
- **System Tables:** 20+ tables

### Key Volumes
- **LeadsAccount_crm:** 58 accounts
- **LoginUser_crm:** 31 employees (5 roles)
- **SalaryInformation:** 30 salary records
- **WeeklyAccountAssignment:** 2 assignments
- **categories:** 300K+ product categories
- **product:** Large catalog
- **suppliers:** Multiple suppliers configured
- **orders:** Order history tracked

---

## Design Patterns

### 1. Geographic Hierarchy
**Purpose:** Multi-level location management  
**Tables:** Country → State → Region → District → City → Area/Zone  
**Use:** Account assignments by pincode, area-based planning

### 2. Approval Workflow
**Tables:** Leave, Expense, LeadsAccount_crm (isApproved)  
**Pattern:** status=(PENDING|APPROVED|REJECTED), approvedBy, approvedAt  
**Use:** HR approvals, account verification

### 3. Time-Series Data  
**Tables:** Attendance, SalesmanTrackingPoint, BeatCompletion  
**Key Fields:** recordedAt, date, timestamp (with GPS coordinates)  
**Use:** Historical tracking, analytics

### 4. Assignment Planning
**Tables:** WeeklyBeatPlan → DailyBeatPlan → WeeklyAccountAssignment  
**Hierarchy:** Week → Day → Accounts  
**Use:** Salesman work scheduling

### 5. Flexible JSON Storage
**Tables:** AreaAssignment, EmployeeArea, LeadsAccount_crm  
**Fields:** areas (JSON array), businessTypes (JSON array)  
**Use:** Multi-select values without additional junction tables

### 6. Master-Detail Pattern
**Tables:** orders + orders_item, purchase_orders + purchase_order_items  
**Use:** Complex transactional records

### 7. Audit Trail
**Tables:** trip_audit_log, stock_audit_log, driver_accountability_log  
**Pattern:** entity_id, event, timestamp, user_id  
**Use:** Compliance, history tracking

### 8. Stock Management
**Pattern:** physical_stock (current) ← stock_voucher (adjustments) ← purchase/sales  
**Use:** Inventory reconciliation

---

## Foreign Key Relationships

### CRM Core
```
LoginUser_crm ← LeadsAccount_crm.createdById (Creator)
LoginUser_crm ← LeadsAccount_crm.approvedById (Approver)
LeadsAccount_crm ← WeeklyAccountAssignment (Accounts assigned)
LoginUserRoles_crm ← LoginUser_crm (Role assignment)
department_crm ← LoginUser_crm (Department)
```

### Beat Planning
```
LoginUser_crm ← WeeklyBeatPlan (Salesman)
WeeklyBeatPlan ← DailyBeatPlan (Weekly breakdown)
DailyBeatPlan ← BeatCompletion (Execution)
LoginUser_crm ← BeatCompletion.verifiedBy (Manager)
```

### Approval Chain
```
LoginUser_crm ← LatePunchApproval.approvedBy
LoginUser_crm ← EarlyPunchOutApproval.approvedBy
LoginUser_crm ← Leave.approvedBy
LoginUser_crm ← Expense.approvedBy
```

---

## Security Notes

1. **Password Handling:** Stored as hashes in LoginUser_crm, users, admin tables
2. **OTP Management:** otp table with expiration timestamp
3. **Session Tracking:** sessions table monitors active users
4. **Approval Workflows:** Multi-level verification in Leave, Expense, Accounts
5. **Audit Logs:** trip_audit_log, stock_audit_log for compliance

---

## Index Strategy

**High-Traffic Tables (Indexed):**
- LeadsAccount_crm: (pincode, businessType, customerStage, createdAt)
- Attendance: (employeeId, date, punchInTime)
- LatePunchApproval: (employeeId, status, requestDate)
- SalesmanTrackingPoint: (employeeId, attendanceId, recordedAt)
- TelecallerCallLog: (telecallerId, calledAt, status)
- WeeklyBeatPlan: (salesmanId, weekStartDate, status)

**Key Composite Indexes:**
- WeeklyBeatPlan: (salesmanId, weekStartDate)
- SalesmanTrackingPoint: (employeeId, attendanceId, recordedAt)
- BeatCompletion: (salesmanId, completedAt)

---

## Recommendations

1. **Cleanup:** Many tables have 0 records (Area, City, Country, State, District, Region, Zone) - define default hierarchy
2. **Optimization:** Add indexes on frequently queried columns(pincode, status, createdAt)
3. **Archival:** Plan for historical data cleanup (old attendance, tracking points)
4. **Consistency:** Align date/time handling (some use datetime(3), others use timestamp)
5. **Documentation:** Maintain table relationships as schema grows

