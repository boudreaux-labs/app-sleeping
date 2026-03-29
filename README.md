# app-sleeping

Sleeping page for [sleeping.boudreauxlabs.com](https://sleeping.boudreauxlabs.com) — served when the Boudreaux Labs EKS cluster is torn down between sessions.

## What it is

A React static site hosted on S3 + CloudFront. When the ephemeral EKS cluster is offline, this page is up instead of nothing. The cluster is routinely destroyed at the end of each working session to keep costs near zero.

## Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React + Vite |
| Hosting | AWS S3 |
| CDN | AWS CloudFront + OAC |
| DNS | Route53 alias → CloudFront |
| TLS | ACM certificate |
| IaC | Terraform |
| CI/CD | GitHub Actions + OIDC → AWS |

## Pipelines

### `infra` — triggered on `terraform/**` changes
`validate` → `plan` → `apply` (manual gate)

Provisions S3, CloudFront, Route53, IAM deploy role, and SSM parameters. Automatically triggers the deploy pipeline on success.

### `deploy` — triggered on app source changes or after infra
Builds the React app with Vite, syncs to S3, and invalidates the CloudFront cache. Reads bucket name and distribution ID from SSM at runtime — no static configuration needed.

## Infrastructure

All infrastructure is app-owned and lives in `terraform/`. State is stored in S3 (`boudreaux-labs-terraform-state`).

The deploy pipeline authenticates to AWS via GitHub OIDC — no static credentials anywhere.
