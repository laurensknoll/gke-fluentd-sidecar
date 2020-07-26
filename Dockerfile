# https://github.com/GoogleCloudPlatform/google-fluentd/blob/master/docker/Dockerfile
FROM gcr.io/stackdriver-agents/stackdriver-logging-agent:1.6.37

# Configure default values for env-based sidecar
ENV K8S_NAMESPACE=default \
    K8S_POD=app \
    K8s_CONTAINER=app

# Configure default values for k8s labels
RUN mkdir -p /k8s && touch /k8s/labels

COPY google-fluentd-sidecar.conf /etc/google-fluentd/google-fluentd-sidecar.conf
CMD [ "/usr/sbin/google-fluentd", "--config", "/etc/google-fluentd/google-fluentd-sidecar.conf" ]