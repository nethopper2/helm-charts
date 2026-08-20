{{/*
Expand the name of the chart.
*/}}
{{- define "private-ai-websearch.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "private-ai-websearch.fullname" -}}
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
{{- define "private-ai-websearch.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "private-ai-websearch.labels" -}}
helm.sh/chart: {{ include "private-ai-websearch.chart" . }}
{{ include "private-ai-websearch.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "private-ai-websearch.selectorLabels" -}}
app.kubernetes.io/name: {{ include "private-ai-websearch.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "private-ai-websearch.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "private-ai-websearch.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Names for the component workloads
*/}}
{{- define "private-ai-websearch.searxng.fullname" -}}
{{- printf "%s-searxng" (include "private-ai-websearch.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "private-ai-websearch.crawl4ai.fullname" -}}
{{- printf "%s-crawl4ai" (include "private-ai-websearch.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Pre-created Secret holding the credentials. This chart never creates it.
*/}}
{{- define "private-ai-websearch.secretName" -}}
{{- required "secretName is required: it must name an existing Secret holding SEARXNG_SECRET and CRAWL4AI_API_TOKEN" .Values.secretName }}
{{- end }}

{{/*
In-cluster URLs of the components, for consumers to point at
*/}}
{{- define "private-ai-websearch.searxng.url" -}}
{{- printf "http://%s:%v" (include "private-ai-websearch.searxng.fullname" .) .Values.searxng.service.port }}
{{- end }}

{{- define "private-ai-websearch.crawl4ai.url" -}}
{{- printf "http://%s:%v" (include "private-ai-websearch.crawl4ai.fullname" .) .Values.crawl4ai.service.port }}
{{- end }}
