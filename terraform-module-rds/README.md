# AWS RDS Global Cluster Module

Terraform module to provision an AWS Aurora RDS environment with support for global clusters spanning multiple AWS regions. Handles ephemeral password generation, Secrets Manager storage, primary and secondary cluster creation, and configurable instance scaling.

---

## Architecture

The module creates the following resources:

| Resource | Description |
|---|---|
| `aws_rds_global_cluster` | Optional Aurora Global Cluster |
| `ephemeral random_password` | Write-only password, never stored in state |
| `aws_secretsmanager_secret` + `aws_secretsmanager_secret_version` | Secure password storage via write-only attributes |
| `aws_rds_cluster` (primary) | Primary Aurora cluster with configurable engine, subnet, and IAM |
| `aws_rds_cluster_instance` (primary) | Count-based primary instances |
| `aws_rds_cluster` (secondary) | Optional secondary cluster in `us-west-1` via provider alias |
| `aws_rds_cluster_instance` (secondary) | Count-based secondary instances, only created when `secondary_cluster_enabled = true` |

---

## Usage

### Basic Example (Standalone Primary Cluster)

```hcl
module "rds" {
  source = "./modules/rds"

  primary_cluster_name          = "my-primary-cluster"
  primary_cluster_instance_name = "my-instance"
  database_username             = "admin"
  cluster_engine                = "aurora-postgresql"
  cluster_engine_version        = "15.4"
  primary_database_subnet       = "my-subnet-group"
}
```

### Global Cluster Example (Multi-Region)

```hcl
module "rds_global" {
  source = "./modules/rds"

  create_global_cluster     = true
  global_cluster_identifier = "my-global-cluster"
  global_engine             = "aurora-postgresql"
  global_engine_version     = "15.4"
  global_database_name      = "mydb"

  primary_cluster_name            = "primary-cluster"
  primary_cluster_instance_name   = "primary-instance"
  primary_instance_count          = 2
  primary_database_subnet         = "primary-subnet-group"

  secondary_cluster_enabled       = true
  secondary_cluster_name          = "secondary-cluster"
  secondary_cluster_instance_name = "secondary-instance"
  secondary_instance_count        = 1
  secondary_database_subnet       = "secondary-subnet-group"

  database_username      = "admin"
  cluster_engine         = "aurora-postgresql"
  cluster_engine_version = "15.4"

  iam_database_authentication_enabled = true
  iam_roles = ["arn:aws:iam::123456789012:role/rds-role"]
}
```

---

## Input Variables

### Global Cluster

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `create_global_cluster` | `bool` | `false` | No | Whether to create an Aurora Global Cluster |
| `global_cluster_identifier` | `string` | `""` | No | Identifier for the global cluster |
| `global_engine` | `string` | `""` | No | Engine type (e.g. `aurora-postgresql`) |
| `global_engine_version` | `string` | `""` | No | Engine version for the global cluster |
| `global_database_name` | `string` | `""` | No | Database name for the global cluster |

### Primary Cluster

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `primary_cluster_name` | `string` | — | Yes | Identifier for the primary RDS cluster |
| `primary_cluster_instance_name` | `string` | — | Yes | Base name for primary instances (index appended) |
| `primary_instance_count` | `number` | `1` | No | Number of primary cluster instances to create |
| `primary_database_subnet` | `string` | — | Yes | DB subnet group name for the primary cluster |
| `cluster_engine` | `string` | — | Yes | Engine when not using a global cluster |
| `cluster_engine_version` | `string` | — | Yes | Engine version when not using a global cluster |
| `database_username` | `string` | — | Yes | Master username for the database |
| `public_access` | `bool` | `false` | No | Whether cluster instances are publicly accessible |

### Secondary Cluster

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `secondary_cluster_enabled` | `bool` | `false` | No | Whether to create a secondary cluster in `us-west-1` |
| `secondary_cluster_name` | `string` | `""` | No | Identifier for the secondary RDS cluster |
| `secondary_cluster_instance_name` | `string` | `""` | No | Base name for secondary instances (index appended) |
| `secondary_instance_count` | `number` | `1` | No | Number of secondary instances — only used when `secondary_cluster_enabled = true` |
| `secondary_database_subnet` | `string` | `""` | No | DB subnet group name for the secondary cluster |

### IAM & Instance

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `iam_database_authentication_enabled` | `bool` | `false` | No | Enable IAM database authentication |
| `iam_roles` | `list(string)` | `[]` | No | List of IAM role ARNs — only used when `iam_database_authentication_enabled = true` |
| `rds_instance_class` | `string` | `"db.t3.medium"` | No | Instance class for cluster instances |

---

## Outputs

| Output | Description |
|---|---|
| `global_cluster_identifier` | ID of the global cluster (`null` if not created) |
| `primary_cluster_endpoint` | Writer endpoint of the primary cluster |
| `secondary_cluster_endpoint` | Writer endpoint of the secondary cluster (`null` if not created) |

---

## Testing

Tests are written using the native [Terraform test framework](https://developer.hashicorp.com/terraform/language/tests) (requires Terraform >= 1.6) and live in the `tests/` directory.

```
your-module/
├── main.tf
├── variables.tf
├── outputs.tf
└── tests/
    ├── primary_only.tftest.hcl
    └── global_cluster.tftest.hcl
```

### Test files

**`tests/primary_only.tftest.hcl`** — validates standalone primary cluster logic using `command = plan` (no real infrastructure created):

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "secondary"
  region = "us-west-1"
}

