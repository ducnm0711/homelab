{{- define "tpl-folders" -}}
{{- range $datasources := .Values.grafana.provision.datasources -}}
{{ $clusterId := $datasources.clusterId }}
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaFolder
metadata:
  name: {{ printf "%s" $clusterId }}
spec:
  title: {{ printf "%s" $clusterId }}
  uid: {{ printf "%s" $clusterId }}
  parentFolderRef: alerts
  instanceSelector:
{{ toYaml $.Values.grafana.instanceSelector | indent 4 }}
---
{{- end }}
{{- end }}