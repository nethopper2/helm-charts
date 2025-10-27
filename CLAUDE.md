# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Helm charts repository for Nethopper, containing multiple Kubernetes application deployments. Each chart follows standard Helm conventions and is structured as an independent application chart.

## Chart Structure and Conventions

### Standard Chart Components
- `Chart.yaml` - Chart metadata with semantic versioning
- `values.yaml` - Default configuration values
- `templates/` - Kubernetes manifest templates
- `templates/_helpers.tpl` - Template helper functions using standard patterns
- `templates/tests/` - Helm test templates for connection testing

### Common Template Patterns
- All charts use standard Helm helper templates for name generation, labels, and selectors
- Labels follow Kubernetes recommended conventions with `app.kubernetes.io/*` prefixes
- Resource naming uses `{{- include "chart.fullname" . }}` pattern
- Common Kubernetes resources include: Deployment, Service, Ingress, ServiceAccount, HPA

## Available Charts

### Production Charts
- **juicefs-s3-gateway** (v0.1.4) - JuiceFS S3 Gateway for distributed file system access
- **ragflow** (v0.1.0) - RAGFlow deployment with multiple data services
- **nh-rag** (v0.1.1) - Nethopper RAG application
- **nh-frontend** - Frontend application
- **log-bundle** - Logging stack (Loki, Promtail)
- **gdrive-gcs-sync** - Google Drive to GCS synchronization
- **private-ai-rest** - Private AI REST API service

### Development Charts
- **example** - Template/example chart for development reference

## Common Development Commands

### Chart Development
```bash
# Create a new chart 
helm create <chart-name>

# Validate chart syntax
helm lint charts/<chart-name>

# Test chart rendering
helm template <release-name> charts/<chart-name>

# Test with custom values
helm template <release-name> charts/<chart-name> -f charts/<chart-name>/test-values.yaml

# Package chart
helm package charts/<chart-name>

# Install chart locally
helm install <release-name> charts/<chart-name>

# Upgrade chart
helm upgrade <release-name> charts/<chart-name>

# Run chart tests
helm test <release-name>
```

### Repository Management
```bash
# Add repository
helm repo add nh-charts https://nethopper2.github.io/helm-charts/

# Update repository index
helm repo update

# Search charts
helm search repo nh-charts
```

## Chart-Specific Notes

### juicefs-s3-gateway
- Requires secret configuration for JuiceFS filesystem access
- Supports both Community Edition (CE) and Enterprise Edition (EE)
- Uses init containers for filesystem formatting
- Configurable resource limits (default: 5000m CPU, 5Gi memory)

### ragflow
- Complex multi-service deployment including Elasticsearch/OpenSearch, MySQL, Redis, MinIO
- Requires careful configuration of data persistence and service dependencies

### Values Files
- Most charts include `test-values.yaml` for development/testing
- Production deployments should use custom values files
- Secret values should never be committed to the repository

## Requirements
- Kubernetes 1.22+
- Helm 3.0+

## Security Considerations
- All secret values should be provided via external secret management
- Charts follow Kubernetes security best practices for service accounts and RBAC
- Network policies and pod security contexts should be configured per environment