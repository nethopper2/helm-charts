# juicefs-s3-gateway

![Version: 0.11.1](https://img.shields.io/badge/Version-0.11.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.6.0](https://img.shields.io/badge/AppVersion-1.6.0-informational?style=flat-square)

A Helm chart for JuiceFS S3 Gateway

**Homepage:** <https://github.com/juicedata/juicefs>

## Gateway Configuration Sidecar

This chart includes an optional sidecar container that can automatically configure the JuiceFS S3 Gateway after deployment. The sidecar uses MinIO Client (mc) to execute configuration commands once the gateway becomes ready.

### Key Features

- **Automatic Readiness Detection**: The sidecar waits for the gateway to be healthy before executing commands
- **Configurable Commands**: Define custom mc commands via values to configure webhook notifications, events, and more
- **Exit After Completion**: By default, the sidecar exits after successful configuration (can be changed for debugging)
- **Resource Efficient**: Uses minimal CPU and memory resources

### Usage

Enable the sidecar by setting `sidecar.enabled: true` in your values:

```yaml
sidecar:
  enabled: true
  webhookEndpoint: "http://webhook-service:3000"
  mcCommands:
    - mc alias set jfs ${GATEWAY_ENDPOINT} ${ACCESS_KEY} ${SECRET_KEY}
    - mc admin config set jfs notify_webhook:1 queue_limit="0" endpoint="${WEBHOOK_ENDPOINT}" queue_dir="/juicefs-queue"
    - mc event add jfs/${BUCKET_NAME} arn:minio:sqs::1:webhook --event put,delete
```

### Available Environment Variables

The following variables are available in command templates:

- `GATEWAY_ENDPOINT`: The gateway endpoint (http://localhost:port)
- `ACCESS_KEY`: From MINIO_ROOT_USER secret
- `SECRET_KEY`: From MINIO_ROOT_PASSWORD secret
- `WEBHOOK_ENDPOINT`: The configured webhook service endpoint
- `BUCKET_NAME`: The JuiceFS bucket/filesystem name

### Migration from v0.1.x

If you were using the `juicefsConfig` Job in v0.1.x, migrate to the sidecar approach:

**Old (v0.1.x - Job approach):**
```yaml
juicefsConfig:
  enabled: true
  webhookEndpoint: "http://webhook-service:3000"
  mcCommands:
    - mc alias set jfs ${GATEWAY_ENDPOINT} ${ACCESS_KEY} ${SECRET_KEY}
```

**New (v0.2.0+ - Sidecar approach):**
```yaml
sidecar:
  enabled: true
  webhookEndpoint: "http://webhook-service:3000"
  mcCommands:
    - mc alias set jfs ${GATEWAY_ENDPOINT} ${ACCESS_KEY} ${SECRET_KEY}
```

The main differences:
- Job runs post-install/post-upgrade; sidecar runs continuously with each pod
- Sidecar uses `localhost` endpoint (same pod); Job used service endpoint
- Sidecar exits after completion (unless `keepRunning: true`)
- No Helm hooks required with sidecar approach

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Juicedata Inc. | <team@juicedata.io> | <https://juicefs.com> |

## Source Code

* <https://github.com/juicedata/juicefs>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| envs | list | `[]` | Environment variables for the gateway container Example:  - name: JFSCHAN    value: "gluster" |
| formatOptions | string | `""` | JuiceFS format options. Separated by spaces Example: "--inodes=1000000 --block-size=4M" Ref: https://juicefs.com/docs/community/command_reference#format |
| fullnameOverride | string | `""` |  |
| hostNetwork | bool | `false` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"juicedata/mount"` |  |
| image.tag | string | `"ce-v1.2.3"` | Overrides the image tag which defaults to the chart appVersion. For JuiceFS Community Edition, use ce-vx.x.x style tags For JuiceFS Enterprise Edition, use ee-vx.x.x style tags Find the latest built images in our docker image repo: https://hub.docker.com/r/juicedata/mount |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `"nginx"` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `""` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| initEnvs | list | `[]` | Environment variables for init containers Example:  - name: GOOGLE_APPLICATION_CREDENTIALS    value: "/root/.config/gcloud/application_default_credentials.json" |
| metricsPort | int | `9567` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| options | string | `""` | Gateway Options. Separated by spaces Example: "--get-timeout=60 --put-timeout=60" CE Ref: https://juicefs.com/docs/community/command_reference#gateway EE Ref: https://juicefs.com/docs/cloud/reference/command_reference/#gateway |
| podAnnotations | object | `{}` |  |
| port | int | `9000` |  |
| replicaCount | int | `1` |  |
| resources.limits.cpu | string | `"5000m"` |  |
| resources.limits.memory | string | `"5Gi"` |  |
| resources.requests.cpu | string | `"1000m"` |  |
| resources.requests.memory | string | `"1Gi"` |  |
| secret.accessKey | string | `""` | Access key for object storage |
| secret.bucket | string | `""` | Object storage bucket or full endpoint CE Ref: https://juicefs.com/docs/community/how_to_setup_object_storage EE Ref (see --bucket): https://juicefs.com/docs/cloud/reference/command_reference/#auth |
| secret.metaurl | string | `""` | Connection URL for metadata engine (e.g. Redis) Ref: https://juicefs.com/docs/community/databases_for_metadata |
| secret.name | string | `""` | The JuiceFS file system name. |
| secret.secretKey | string | `""` | Secret key for object storage |
| secret.storage | string | `""` | Object storage type, such as `s3`, `gs`, `oss` Ref: https://juicefs.com/docs/community/how_to_setup_object_storage |
| secret.token | string | `""` | JuiceFS Enterprise Edition file system token, if this token is specified, this helm chart then assumes JuiceFS EE and neglect all CE configurations |
| service.type | string | `"ClusterIP"` |  |
| tolerations | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
