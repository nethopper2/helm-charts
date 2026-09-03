{{/*
Expand the name of the chart.
*/}}
{{- define "nh-rag.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nh-rag.fullname" -}}
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
{{- define "nh-rag.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nh-rag.labels" -}}
helm.sh/chart: {{ include "nh-rag.chart" . }}
{{ include "nh-rag.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nh-rag.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nh-rag.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nh-rag.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nh-rag.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Pre-created Secret holding the websearch credentials
*/}}
{{- define "nh-rag.websearch.secretName" -}}
{{- required "websearch.secretName is required when websearch.enabled is true" .Values.websearch.secretName }}
{{- end }}

{{/*
URLs of the websearch services. They are deployed by the private-ai-websearch chart, not
this one, so both must be supplied.
*/}}
{{- define "nh-rag.searxng.url" -}}
{{- required "websearch.searxngUrl is required when websearch.enabled is true (deploy the private-ai-websearch chart and point at its SearXNG Service)" .Values.websearch.searxngUrl }}
{{- end }}

{{- define "nh-rag.crawl4ai.url" -}}
{{- required "websearch.crawl4aiUrl is required when websearch.enabled is true (deploy the private-ai-websearch chart and point at its Crawl4AI Service)" .Values.websearch.crawl4aiUrl }}
{{- end }}

{{/*
Websearch environment shared by the api and worker containers
*/}}
{{- define "nh-rag.websearch.env" -}}
- name: WEB_SEARCH_ENABLED
  value: "true"
- name: SEARXNG_URL
  value: {{ include "nh-rag.searxng.url" . | quote }}
- name: CRAWL4AI_URL
  value: {{ include "nh-rag.crawl4ai.url" . | quote }}
- name: CRAWL4AI_API_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "nh-rag.websearch.secretName" . }}
      key: CRAWL4AI_API_TOKEN
{{- end }}

{{/*
Name of the Secret holding the workspace sandbox HMAC token secret.
*/}}
{{- define "nh-rag.workspaceSandbox.secretName" -}}
{{- if .Values.workspaceSandbox.existingSecret -}}
{{- .Values.workspaceSandbox.existingSecret -}}
{{- else -}}
{{- include "nh-rag.fullname" . }}-workspace-sandbox
{{- end -}}
{{- end }}

{{/*
Workspace sandbox environment for the api container (per-conversation
agent-sandbox CRs provisioned by Intel; see docs/workspace-sandbox-deploy.md
in nh-rag-embedding).
*/}}
{{- define "nh-rag.workspaceSandbox.env" -}}
- name: WORKSPACE_RUNTIME_ENABLED
  value: "true"
- name: WORKSPACE_SANDBOX_ENABLED
  value: "true"
- name: WORKSPACE_SANDBOX_NAMESPACE
  value: {{ .Values.workspaceSandbox.namespace | default .Release.Namespace | quote }}
- name: WORKSPACE_SANDBOX_IMAGE
  value: "{{ .Values.workspaceSandbox.image.repository }}:{{ .Values.workspaceSandbox.image.tag }}"
{{- if .Values.workspaceSandbox.runtimeClassName }}
- name: WORKSPACE_SANDBOX_RUNTIME_CLASS
  value: {{ .Values.workspaceSandbox.runtimeClassName | quote }}
{{- end }}
- name: WORKSPACE_SANDBOX_PORT
  value: {{ .Values.workspaceSandbox.port | quote }}
- name: WORKSPACE_SANDBOX_TTL_S
  value: {{ .Values.workspaceSandbox.ttlSeconds | quote }}
- name: WORKSPACE_SANDBOX_READY_TIMEOUT_S
  value: {{ .Values.workspaceSandbox.readyTimeoutSeconds | quote }}
- name: WORKSPACE_SANDBOX_PER_USER_CAP
  value: {{ .Values.workspaceSandbox.perUserCap | quote }}
- name: WORKSPACE_SANDBOX_CPU_REQUEST
  value: {{ .Values.workspaceSandbox.sandboxResources.cpuRequest | quote }}
- name: WORKSPACE_SANDBOX_MEM_REQUEST
  value: {{ .Values.workspaceSandbox.sandboxResources.memoryRequest | quote }}
- name: WORKSPACE_SANDBOX_CPU_LIMIT
  value: {{ .Values.workspaceSandbox.sandboxResources.cpuLimit | quote }}
- name: WORKSPACE_SANDBOX_MEM_LIMIT
  value: {{ .Values.workspaceSandbox.sandboxResources.memoryLimit | quote }}
- name: WORKSPACE_SANDBOX_TOKEN_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "nh-rag.workspaceSandbox.secretName" . }}
      key: WORKSPACE_SANDBOX_TOKEN_SECRET
- name: WORKSPACE_SUBAGENT_BUDGET_S
  value: {{ .Values.workspaceSandbox.subagentBudgetSeconds | quote }}
{{- end }}
