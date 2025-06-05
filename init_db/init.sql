-- PostgreSQL Schema for School Accounting System (IRD Nepal Compliant, Updated)

-- 1. Users Table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) CHECK (role IN ('admin', 'accountant', 'auditor', 'ird_verifier')) NOT NULL, 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Invoices Table
CREATE TABLE invoices (
    id SERIAL PRIMARY KEY,
    fiscal_year VARCHAR(10) NOT NULL,
    bill_number VARCHAR(30) UNIQUE NOT NULL,
    customer_name VARCHAR(100),
    customer_pan VARCHAR(20),
    bill_date DATE NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    vat_amount NUMERIC(12,2) NOT NULL, 
    taxable_amount NUMERIC(12,2) NOT NULL, 
    qr_code TEXT, 
    ird_sync_status VARCHAR(20) CHECK (ird_sync_status IN ('pending', 'synced', 'failed')) DEFAULT 'pending', 
    print_status BOOLEAN DEFAULT FALSE,
    entered_by INTEGER REFERENCES users(id) ON DELETE RESTRICT, 
    payment_method VARCHAR(30) CHECK (payment_method IN ('cash', 'bank', 'digital_payment')), 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_invoices_bill_number ON invoices(bill_number); 
CREATE INDEX idx_invoices_fiscal_year ON invoices(fiscal_year); 

-- 3. Expenses Table
CREATE TABLE expenses (
    id SERIAL PRIMARY KEY,
    category VARCHAR(50) NOT NULL, 
    amount NUMERIC(12,2) NOT NULL,
    expense_date DATE NOT NULL,
    notes TEXT,
    entered_by INTEGER REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Income Table
CREATE TABLE income (
    id SERIAL PRIMARY KEY,
    source VARCHAR(100) NOT NULL, 
    amount NUMERIC(12,2) NOT NULL,
    income_date DATE NOT NULL,
    reference TEXT,
    bank_transaction_id INTEGER REFERENCES bank_transactions(id), 
    entered_by INTEGER REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Bank Transactions Table (New)
CREATE TABLE bank_transactions (
    id SERIAL PRIMARY KEY,
    bank_name VARCHAR(100) NOT NULL,
    transaction_id VARCHAR(50) UNIQUE NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    transaction_date DATE NOT NULL,
    reference TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Recurring Expenses Table (New)
CREATE TABLE recurring_expenses (
    id SERIAL PRIMARY KEY,
    expense_id INTEGER REFERENCES expenses(id) ON DELETE CASCADE,
    frequency VARCHAR(20) CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly')) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Ledger Accounts Table
CREATE TABLE ledger_accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL, 
    type VARCHAR(20) CHECK (type IN ('asset', 'liability', 'equity', 'income', 'expense')) NOT NULL, 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Journal Entries Table
CREATE TABLE journal_entries (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    entry_date DATE NOT NULL,
    entered_by INTEGER REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_journal_entries_entry_date ON journal_entries(entry_date); 

-- 9. Journal Lines Table
CREATE TABLE journal_lines (
    id SERIAL PRIMARY KEY,
    journal_entry_id INTEGER REFERENCES journal_entries(id) ON DELETE CASCADE,
    ledger_account_id INTEGER REFERENCES ledger_accounts(id) ON DELETE RESTRICT,
    debit NUMERIC(12,2) DEFAULT 0,
    credit NUMERIC(12,2) DEFAULT 0,
    CONSTRAINT check_debit_credit CHECK (debit > 0 OR credit > 0) 
);

-- 10. CBMS Sync Log
CREATE TABLE cbms_sync_log (
    id SERIAL PRIMARY KEY,
    invoice_id INTEGER REFERENCES invoices(id) ON DELETE CASCADE,
    sync_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status TEXT NOT NULL, -
    response TEXT,
    hash TEXT 
);

-- 11. Audit Logs
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE RESTRICT,
    action TEXT NOT NULL, -- Renamed 'actions' to 'action'
    table_name TEXT NOT NULL, -- Made NOT NULL for clarity
    record_id INTEGER,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address TEXT,
    hash TEXT 
);
CREATE INDEX idx_audit_logs_table_name ON audit_logs(table_name); 

-- 12. Reports Metadata
CREATE TABLE reports_metadata (
    id SERIAL PRIMARY KEY,
    report_name VARCHAR(100) NOT NULL, -- Added NOT NULL
    generated_by INTEGER REFERENCES users(id) ON DELETE RESTRICT,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    format VARCHAR(10) CHECK (format IN ('pdf', 'xls', 'xml')) NOT NULL 

);

-- 13. API Tokens Table 
CREATE TABLE api_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    purpose VARCHAR(50) NOT NULL, 
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Trigger to Ensure Immutable Timestamps
CREATE OR REPLACE FUNCTION prevent_timestamp_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.created_at IS DISTINCT FROM NEW.created_at THEN
        RAISE EXCEPTION 'Cannot update created_at timestamp';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER immutable_created_at_users
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION prevent_timestamp_update();

CREATE TRIGGER immutable_created_at_invoices
BEFORE UPDATE ON invoices
FOR EACH ROW EXECUTE FUNCTION prevent_timestamp_update();

-- Add similar triggers for other tables as needed