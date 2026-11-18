{{- define "tpl-datasources" -}}
{{- range $datasources := .Values.grafana.provision.datasources -}}
{{ $secretKeyRef := $.Values.grafana.secretKeyRef }}
{{ $clusterId := $datasources.clusterId }}
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDatasource
metadata:
  name: {{ printf "metrics-%s" $clusterId }}
  namespace: {{ $.Release.Namespace }}
spec:
  uid: {{ printf "metrics-%s" $clusterId }}
  instanceSelector:
{{ toYaml $.Values.grafana.instanceSelector | indent 4 }}
  valuesFrom:
    - targetPath: "basicAuthUser"
      valueFrom:
        secretKeyRef:
          name: "{{ printf "%s" $secretKeyRef }}"
          key: "MIMIR_USERNAME"
    - targetPath: "secureJsonData.basicAuthPassword"
      valueFrom:
        secretKeyRef:
          name: "{{ printf "%s" $secretKeyRef }}"
          key: "MIMIR_PASSWORD"
    - targetPath: "secureJsonData.httpHeaderValue1"
      valueFrom:
        secretKeyRef:
          name: "{{ printf "%s" $secretKeyRef }}"
          key: "{{ printf "%s" $clusterId | replace "-" "_" | upper}}"
  datasource:
    name: {{ printf "metrics-%s" $clusterId }}
    type: prometheus
    access: proxy
    url: https://mimir.dummy.io/prometheus
    basicAuth: true
    basicAuthUser: "${MIMIR_USERNAME}"
    isDefault: false
    readOnly: true
    jsonData:
      prometheusType: Mimir
      prometheusVersion: 2.9.1
      disableRecordingRules: true
      httpHeaderName1: X-Scope-OrgID
      httpMethod: POST
      manageAlerts: false
      oauthPassThru: false
      sigV4Auth: false
    secureJsonData:
      basicAuthPassword: "${MIMIR_PASSWORD}"
      httpHeaderValue1: "${{ printf "{%s}" $clusterId | replace "-" "_" | upper}}"
---
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDatasource
metadata:
  name: {{ printf "logs-%s" $clusterId }}
  namespace: {{ $.Release.Namespace }}
spec:
  uid: {{ printf "logs-%s" $clusterId }}
  instanceSelector:
{{ toYaml $.Values.grafana.instanceSelector | indent 4 }}
  valuesFrom:
    - targetPath: "basicAuthUser"
      valueFrom:
        secretKeyRef:
          name: "{{ printf "%s" $secretKeyRef }}"
          key: "LOKI_USERNAME"
    - targetPath: "secureJsonData.basicAuthPassword"
      valueFrom:
        secretKeyRef:
          name: "{{ printf "%s" $secretKeyRef }}"
          key: "LOKI_PASSWORD"
    - targetPath: "secureJsonData.httpHeaderValue1"
      valueFrom:
        secretKeyRef:
          name: "{{ printf "%s" $secretKeyRef }}"
          key: "{{ printf "%s" $clusterId | replace "-" "_" | upper}}"
  datasource:
    name: {{ printf "logs-%s" $clusterId }}
    type: loki
    access: proxy
    url: https://loki.dummy.io
    basicAuth: true
    basicAuthUser: "${LOKI_USERNAME}"
    isDefault: false
    readOnly: true
    jsonData:
      httpHeaderName1: X-Scope-OrgID
    secureJsonData:
      basicAuthPassword: "${LOKI_PASSWORD}"
      httpHeaderValue1: "${{ printf "{%s}" $clusterId | replace "-" "_" | upper}}"
---
{{- end -}}
{{- end -}}

