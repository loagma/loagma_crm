## MySQL Schema Setup with Prisma

This project now uses **MySQL** as the primary database for Prisma (see `backend/prisma/schema.prisma` and `backend/.env`).

### 1. Prepare a MySQL database

1. Install MySQL 8+ (or a compatible MySQL service such as TiDB) and create an empty database, for example:
   - Database name: `loagma_crm`
   - Host: `localhost`
   - Port: `3306`
   - User: `user`
   - Password: `password`

2. Update `backend/.env`:
   - Set `DATABASE_URL` to your MySQL connection string, for example:

   ```env
   DATABASE_URL="mysql://user:password@localhost:3306/loagma_crm"
   ```

### 2. Generate Prisma client

From the `backend` directory:

```bash
npm install
npm run db:generate
```

This will generate a MySQL-compatible Prisma client in `node_modules/@prisma/client`.

### 3. Create the schema on MySQL

Because the existing migration history in `backend/prisma/migrations` was generated for **PostgreSQL**, it should **not** be applied to MySQL. Instead, use Prisma to create the schema directly from `schema.prisma`:

```bash
cd backend
npm run db:migrate    # runs: prisma db push
```

This will:

- Connect to the MySQL database defined by `DATABASE_URL`.
- Create all tables, indexes, and foreign keys defined in `schema.prisma`.

> **Note:** Do **not** use `npm run db:reset` or `prisma migrate deploy` against MySQL with the current migrations folder, as those SQL files contain PostgreSQL-specific SQL (quoted identifiers, etc.).

### 4. Verifying the schema

After `npm run db:migrate` completes, you can:

- Connect to MySQL (e.g., `mysql` CLI, TablePlus, DBeaver) and verify that tables such as `User`, `Account`, `Attendance`, `WeeklyBeatPlan`, `DailyBeatPlan`, `Notification`, `Leave`, etc. exist.
- Optionally run:

```bash
npx prisma studio
```

to visually inspect tables and relations.

### 5. Smoke test critical flows

After the schema is created and `DATABASE_URL` points to your MySQL database, smoke test:

- Login and OTP flows.
- Account creation and updates.
- Attendance punch in/out and live tracking.
- Beat planning (weekly/daily), completion, and verification.
- Leave requests/approvals and expense flows.

