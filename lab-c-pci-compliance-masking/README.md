# Lab C - Vault & Veil (STANDALONE)
Deploys: VPC, KMS, Aurora PostgreSQL, S3 bucket for snapshot exports, Macie account + classification job, Config Rules (encrypted + no public snapshot), IAM roles for least privilege
Deploy: terraform init && terraform apply
Then: psql -h <aurora-endpoint-from-output> -U dbadmin -d labcdb -f ../sql/rls_and_masking_views.sql
Validation: Connect as analyst -> SELECT from customers_masked shows ****1111. Macie console -> findings.
Independent: YES - no Lab A/B needed.
