{{- define "openbao-unseal.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "openbao-unseal.fullname" -}}
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

{{- define "openbao-unseal.labels" -}}
helm.sh/chart: {{ include "openbao-unseal.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "openbao-unseal.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "openbao-unseal.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openbao-unseal.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
