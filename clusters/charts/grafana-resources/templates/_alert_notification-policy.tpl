{{- define "alert-notification-policy" -}}
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaNotificationPolicy
metadata:
  name: dummy-ms-teams
  namespace: {{ .Release.Namespace }}
spec:
  instanceSelector:
{{ toYaml $.Values.grafana.instanceSelector | indent 4 }}
  route:
    receiver: grafana-default-email
    group_by:
        - alertname
        - cluster
    routes:
{{- range $contactPoint := .Values.grafana.provision.contactPoints }}
      - receiver: {{ $contactPoint.contactId }}
        object_matchers:
{{- range $matcher := $contactPoint.alertMatchers }}
          - {{ $matcher | toJson }}
{{- end }}
{{- end }}
{{- end -}}