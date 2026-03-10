# microservice (Generic Helm Chart)

A single, reusable Helm chart for deploying any Python microservice on EKS.
Each service is deployed independently using its own values file.

## Structure

```
microservice/
├── Chart.yaml
├── values.yaml                   # Base defaults (generic)
├── values.email-checker.yaml     # email-checker overrides
├── values.queue-checker.yaml     # queue-checker overrides
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml              # Only rendered if ingress.enabled=true
    ├── hpa.yaml                  # Only rendered if hpa.enabled=true
    └── rbac.yaml                 # ServiceAccount + Role + RoleBinding
```

## Prerequisites

- EKS cluster with **AWS Load Balancer Controller** (required for ALB ingress)
- `metrics-server` installed (required for HPA)
- ECR images pushed for each service

## Fill in before deploying

In each `values.<service>.yaml`:

| Placeholder | Description |
|---|---|
| `<AWS_ACCOUNT_ID>` | Your AWS account ID |
| `<AWS_REGION>` | e.g. `us-east-1` |
| `<ACM_CERT_ARN>` | ACM certificate ARN for HTTPS (email-checker) |
| `eks.amazonaws.com/role-arn` | IRSA role ARN for AWS API access (optional) |

## Deploy each service

```bash
# email-checker (internet-facing, ALB)
helm upgrade --install email-checker ./microservice \
  -f values.email-checker.yaml \
  -n my-namespace --create-namespace

# queue-checker (internal, ClusterIP)
helm upgrade --install queue-checker ./microservice \
  -f values.queue-checker.yaml \
  -n my-namespace --create-namespace
```

## Adding a new microservice

1. Copy `values.queue-checker.yaml` → `values.my-new-service.yaml`
2. Update `name`, `image.repository`, and any relevant fields
3. Deploy:
```bash
helm upgrade --install my-new-service ./microservice \
  -f values.my-new-service.yaml \
  -n my-namespace
```

## Useful commands

```bash
# Lint
helm lint ./microservice -f values.email-checker.yaml

# Dry-run / debug
helm upgrade --install email-checker ./microservice \
  -f values.email-checker.yaml \
  -n my-namespace --dry-run --debug

# Uninstall
helm uninstall email-checker -n my-namespace
helm uninstall queue-checker -n my-namespace
```
