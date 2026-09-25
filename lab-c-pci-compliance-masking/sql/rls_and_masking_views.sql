
CREATE TABLE IF NOT EXISTS customers (id SERIAL PRIMARY KEY, tenant_id INT, full_name TEXT, email TEXT, card_number TEXT);
INSERT INTO customers (tenant_id, full_name, email, card_number) VALUES (1, 'Alice Smith', 'alice@example.com', '4111111111111111') ON CONFLICT DO NOTHING;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation ON customers;
CREATE POLICY tenant_isolation ON customers USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE OR REPLACE VIEW customers_masked AS SELECT id, tenant_id, full_name, CONCAT(LEFT(email,2), '****@', SPLIT_PART(email,'@',2)) as email, CONCAT('****-****-****-', RIGHT(card_number,4)) as card_number FROM customers;
DROP ROLE IF EXISTS analyst_role; CREATE ROLE analyst_role NOLOGIN; GRANT SELECT ON customers_masked TO analyst_role;
REVOKE ALL ON customers FROM analyst_role;
