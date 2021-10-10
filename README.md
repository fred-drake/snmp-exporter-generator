# SNMP Exporter Generator

This is a custom built image used to automatically generate the snmp.yml file needed for the Prometheus SNMP exporter.  
Unlike most containers, this does not process anything during runtime.  Instead, all of the processing is performed during image creation.

I use this as an init-container for my Prometheus SNMP exporter deployment that resides on my Kubernetes cluster.  It mounts
the same persistent volume claim as the SNMP exporter, and copies the snmp.yml file.  If the snmp.yml values change, it will
be automatically picked up upon exporter rebuild.

## Modifying the Contents of This Container

All supporting MIBs sit in the `mibs` directory, and the `generator.yml` sits in the root of the repository.  The image build
copies these to the appropriate location in the container.  Upon push to Github, the built-in CI/CD will bake a new image and
push to Docker hub under the tag `fdrake/snmp-exporter-generator:latest`.

## Supporting architectures

Both `arm64` and `amd64` are supported.  Note that at the time of this writing, the official `prom/snmp-exporter` image does
not support `arm64`.

## Init-Container Example

Below is my deployment, which illustrates how I use this image as an init-container, before the actual snmp-exporter container is built.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: snmp-exporter
  namespace: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: snmp-exporter
  template:
    metadata:
      labels:
        app: snmp-exporter
    spec:
      volumes:
        - name: config
          persistentVolumeClaim:
            claimName: config-vol
      containers:
      - name: snmp-exporter
        image: prom/snmp-exporter
        env:
        - name: TZ
          value: America/New_York
        volumeMounts:
        - name: config
          mountPath: /etc/snmp_exporter
        ports:
        - containerPort: 9116
          name: metrics
      initContainers:
      - name: init-config
        image: fdrake/snmp-exporter-generator
        imagePullPolicy: Always
        command:
          - sh
          - -c
          - cp -f /opt/snmp.yml /etc/snmp_exporter
        volumeMounts:
        - name: config
          mountPath: /etc/snmp_exporter

```

For completeness, below are my definitions for the persistent volume claim and service.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: config-vol
  namespace: prometheus
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi # Overkill, but my ceph storage thin-provisions
---
# This gets called by Prometheus at http://snmp-exporter.prometheus.svc.cluster.local:9116
kind: Service
apiVersion: v1
metadata:
  name: snmp-exporter
  namespace: prometheus
spec:
  type: ClusterIP
  selector:
    app: snmp-exporter
  ports:
  - name: http-metrics
    port: 9116
    protocol: TCP
    targetPort: metrics
```

The github repository can be found here: https://github.com/fred-drake/snmp-exporter-generator