variables {
  primary_cluster_name          = "test-primary"
  primary_cluster_instance_name = "test-instance"
  database_username             = "admin"
  cluster_engine                = "aurora-postgresql"
  cluster_engine_version        = "15.4"
  primary_database_subnet       = "test-subnet"
  primary_instance_count        = 2
}

run "no_global_cluster_by_default" {
  command = plan

  assert {
    condition     = length(aws_rds_global_cluster.global_cluster) == 0
    error_message = "Global cluster should not be created when create_global_cluster is false"
  }
}

run "primary_instance_count" {
  command = plan

  assert {
    condition     = length(aws_rds_cluster_instance.primary_instance) == 2
    error_message = "Expected 2 primary instances"
  }
}

run "no_secondary_by_default" {
  command = plan

  assert {
    condition     = length(aws_rds_cluster.secondary) == 0
    error_message = "Secondary cluster should not be created when secondary_cluster_enabled is false"
  }
}

run "public_access_disabled_by_default" {
  command = plan

  assert {
    condition     = alltrue([for i in aws_rds_cluster_instance.primary_instance : i.publicly_accessible == false])
    error_message = "Instances should not be publicly accessible by default"
  }
}
```

**`tests/global_cluster.tftest.hcl`** — validates global and secondary cluster logic:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "secondary"
  region = "us-west-1"
}

variables {
  create_global_cluster           = true
  global_cluster_identifier       = "tf-test-global"
  global_engine                   = "aurora-postgresql"
  global_engine_version           = "15.4"
  global_database_name            = "testdb"
  primary_cluster_name            = "tf-test-primary"
  primary_cluster_instance_name   = "tf-test-instance"
  secondary_cluster_enabled       = true
  secondary_cluster_name          = "tf-test-secondary"
  secondary_cluster_instance_name = "tf-test-secondary-instance"
  secondary_database_subnet       = "test-secondary-subnet"
  database_username               = "admin"
  cluster_engine                  = "aurora-postgresql"
  cluster_engine_version          = "15.4"
  primary_database_subnet         = "test-subnet"
  primary_instance_count          = 1
  secondary_instance_count        = 1
}

run "global_cluster_created" {
  command = plan

  assert {
    condition     = length(aws_rds_global_cluster.global_cluster) == 1
    error_message = "Global cluster should be created when create_global_cluster is true"
  }
}

run "primary_uses_global_engine" {
  command = plan

  assert {
    condition     = aws_rds_cluster.primary_cluster.engine == aws_rds_global_cluster.global_cluster[0].engine
    error_message = "Primary cluster engine should match global cluster engine"
  }
}

run "secondary_cluster_created" {
  command = plan

  assert {
    condition     = length(aws_rds_cluster.secondary) == 1
    error_message = "Secondary cluster should be created when secondary_cluster_enabled is true"
  }
}

run "instance_identifiers_are_unique" {
  command = plan

  assert {
    condition     = aws_rds_cluster_instance.primary_instance[0].identifier == "tf-test-instance-0"
    error_message = "Primary instance identifier should be suffixed with count index"
  }
}
```

### Running the tests

```bash
# Run all tests
terraform test

# Run a specific test file
terraform test -filter=tests/primary_only.tftest.hcl

# Run with variable overrides
terraform test -var="primary_instance_count=3"
```

> All tests use `command = plan` — no real AWS infrastructure is created. If you add `command = apply` tests in the future, ensure your AWS credentials are configured and be aware they will provision real resources.

---

## Security Notes

- Passwords are generated using the `ephemeral` `random_password` resource — they are **never written to Terraform state**.
- The generated password is stored in AWS Secrets Manager using `secret_string_wo` (write-only), also keeping it out of state.
- `master_password_wo` and `master_password_wo_version` are used on the RDS cluster, ensuring the password is passed securely at apply time only.
- Optionally enable IAM database authentication via `iam_database_authentication_enabled` to avoid password-based logins entirely.

---

## Requirements

| Requirement | Value |
|---|---|
| Terraform | `>= 1.10` — required for `ephemeral` resources and write-only attributes |
| AWS Provider | `~> 6.38` (`hashicorp/aws`) |
| Secondary Region Provider | Provider alias `aws.secondary` must be configured in the calling module (targets `us-west-1`) |

---

## Additional Notes

- Secondary cluster variables (`secondary_cluster_name`, `secondary_cluster_instance_name`, `secondary_database_subnet`) all default to `""` and are only required when `secondary_cluster_enabled = true`.
- Secondary instances are only created when `secondary_cluster_enabled = true`. Setting `secondary_instance_count` has no effect if the secondary cluster is disabled.
- Instance identifiers are auto-suffixed with the count index (e.g. `primary-instance-0`, `primary-instance-1`) to ensure uniqueness across scaled deployments.
- `lifecycle { create_before_destroy = true }` is set on all resources to minimize downtime during replacements.
- `replication_source_identifier` is ignored on the secondary cluster to prevent perpetual drift after initial replication setup.
