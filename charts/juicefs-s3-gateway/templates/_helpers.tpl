{{/*
Expand the name of the chart.
*/}}
{{- define "juicefs-s3-gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "juicefs-s3-gateway.fullname" -}}
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
{{- define "juicefs-s3-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "juicefs-s3-gateway.labels" -}}
helm.sh/chart: {{ include "juicefs-s3-gateway.chart" . }}
{{ include "juicefs-s3-gateway.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "juicefs-s3-gateway.selectorLabels" -}}
app.kubernetes.io/name: {{ include "juicefs-s3-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "juicefs-s3-gateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "juicefs-s3-gateway.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the secret to use
*/}}
{{- define "juicefs-s3-gateway.secretName" -}}
{{- if .Values.secret.create }}
{{- default (include "juicefs-s3-gateway.fullname" .) .Values.secret.name }}
{{- else }}
{{- required "secret.name is required when secret.create is false" .Values.secret.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the configmap to use
*/}}
{{- define "juicefs-s3-gateway.configMapName" -}}
{{- if .Values.configMap.create }}
{{- default (include "juicefs-s3-gateway.fullname" .) .Values.configMap.name }}
{{- else }}
{{- required "configMap.name is required when configMap.create is false" .Values.configMap.name }}
{{- end }}
{{- end }}

{{/*
Cache flags for every JuiceFS client in the pod. Both clients must receive IDENTICAL
values: each runs its own LRU eviction against the shared juicefs-cache volume, so a
smaller --cache-size on one would continuously evict the other's blocks.

--cache-size is in MiB, set to 80% of the volume. Exceeding it evicts cache blocks;
exceeding the emptyDir sizeLimit evicts the POD. The gap absorbs JuiceFS's documented
overshoot and the drift between the clients' periodic cache-index rescans.

Integer math only: sprig `mul` casts every argument to int64, so `mul emptyDirSizeGi 1024 0.8`
silently renders --cache-size=0. 1024 converts GiB->MiB, *4/5 applies the 80%, and the
multiply must come before the divide or truncation loses the fraction.
*/}}
{{- define "juicefs-s3-gateway.cacheFlags" -}}
{{- $c := .Values.cache | default dict -}}
{{- $gi := $c.emptyDirSizeGi | default 0 | int -}}
{{- if lt $gi 1 -}}
{{- fail "cache.emptyDirSizeGi must be >= 1. There is no '0 = unlimited': 0 renders --cache-size=0 AND drops the emptyDir sizeLimit, giving an unbounded cache with no backstop - which is exactly how the gateway reached 75G on pw and 69G on nh-dev. For a large cache set a large number." -}}
{{- end -}}
{{- if not $c.dir -}}
{{- fail "cache.dir must be set - it is both --cache-dir and the mountPath of the juicefs-cache volume. Empty renders --cache-dir= and JuiceFS silently falls back to $HOME/.juicefs/cache, i.e. the uncapped minio-config volume." -}}
{{- end -}}
--cache-dir={{ $c.dir }} --cache-size={{ div (mul $gi 1024 4) 5 }} --free-space-ratio={{ $c.freeSpaceRatio | default 0.2 }} --cache-expire={{ $c.expire | default "336h" }} --cache-mode={{ $c.mode | default "0660" }}
{{- end }}
