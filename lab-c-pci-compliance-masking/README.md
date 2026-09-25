<img width="1920" height="1280" alt="image" src="https://github.com/user-attachments/assets/89c420ac-6519-47bf-8432-9d99b411a8f1" />
# Lab C - Vault & Veil - PCI-DSS Compliance & PII Masking

Deploys: VPC, KMS, Aurora PostgreSQL, S3 bucket for snapshot exports, Macie account + classification job, Config Rules (encrypted + no public snapshot), IAM roles for least privilege

Deploy: terraform init && terraform apply
T
hen: psql -h <aurora-endpoint-from-output> -U dbadmin -d labcdb -f ../sql/rls_and_masking_views.sql

Validation: Connect as analyst -> SELECT from customers_masked shows ****1111. Macie console -> findings.

Independent: YES - no Lab A/B needed.

ISSUE : I am securing RDS for a Walford-based payments processor that stores PANs and emails. Must pass PCI-DSS Req 3,7,10 and ensure support analysts cannot see full card numbers.


Design & Plan:

    Discovery: Enable Amazon Macie to scan RDS snapshots exported to S3. Macie finds PAN, SSN, Email -> pushes finding to Security Hub.
    Access Control: Implement PostgreSQL Row Level Security (RLS) + 2 IAM Roles: app_role (read/write own tenant), analyst_role (read-only masked view).
    Data Masking: Create masked views:
SQL

CREATE VIEW customers_masked AS
SELECT id, 
       CONCAT('****', RIGHT(card_number,4)) as card_number,
       CONCAT(LEFT(email,2), '****@', SPLIT_PART(email,'@',2)) as email
FROM customers;

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON customers USING (tenant_id = current_user_id());


    Compliance Automation: AWS Config Rules: rds-storage-encrypted, rds-snapshot-public-prohibited. AWS Audit Manager PCI-DSS framework collects evidence automatically to S3.
    Rotation: Same as Lab A - 30-day rotation mandatory for PCI.

Execution Steps:

    Create dummy PII data in RDS.
    Create snapshot -> export to S3 -> Macie job -> screenshot finding.
    Deploy rls_and_masking_views.sql.
    Test: connect as analyst_role -> SELECT * FROM customers_masked shows masked data. Direct table access denied.
    Enable Audit Manager assessment, show report.

 Before/after query screenshots, Macie findings JSON, Audit Manager compliance score to be attached.

Output/Solution: Implemented PCI-DSS controls for RDS including Macie PII discovery, PostgreSQL RLS and dynamic data masking views, and Audit Manager automated evidence collection, ensuring least-privilege access for non-admin roles.

