{{- define "alert-contactpoint" -}}
{{- range $contactPoints := .Values.grafana.provision.contactPoints -}}
{{ $contactId := $contactPoints.contactId }}
{{ $contactUrl := $contactPoints.contactUrl }}
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaContactPoint
metadata:
  name: {{ printf "%s" $contactId }}
  namespace: {{ $.Release.Namespace }}
spec:
  name: {{ printf "%s" $contactId }}
  uid: {{ printf "%s" $contactId }}
  type: teams
  instanceSelector:
{{ toYaml $.Values.grafana.instanceSelector | indent 4 }}
  settings:
    message: '{{`{{ template "dummy.teams.message" . }}`}}'
    title: '{{`{{ template "dummy.teams.title" . }}`}}'
    url: {{ printf "%s" $contactUrl }}
---
{{- end -}}
{{- end -}}
