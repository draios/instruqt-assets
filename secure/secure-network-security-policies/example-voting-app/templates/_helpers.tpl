{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "example-voting-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "example-voting-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "example-voting-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "example-voting-app.serviceAccountName" -}}
    {{ include "example-voting-app.fullname" .}}
{{- end -}}

{{/*
Common labels for observer
*/}}
{{- define "example-voting-app.observer.labels" -}}
helm.sh/chart: {{ include "example-voting-app.chart" . }}
{{ include "example-voting-app.observer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for observer
*/}}
{{- define "example-voting-app.observer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "example-voting-app.name" . }}-observer
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-voting-app.observer.image" -}}
{{- include "image_for_component" (dict "root" . "component" "observer") -}}
{{- end -}}

{{/*
Common labels for db
*/}}
{{- define "example-voting-app.db.labels" -}}
helm.sh/chart: {{ include "example-voting-app.chart" . }}
{{ include "example-voting-app.db.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for db
*/}}
{{- define "example-voting-app.db.selectorLabels" -}}
app.kubernetes.io/name: {{ include "example-voting-app.name" . }}-db
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-voting-app.db.image" -}}
{{- include "image_for_component" (dict "root" . "component" "db") -}}
{{- end -}}

{{/*
Common labels for redis
*/}}
{{- define "example-voting-app.redis.labels" -}}
helm.sh/chart: {{ include "example-voting-app.chart" . }}
{{ include "example-voting-app.redis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for redis
*/}}
{{- define "example-voting-app.redis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "example-voting-app.name" . }}-redis
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-voting-app.redis.image" -}}
{{- include "image_for_component" (dict "root" . "component" "redis") -}}
{{- end -}}

{{/*
Common labels for result
*/}}
{{- define "example-voting-app.result.labels" -}}
helm.sh/chart: {{ include "example-voting-app.chart" . }}
{{ include "example-voting-app.result.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for result
*/}}
{{- define "example-voting-app.result.selectorLabels" -}}
app.kubernetes.io/name: {{ include "example-voting-app.name" . }}-result
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-voting-app.result.image" -}}
{{- include "image_for_component" (dict "root" . "component" "result") -}}
{{- end -}}

{{/*
Common labels for vote
*/}}
{{- define "example-voting-app.vote.labels" -}}
helm.sh/chart: {{ include "example-voting-app.chart" . }}
{{ include "example-voting-app.vote.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for vote
*/}}
{{- define "example-voting-app.vote.selectorLabels" -}}
app.kubernetes.io/name: {{ include "example-voting-app.name" . }}-vote
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-voting-app.vote.image" -}}
{{- include "image_for_component" (dict "root" . "component" "vote") -}}
{{- end -}}

{{/*
Common labels for voter
*/}}
{{- define "example-voting-app.voter.labels" -}}
helm.sh/chart: {{ include "example-voting-app.chart" . }}
{{ include "example-voting-app.voter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for voter
*/}}
{{- define "example-voting-app.voter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "example-voting-app.name" . }}-voter
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-voting-app.voter.image" -}}
{{- include "image_for_component" (dict "root" . "component" "voter") -}}
{{- end -}}


{{/*
Common labels for worker
*/}}
{{- define "example-voting-app.worker.labels" -}}
helm.sh/chart: {{ include "example-voting-app.chart" . }}
{{ include "example-voting-app.worker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for worker
*/}}
{{- define "example-voting-app.worker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "example-voting-app.name" . }}-worker
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-voting-app.worker.image" -}}
{{- include "image_for_component" (dict "root" . "component" "worker") -}}
{{- end -}}

{{/* 
Use like: {{ include "define_component_image" (dict "root" . "component" "<component_name>" }}
*/}}
{{- define "image_for_component" -}}
{{- $overrideValue := tpl (printf "{{- .Values.%s.image.overrideValue -}}" .component) .root }}
{{- if $overrideValue }}
    {{- $overrideValue -}}
{{- else -}}
    {{- $imageRegistry := tpl (printf "{{- .Values.%s.image.registry -}}" .component) .root -}}
    {{- $imageRepository := tpl (printf "{{- .Values.%s.image.repository -}}" .component) .root -}}
    {{- $imageTag := tpl (printf "{{- .Values.%s.image.tag -}}" .component) .root -}}
    {{- $globalRegistry := (default .root.Values.global dict).imageRegistry -}}
    {{- $globalRegistry | default $imageRegistry | default "docker.io" -}} / {{- $imageRepository -}} : {{- $imageTag -}}
{{- end -}}
{{- end -}}