{{/*
Expand the name of the chart.
*/}}
{{- define "nh-data-ingestion.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nh-data-ingestion.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nh-data-ingestion.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nh-data-ingestion.labels" -}}
helm.sh/chart: {{ include "nh-data-ingestion.chart" . }}
{{ include "nh-data-ingestion.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nh-data-ingestion.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nh-data-ingestion.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nh-data-ingestion.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nh-data-ingestion.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
API component name
*/}}
{{- define "nh-data-ingestion.api.fullname" -}}
{{- printf "%s-api" (include "nh-data-ingestion.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
API labels
*/}}
{{- define "nh-data-ingestion.api.labels" -}}
{{ include "nh-data-ingestion.labels" . }}
app.kubernetes.io/component: api
{{- end }}

{{/*
API selector labels
*/}}
{{- define "nh-data-ingestion.api.selectorLabels" -}}
{{ include "nh-data-ingestion.selectorLabels" . }}
app.kubernetes.io/component: api
{{- end }}

{{/*
Worker component name
*/}}
{{- define "nh-data-ingestion.worker.fullname" -}}
{{- printf "%s-worker" (include "nh-data-ingestion.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Worker labels
*/}}
{{- define "nh-data-ingestion.worker.labels" -}}
{{ include "nh-data-ingestion.labels" . }}
app.kubernetes.io/component: worker
{{- end }}

{{/*
Worker selector labels
*/}}
{{- define "nh-data-ingestion.worker.selectorLabels" -}}
{{ include "nh-data-ingestion.selectorLabels" . }}
app.kubernetes.io/component: worker
{{- end }}

{{/*
Scheduler component name
*/}}
{{- define "nh-data-ingestion.scheduler.fullname" -}}
{{- printf "%s-scheduler" (include "nh-data-ingestion.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Scheduler labels
*/}}
{{- define "nh-data-ingestion.scheduler.labels" -}}
{{ include "nh-data-ingestion.labels" . }}
app.kubernetes.io/component: scheduler
{{- end }}

{{/*
Scheduler selector labels
*/}}
{{- define "nh-data-ingestion.scheduler.selectorLabels" -}}
{{ include "nh-data-ingestion.selectorLabels" . }}
app.kubernetes.io/component: scheduler
{{- end }}

{{/*
Flower component name
*/}}
{{- define "nh-data-ingestion.flower.fullname" -}}
{{- printf "%s-flower" (include "nh-data-ingestion.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Flower labels
*/}}
{{- define "nh-data-ingestion.flower.labels" -}}
{{ include "nh-data-ingestion.labels" . }}
app.kubernetes.io/component: flower
{{- end }}

{{/*
Flower selector labels
*/}}
{{- define "nh-data-ingestion.flower.selectorLabels" -}}
{{ include "nh-data-ingestion.selectorLabels" . }}
app.kubernetes.io/component: flower
{{- end }}

{{/*
Common environment variables for all components
Uses shared secrets from parent chart (private-ai-rag):
- shared-secrets-rag: Contains DATABASE_URL, JWT_SECRET_KEY
- juicefs-s3-gateway: Contains JuiceFS credentials
- shared-configmap-rag: Contains other config (loaded via envFrom)
*/}}
{{- define "nh-data-ingestion.commonEnv" -}}
- name: REDIS_URL
  value: {{ .Values.config.redisUrl | quote }}
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.extraEnvVarsSecret | default "shared-secrets-rag" }}
      key: DATABASE_URL
# - name: POSTGRES_DATABASE
#   value: {{ .Values.config.postgresDatabase | quote }}
- name: JWT_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.global.extraEnvVarsSecret | default "shared-secrets-rag" }}
      key: JWT_SECRET_KEY
{{- if .Values.config.juiceFsSecretName }}
- name: JUICEFS_S3_ENDPOINT
  valueFrom:
    secretKeyRef:
      name: {{ .Values.config.juiceFsSecretName }}
      key: juicefs-s3-gateway-endpoint
      optional: true
- name: JUICEFS_S3_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.config.juiceFsSecretName }}
      key: minio-root-user
- name: JUICEFS_S3_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.config.juiceFsSecretName }}
      key: minio-root-password
- name: JUICEFS_S3_VOLUME_NAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.config.juiceFsSecretName }}
      key: name
- name: JUICEFS_S3_STORAGE
  valueFrom:
    secretKeyRef:
      name: {{ .Values.config.juiceFsSecretName }}
      key: storage
      optional: true
- name: JUICEFS_S3_BUCKET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.config.juiceFsSecretName }}
      key: bucket
      optional: true
{{- end }}
{{- end }}

{{/*
Common envFrom for all components
*/}}
{{- define "nh-data-ingestion.commonEnvFrom" -}}
{{- if .Values.global.extraEnvVarsCM }}
- configMapRef:
    name: {{ .Values.global.extraEnvVarsCM }}
{{- end }}
{{- if .Values.global.extraEnvVarsSecret }}
- secretRef:
    name: {{ .Values.global.extraEnvVarsSecret }}
{{- end }}
{{- if .Values.global.dataIngestionCredsRef }}
- secretRef:
    name: {{ .Values.global.dataIngestionCredsRef }}
{{- end }}
{{- end }}
