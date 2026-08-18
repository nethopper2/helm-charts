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
Names for the websearch workloads
*/}}
{{- define "nh-rag.searxng.fullname" -}}
{{- printf "%s-searxng" (include "nh-rag.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "nh-rag.crawl4ai.fullname" -}}
{{- printf "%s-crawl4ai" (include "nh-rag.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Pre-created Secret holding the websearch credentials
*/}}
{{- define "nh-rag.websearch.secretName" -}}
{{- required "websearch.secretName is required when websearch.enabled is true" .Values.websearch.secretName }}
{{- end }}

{{/*
In-cluster URLs for the websearch services, overridable per component
*/}}
{{- define "nh-rag.searxng.url" -}}
{{- default (printf "http://%s:%v" (include "nh-rag.searxng.fullname" .) .Values.websearch.searxng.service.port) .Values.websearch.searxng.url }}
{{- end }}

{{- define "nh-rag.crawl4ai.url" -}}
{{- default (printf "http://%s:%v" (include "nh-rag.crawl4ai.fullname" .) .Values.websearch.crawl4ai.service.port) .Values.websearch.crawl4ai.url }}
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
