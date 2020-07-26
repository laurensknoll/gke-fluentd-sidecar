# GKE Fluentd Sidecar

The GKE Fluentd Sidecar extends the [Cloud Logging Agent](https://cloud.google.com/logging/docs/agent) with GKE-specific Cloud Logging labels. Allowing you to forward GKE application logs the same way as application stdout/stderr logs.

## Why this thing?

The default Cloud Logging Agent configuration doesn't add the required labels for [Cloud Operations for GKE](https://cloud.google.com/stackdriver/docs/solutions/gke) resource types. In effect the logs are not visible as Kubernetes container logs in Cloud Logging/Stackdriver.

Since the Cloud Logging Agent is unable to derive these labels (namespace-, pod- and container-name) without Kubernetes API permissions, I don't expect a fix for this.

## How does it work?

The GKE Fluentd sidecar is, like the name suggests, installed as a container [sidecar](https://kubernetes.io/docs/concepts/cluster-administration/logging/#using-a-sidecar-container-with-the-logging-agent). The application expects pod metadata as [environment variables](https://kubernetes.io/docs/tasks/inject-data-application/environment-variable-expose-pod-information/#use-pod-fields-as-values-for-environment-variables) and [files](https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/).

The environment variables are used to construct the `logging.googleapis.com/local_resource_id` attribute. This attribute ensures that logs are aggregated as the provided Kubernetes container:

    logging.googleapis.com/local_resource_id = "k8s_container.${K8S_NAMESPACE}.${K8S_POD}.${K8S_CONTAINER}"


The files are used to construct the `logging.googleapis.com/labels` attribute. This attribute ensures that the logs are tagged appropriately.

    logging.googleapis.com/labels = {
        k8s-pod/<pod.metadata.labels.key> = "<pod.metadata.labels.value>"
    }

> Files are used to prevent you granting your Pod Pod API access, which is currently required by the [kubernetes metadata plugin](https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter).


## Deployment configuration

> A full example is provided in [example/deployment.yaml](example/deployment.yaml).

The application container creates logs, which are forwarded by the sidecar container. Since the sidecar is unable to access the application container, both share a volume.

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      volumes:
        - name: logs
          emptyDir: {}
      containers:
        - name: application
          volumeMounts:
            - name: logs
              mountPath: /app/log
        - name: logging-agent
          volumeMounts:
            - name: logs
              mountPath: /app/log
```

To ensure that the sidecar forwards the logs with the appropriate origin, the sidecar is configured with the kubernetes metadata of the application container.

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
        - name: application
        - name: logging-agent
          env:
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: K8S_POD
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_CONTAINER
            value: application
```

To provide proper GKE logs integration, the deployment metadata is provided to the logging-agent. This information allows the logging-agent to construct the required "k8s-pod/..."-labels.

```yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: example
spec:
  template:
    spec:
      volumes:
        - name: k8s-labels
          downwardAPI:
            items:
              - path: labels
                fieldRef:
                  fieldPath: metadata.labels
      containers:
        - name: logging-agent
          volumeMounts:
            - name: k8s-labels
              mountPath: /k8s
```