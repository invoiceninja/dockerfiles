{{- define "invoiceninja.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "invoiceninja.fullname" -}}
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

{{- define "invoiceninja.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "invoiceninja.labels" -}}
helm.sh/chart: {{ include "invoiceninja.chart" . }}
app.kubernetes.io/name: {{ include "invoiceninja.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "invoiceninja.selectorLabels" -}}
app.kubernetes.io/name: {{ include "invoiceninja.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "invoiceninja.appServiceName" -}}
{{- printf "%s-app" (include "invoiceninja.fullname" .) -}}
{{- end -}}

{{- define "invoiceninja.mysqlServiceName" -}}
{{- printf "%s-mysql" (include "invoiceninja.fullname" .) -}}
{{- end -}}

{{- define "invoiceninja.redisServiceName" -}}
{{- printf "%s-redis" (include "invoiceninja.fullname" .) -}}
{{- end -}}
