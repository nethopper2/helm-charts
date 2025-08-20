# JuiceFS S3 Gateway - Volume-Based Authentication

This chart uses **volume-based authentication** for both S3 and GCS storage backends. Credentials are provided via mounted Kubernetes secrets rather than environment variables or inline configuration.

## S3 Authentication

### Requirements
- AWS credentials file mounted to `/root/.aws/`
- Must contain both `credentials` and `config` files

### Setup

1. **Create AWS credentials secret:**
```bash
kubectl create secret generic aws-credentials \
  --from-literal=credentials="[default]
aws_access_key_id = AKIA123456789EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" \
  --from-literal=config="[default]
region = us-west-2"
```

2. **Configure values.yaml:**
```yaml
secret:
  create: true
  config:
    name: "myjuicefs-s3"
    storage: "s3"
    bucket: "my-s3-bucket"
    metaurl: "redis://redis:6379/0"

extraVolumeMounts:
  - name: aws-credentials
    mountPath: /root/.aws
    readOnly: true

extraVolumes:
  - name: aws-credentials
    secret:
      secretName: aws-credentials
      items:
        - key: credentials
          path: credentials
        - key: config
          path: config
```

### Alternative: IAM Roles for Service Accounts (IRSA)
For AWS EKS, you can use IRSA instead of static credentials:

```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/JuiceFSS3Role

# No extraVolumes needed - authentication via service account
```

## GCS Authentication

### Requirements
- Service account key mounted to `/var/secrets/google/`
- `GOOGLE_APPLICATION_CREDENTIALS` environment variable pointing to the key file

### Setup

1. **Create GCS service account secret:**
```bash
kubectl create secret generic gcs-service-account-key \
  --from-file=key.json=/path/to/service-account-key.json
```

2. **Configure values.yaml:**
```yaml
secret:
  create: true
  config:
    name: "myjuicefs-gcs"
    storage: "gs"
    bucket: "gs://my-gcs-bucket"
    metaurl: "redis://redis:6379/0"

initEnvs:
  - name: GOOGLE_APPLICATION_CREDENTIALS
    value: /var/secrets/google/key.json

envs:
  - name: GOOGLE_APPLICATION_CREDENTIALS
    value: /var/secrets/google/key.json

extraVolumeMounts:
  - name: gcs-service-account
    mountPath: /var/secrets/google
    readOnly: true

extraVolumes:
  - name: gcs-service-account
    secret:
      secretName: gcs-service-account-key
```

### Alternative: Workload Identity
For GKE, you can use Workload Identity instead of service account keys:

```yaml
serviceAccount:
  create: true
  annotations:
    iam.gke.io/gcp-service-account: juicefs@PROJECT-ID.iam.gserviceaccount.com

# No extraVolumes needed - authentication via workload identity
```

## Security Benefits

✅ **No Inline Credentials** - Secrets are never stored in values files  
✅ **Kubernetes Secret Management** - Leverages native K8s secret encryption  
✅ **Read-Only Mounts** - Credential files mounted as read-only  
✅ **Standard Auth Patterns** - Uses standard AWS/GCP authentication mechanisms  
✅ **Rotation Support** - Easy credential rotation via secret updates  

## Troubleshooting

### S3 Authentication Issues
- Verify AWS credentials secret exists: `kubectl get secret aws-credentials`
- Check mount path: `kubectl exec -it <pod> -- ls -la /root/.aws/`
- Test AWS CLI: `kubectl exec -it <pod> -- aws s3 ls`

### GCS Authentication Issues
- Verify service account secret exists: `kubectl get secret gcs-service-account-key`
- Check environment variable: `kubectl exec -it <pod> -- env | grep GOOGLE_APPLICATION_CREDENTIALS`
- Check mount path: `kubectl exec -it <pod> -- ls -la /var/secrets/google/`
- Test gcloud: `kubectl exec -it <pod> -- gcloud auth application-default print-access-token`