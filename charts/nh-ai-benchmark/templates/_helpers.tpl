{{/*
Expand the name of the chart.
*/}}
{{- define "nh-ai-benchmark.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nh-ai-benchmark.fullname" -}}
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
{{- define "nh-ai-benchmark.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nh-ai-benchmark.labels" -}}
helm.sh/chart: {{ include "nh-ai-benchmark.chart" . }}
{{ include "nh-ai-benchmark.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nh-ai-benchmark.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nh-ai-benchmark.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nh-ai-benchmark.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nh-ai-benchmark.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Env entries sourced from .Values.existingSecret. Shared by deployment-api.yaml
and job-validate-secret.yaml so the two can never drift apart. Renders nothing
if .Values.existingSecret is unset.
*/}}
{{- define "nh-ai-benchmark.secretEnv" -}}
{{- with .Values.existingSecret }}
- name: OI_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: OI_API_KEY
- name: SLACK_WEBHOOK_URL
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: SLACK_WEBHOOK_URL
      optional: true
- name: BENCH_AUTOMATION_ENCRYPTION_KEY
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: BENCH_AUTOMATION_ENCRYPTION_KEY
- name: BENCH_AUTOMATION_RUN_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: BENCH_AUTOMATION_RUN_SECRET
{{- end }}
{{- end }}
