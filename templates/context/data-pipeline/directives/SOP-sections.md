
## 10. Schema Validation

- All data ingestion points must validate against a defined schema
- Use schema versioning — never silently change field types
- Reject malformed records with clear error messages (don't silently drop)
- Schema definitions should be co-located with the code that uses them
- Support schema evolution (adding optional fields, deprecating old ones)

## 11. Orchestration

- Use a DAG-based orchestrator (Airflow, Dagster, Prefect, or equivalent)
- Every task/step must be independently retriable
- Set appropriate timeouts for each pipeline stage
- Use backfill-friendly designs — pipelines should support date-range reruns
- Alert on pipeline failures and SLA breaches

## 12. Idempotency & Data Quality

- All pipeline stages must be idempotent — rerunning produces the same result
- Use upsert patterns instead of insert-only for dimension tables
- Implement data quality checks at pipeline boundaries (row counts, null rates, value ranges)
- Partition data by time where possible for efficient reprocessing
- Log record counts at each stage boundary for reconciliation

## 13. Credentials & Configuration

- All database credentials, API keys, and connection strings come from environment variables
- Use a secrets manager in production (Vault, AWS Secrets Manager, etc.)
- Never log full connection strings or credentials
- Configuration should support per-environment overrides (dev, staging, prod)
