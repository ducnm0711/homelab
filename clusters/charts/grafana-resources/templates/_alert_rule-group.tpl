{{- define "alert-rule-group" -}}
{{- $root := . -}}
{{- range $datasources := .Values.grafana.provision.datasources -}}
{{ $clusterId := $datasources.clusterId }}
{{ $alertEnabled := $datasources.alertEnabled }}
{{- if eq $alertEnabled true }}
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaAlertRuleGroup
metadata:
  name: {{ printf "%s" $clusterId }}
  namespace: {{ $root.Release.Namespace }}
spec:
  folderRef: {{ printf "%s" $clusterId }}
  instanceSelector:
{{ toYaml $root.Values.grafana.instanceSelector | indent 4 }}
  interval: 5m
  rules:
{{- /* Load alert rules dynamically from files/alert-rules directory */ -}}
{{- range $path, $_ := $root.Files.Glob "files/alert-rules/*.yaml" }}
{{- $alertRules := $root.Files.Get $path | fromYaml }}
{{- range $alertRules.rules }}
    - uid: {{ printf "%s-%s" .uid $clusterId | trunc 40 | lower }}
      title: {{ .title }}
      condition: {{ .condition }}
      data:
        - refId: A
          relativeTimeRange:
            from: {{ .query.timeRange.from | default 600 }}
            to: {{ .query.timeRange.to | default 0 }}
          datasourceUid: {{ printf "metrics-%s" $clusterId }}
          model:
{{- if .query.datasource }}
            datasource:
                type: {{ .query.datasource.type }}
                uid: {{ printf "metrics-%s" $clusterId }}
{{- end }}
            disableTextWrap: false
            editorMode: {{ .query.editorMode | default "builder" }}
            expr: {{ .query.expr }}
            fullMetaSearch: false
            includeNullMetadata: true
            instant: true
            intervalMs: 1000
            legendFormat: __auto
            maxDataPoints: 43200
            range: false
            refId: A
            useBackend: false
        - refId: B
          datasourceUid: __expr__
          model:
            conditions:
                - evaluator:
                    params:
                        - {{ .threshold.value }}
                    type: {{ .threshold.operator }}
                  operator:
                    type: and
                  query:
                    params:
                        - B
                  reducer:
                    params: []
                    type: last
                  type: query
            datasource:
                type: __expr__
                uid: __expr__
            expression: A
            intervalMs: 1000
            maxDataPoints: 43200
            refId: B
            type: threshold
      noDataState: {{ .noDataState | default "NoData" }}
      execErrState: {{ .execErrState | default "Error" }}
      for: {{ .for }}
      annotations:
        summary: {{ .annotations.summary }}
      labels:
        owner: {{ .labels.owner }}
        priority: {{ .labels.priority }}
      isPaused: {{ .isPaused | default true }}
{{- if .notification_settings }}
      notification_settings:
        receiver: {{ .notification_settings.receiver }}
{{- end }}
{{- end }}
{{- end }}
{{ end -}}
---
{{- end -}}
{{- end -}}