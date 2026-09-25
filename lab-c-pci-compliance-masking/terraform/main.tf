
provider "aws" { region = var.region }
resource "aws_vpc" "main" { cidr_block="10.2.0.0/16" tags={Name="lab-c-vpc"} }
resource "aws_subnet" "private_a" { vpc_id=aws_vpc.main.id cidr_block="10.2.2.0/24" availability_zone="${var.region}a" }
resource "aws_subnet" "private_b" { vpc_id=aws_vpc.main.id cidr_block="10.2.3.0/24" availability_zone="${var.region}b" }
resource "aws_kms_key" "rds" { description="Lab C CMK" enable_key_rotation=true }
resource "aws_kms_alias" "rds" { name="alias/rds/lab-c-secure" target_key_id=aws_kms_key.rds.id }
resource "aws_security_group" "db" { vpc_id=aws_vpc.main.id name="lab-c-db-sg" ingress { from_port=5432 to_port=5432 protocol="tcp" cidr_blocks=["10.2.0.0/16"] } egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] } }
resource "aws_db_subnet_group" "main" { name="lab-c-subnet-group" subnet_ids=[aws_subnet.private_a.id, aws_subnet.private_b.id] }
resource "aws_rds_cluster" "aurora" { cluster_identifier="lab-c-aurora" engine="aurora-postgresql" engine_version="15.4" master_username="dbadmin" master_password=var.db_password database_name="labcdb" db_subnet_group_name=aws_db_subnet_group.main.name vpc_security_group_ids=[aws_security_group.db.id] storage_encrypted=true kms_key_id=aws_kms_key.rds.id skip_final_snapshot=true }
resource "aws_rds_cluster_instance" "inst" { count=1 identifier="lab-c-aurora-0" cluster_identifier=aws_rds_cluster.aurora.id instance_class="db.t3.medium" engine=aws_rds_cluster.aurora.engine publicly_accessible=false }

resource "aws_s3_bucket" "snapshot_export" { bucket="lab-c-snapshot-export-${random_id.s.hex}" }
resource "random_id" "s" { byte_length=4 }
resource "aws_macie2_account" "main" { finding_publishing_frequency="FIFTEEN_MINUTES" status="ENABLED" }
resource "aws_config_configuration_recorder" "main" { name="lab-c-recorder" role_arn=aws_iam_role.config.arn recording_group { all_supported=true } }
resource "aws_iam_role" "config" { name="lab-c-config-role" assume_role_policy=jsonencode({Version="2012-10-17", Statement=[{Effect="Allow", Principal={Service="config.amazonaws.com"}, Action="sts:AssumeRole"}]}) }
resource "aws_iam_role_policy_attachment" "config" { role=aws_iam_role.config.name policy_arn="arn:aws:iam::aws:policy/service-role/AWSConfigRole" }
resource "aws_config_config_rule" "encrypted" { name="lab-c-rds-storage-encrypted" source { owner="AWS" source_identifier="RDS_STORAGE_ENCRYPTED" } }
resource "aws_config_config_rule" "no_public_snapshot" { name="lab-c-rds-snapshot-public-prohibited" source { owner="AWS" source_identifier="RDS_SNAPSHOTS_PUBLIC_PROHIBITED" } }

output "aurora_endpoint" { value=aws_rds_cluster.aurora.endpoint }
output "s3_export_bucket" { value=aws_s3_bucket.snapshot_export.id }
