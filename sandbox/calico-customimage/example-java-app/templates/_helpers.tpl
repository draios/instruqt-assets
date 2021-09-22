{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "example-java-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "example-java-app.fullname" -}}
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
{{- define "example-java-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "example-java-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "example-java-app.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}



{{/*
Common labels for cassandra
*/}}
{{- define "example-java-app.cassandra.labels" -}}
helm.sh/chart: {{ include "example-java-app.chart" . }}
{{ include "example-java-app.cassandra.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for cassandra
*/}}
{{- define "example-java-app.cassandra.selectorLabels" -}}
app.kubernetes.io/name: {{ include "example-java-app.name" . }}-cassandra
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}


{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-java-app.cassandra.image" -}}
{{- include "image_for_component" (dict "root" . "component" "cassandra") -}}
{{- end -}}


{{/*
Common labels for javaapp
*/}}
{{- define "example-java-app.javaapp.labels" -}}
helm.sh/chart: {{ include "example-java-app.chart" . }}
{{ include "example-java-app.javaapp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for javaapp
*/}}
{{- define "example-java-app.javaapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "example-java-app.name" . }}-javaapp
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-java-app.javaapp.image" -}}
{{- include "image_for_component" (dict "root" . "component" "javaapp") -}}
{{- end -}}


{{/*
Common labels for jclient
*/}}
{{- define "example-java-app.jclient.labels" -}}
helm.sh/chart: {{ include "example-java-app.chart" . }}
{{ include "example-java-app.jclient.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for jclient
*/}}
{{- define "example-java-app.jclient.selectorLabels" -}}
app.kubernetes.io/name: {{ include "example-java-app.name" . }}-jclient
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-java-app.jclient.image" -}}
{{- include "image_for_component" (dict "root" . "component" "jclient") -}}
{{- end -}}


{{/*
Common labels for mongo
*/}}
{{- define "example-java-app.mongo.labels" -}}
helm.sh/chart: {{ include "example-java-app.chart" . }}
{{ include "example-java-app.mongo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for mongo
*/}}
{{- define "example-java-app.mongo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "example-java-app.name" . }}-mongo
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-java-app.mongo.image" -}}
{{- include "image_for_component" (dict "root" . "component" "mongo") -}}
{{- end -}}

{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-java-app.mongo_statsd.image" -}}
{{- include "image_for_component" (dict "root" . "component" "mongo_statsd") -}}
{{- end -}}


{{/*
Common labels for redis
*/}}
{{- define "example-java-app.redis.labels" -}}
helm.sh/chart: {{ include "example-java-app.chart" . }}
{{ include "example-java-app.redis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for redis
*/}}
{{- define "example-java-app.redis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "example-java-app.name" . }}-redis
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Allow overriding registry and repository for air-gapped environments
*/}}
{{- define "example-java-app.redis.image" -}}
{{- include "image_for_component" (dict "root" . "component" "redis") -}}
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