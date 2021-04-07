# Invoiceninja

This helm chart installs a Invoiceninja and its dependencies into a running
Kubernetes cluster.

The chart installs the [Invoiceninja](https://hub.docker.com/r/invoiceninja/invoiceninja) docker image.

Please read [Upgrading](#upgrading) section before upgrading MAJOR versions.

## Dependencies

- The Bitnami [common](https://github.com/bitnami/charts/tree/master/bitnami/common) helm chart
- The Bitnami [mariadb](https://github.com/bitnami/charts/tree/master/bitnami/mariadb) helm chart
- The Bitnami [nginx](https://github.com/bitnami/charts/tree/master/bitnami/nginx) helm chart
- The Bitnami [redis](https://github.com/bitnami/charts/tree/master/bitnami/redis) helm chart
- Tested on Kubernetes 1.17+

## Installing the Chart

To install the chart with the release name `invoiceninja`:

```bash
helm repo add invoiceninja https://invoiceninja.github.io/dockerfiles
helm install invoiceninja invoiceninja/invoiceninja
```

The command deploys Invoiceninja on the Kubernetes cluster in the default namespace. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `invoiceninja` deployment:

```bash
helm delete invoiceninja
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

The following table lists the configurable parameters of the Invoiceninja chart and their default values.

> NOTE: You MUST set any values that default to random or risk losing access after an upgrade. See how [here](https://github.com/lwj5/dockerfiles/tree/redis-pw/charts/invoiceninja#installing-with-arguments)

### Global Configuration

The following table shows the configuration options for the Invoiceninja helm chart:

### Global parameters

| Parameter                 | Description                                     | Default                                                 |
| ------------------------- | ----------------------------------------------- | ------------------------------------------------------- |
| `global.imageRegistry`    | Global Docker image registry                    | `nil`                                                   |
| `global.imagePullSecrets` | Global Docker registry secret names as an array | `[]` (does not add image pull secrets to deployed pods) |
| `global.storageClass`     | Global storage class for dynamic provisioning   | `nil`                                                   |

### Common parameters

| Parameter           | Description                                                          | Default                        |
| ------------------- | -------------------------------------------------------------------- | ------------------------------ |
| `nameOverride`      | String to partially override common.names.fullname                   | `nil`                          |
| `fullnameOverride`  | String to fully override common.names.fullname                       | `nil`                          |
| `clusterDomain`     | Default Kubernetes cluster domain                                    | `cluster.local`                |
| `commonLabels`      | Labels to add to all deployed objects                                | `{}`                           |
| `commonAnnotations` | Annotations to add to all deployed objects                           | `{}`                           |
| `kubeVersion`       | Force target Kubernetes version (using Helm capabilities if not set) | `nil`                          |
| `extraDeploy`       | Array of extra objects to deploy with the release                    | `[]` (evaluated as a template) |

### Invoiceninja parameters

| Parameter            | Description                                                     | Default                                                 |
| -------------------- | --------------------------------------------------------------- | ------------------------------------------------------- |
| `image.registry`     | Invoiceninja image registry                                     | `docker.io`                                             |
| `image.repository`   | Invoiceninja image name                                         | `invoiceninja/invoiceninja`                             |
| `image.tag`          | Invoiceninja image tag                                          | Check `values.yaml` file                                |
| `image.pullPolicy`   | Invoiceninja image pull policy                                  | `IfNotPresent`                                          |
| `image.pullSecrets`  | Specify docker-registry secret names as an array                | `[]` (does not add image pull secrets to deployed pods) |
| `image.debug`        | Specify if debug logs should be enabled                         | `false`                                                 |
| `serviceAccountName` | Name of a service account for the Invoiceninja pods             | `default`                                               |
| `debug`              | Turn on debug mode on Invoiceninja                              | `false`                                                 |
| `appKey`             | Laravel Application Key                                         | _random 32 character alphanumeric string_               |
| `logChannel`         | Name of log channel to use                                      | `nil`                                                   |
| `broadcastDriver`    | Name of broadcast driver to use                                 | `nil`                                                   |
| `cacheDriver`        | Name of cache driver to use                                     | `nil`                                                   |
| `sessionDriver`      | Name of session driver to use                                   | `nil`                                                   |
| `queueConnection`    | Name of queue connection to use                                 | `nil`                                                   |
| `snappdf`            | Use snappdf instead of Phantom JS PDF generation                | `true`                                                  |
| `extraEnvVars`       | Extra environment variables to be set on Invoiceninja container | `{}`                                                    |
| `extraEnvVarsCM`     | Name of existing ConfigMap containing extra env vars            | `nil`                                                   |
| `extraEnvVarsSecret` | Name of existing Secret containing extra env vars               | `nil`                                                   |

### Invoiceninja deployment parameters

| Parameter                   | Description                                                                               | Default                        |
| --------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------ |
| `replicaCount`              | Number of Invoiceninja Pods to run                                                        | `1`                            |
| `containerPorts.fastcgi`    | FastCGI port to expose at container level                                                 | `9000`                         |
| `podSecurityContext`        | Invoiceninja pods' Security Context                                                       | Check `values.yaml` file       |
| `containerSecurityContext`  | Invoiceninja containers' Security Context                                                 | Check `values.yaml` file       |
| `resources`                 | The resources for the Invoiceninja container                                              | `{}`                           |
| `livenessProbe`             | Liveness probe configuration for Invoiceninja                                             | Check `values.yaml` file       |
| `readinessProbe`            | Readiness probe configuration for Invoiceninja                                            | Check `values.yaml` file       |
| `updateStrategy`            | Set up update strategy                                                                    | `RollingUpdate`                |
| `podAntiAffinityPreset`     | Pod anti-affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`  | `soft`                         |
| `nodeAffinityPreset.type`   | Node affinity preset type. Ignored if `affinity` is set. Allowed values: `soft` or `hard` | `""`                           |
| `nodeAffinityPreset.key`    | Node label key to match. Ignored if `affinity` is set.                                    | `""`                           |
| `nodeAffinityPreset.values` | Node label values to match. Ignored if `affinity` is set.                                 | `[]`                           |
| `affinity`                  | Affinity for pod assignment                                                               | `{}` (evaluated as a template) |
| `nodeSelector`              | Node labels for pod assignment                                                            | `{}` (evaluated as a template) |
| `tolerations`               | Tolerations for pod assignment                                                            | `[]` (evaluated as a template) |
| `podLabels`                 | Extra labels for Invoiceninja pods                                                        | `{}`                           |
| `podAnnotations`            | Annotations for Invoiceninja pods                                                         | `{}`                           |
| `extraVolumeMounts`         | Additional volume mounts                                                                  | `[]`                           |
| `extraVolumes`              | Additional volumes                                                                        | `[]`                           |

### Exposure parameters

| Parameter                          | Description                                                                | Default                        |
| ---------------------------------- | -------------------------------------------------------------------------- | ------------------------------ |
| `service.type`                     | Kubernetes Service type                                                    | `ClusterIP`                    |
| `service.port`                     | Service FastCGI port                                                       | `9000`                         |
| `service.nodePort`                 | Kubernetes FastCGI node port                                               | `""`                           |
| `service.clusterIP`                | Invoiceninja service clusterIP IP                                          | `None`                         |
| `service.loadBalancerSourceRanges` | Restricts access for LoadBalancer (only with `service.type: LoadBalancer`) | `[]`                           |
| `service.loadBalancerIP`           | loadBalancerIP if service type is `LoadBalancer`                           | `nil`                          |
| `service.externalTrafficPolicy`    | Enable client source IP preservation                                       | `Cluster`                      |
| `service.annotations`              | Service annotations                                                        | `{}` (evaluated as a template) |

### Ingress parameters 

| Parameter                                               | Description                           | Default                  |
| ------------------------------------------------------- | ------------------------------------- | ------------------------ |
| `nginx.service.type`                                    | Kubernetes Service type               | `ClusterIP`              |
| `nginx.ingress.enabled`                                 | Enable ingress controller resource    | `true`                   |
| `nginx.ingress.hostname`                                | Default host for the ingress resource | `invoiceninja.local`     |
| `nginx.serverBlock`                                     | Custom NGINX server block             | `nil`                    |
| `nginx.extraVolumes`                                    | Array to add extra volumes            | Check `values.yaml` file |
| `nginx.extraVolumes[0].persistentVolumeClaim.claimName` | Name of Invoiceninja public PVC       | `invoiceninja-public`    |
| `nginx.extraVolumeMounts`                               | Array to add extra mount              | Check `values.yaml` file |

> See [Dependencies](#dependencies) for more.

### Persistence parameters

| Parameter                           | Description                              | Default           |
| ----------------------------------- | ---------------------------------------- | ----------------- |
| `persistence.public.enabled`        | Enable persistence using PVC             | `true`            |
| `persistence.public.existingClaim`  | Enable persistence using an existing PVC | `nil`             |
| `persistence.public.storageClass`   | PVC Storage Class                        | `nil`             |
| `persistence.public.accessModes`    | PVC Access Modes                         | `[ReadWriteMany]` |
| `persistence.public.size`           | PVC Storage Request                      | `1Gi`             |
| `persistence.public.dataSource`     | PVC data source                          | `{}`              |
| `persistence.storage.enabled`       | Enable persistence using PVC             | `true`            |
| `persistence.storage.existingClaim` | Enable persistence using an existing PVC | `nil`             |
| `persistence.storage.storageClass`  | PVC Storage Class                        | `nil`             |
| `persistence.storage.accessModes`   | PVC Access Modes                         | `[ReadWriteMany]` |
| `persistence.storage.size`          | PVC Storage Request                      | `5Gi`             |
| `persistence.storage.dataSource`    | PVC data source                          | `{}`              |

### Redis parameters

| Parameter                         | Description                                  | Default                                   |
| --------------------------------- | -------------------------------------------- | ----------------------------------------- |
| `redis.enabled`                   | If external redis is used, set it to `false` | `true`                                    |
| `redis.password`                  | Redis password                               | _random 10 character alphanumeric string_ |
| `redis.sentinel.enabled`          | Enable sentinel containers                   | `true`                                    |
| `redis.sentinel.usePassword`      | Use password for sentinel containers         | `false`                                   |
| `externalRedis.host`              | Host of the external redis                   | `nil`                                     |
| `externalRedis.port`              | Port of the external redis                   | `6379`                                    |
| `externalRedis.password`          | Password for the external redis              | `nil`                                     |
| `externalRedis.sentinel`          | Using sentinels                              | `false`                                   |
| `externalRedis.databases.default` | Database to use by default                   | `0`                                       |
| `externalRedis.databases.cache`   | Database to use by cache                     | `1`                                       |

> See [Dependencies](#dependencies) for more.

### Database parameters 

| Parameter                         | Description                                 | Default                                   |
| --------------------------------- | ------------------------------------------- | ----------------------------------------- |
| `mariadb.enabled`                 | Deploy MariaDB container(s)                 | `true`                                    |
| `mariadb.auth.rootPassword`       | Password for the MariaDB `root` user        | _random 10 character alphanumeric string_ |
| `mariadb.auth.database`           | Database name to create                     | `invoiceninja`                            |
| `mariadb.auth.username`           | Database user to create                     | `invoiceninja`                            |
| `mariadb.auth.password`           | Password for the database                   | _random 10 character alphanumeric string_ |
| `externalDatabase.host`           | Host of the external database               | `nil`                                     |
| `externalDatabase.user`           | Existing username in the external db        | `invoiceninja`                            |
| `externalDatabase.password`       | Password for the above username             | `nil`                                     |
| `externalDatabase.database`       | Name of the existing database               | `invoiceninja`                            |
| `externalDatabase.port`           | Database port number                        | `3306`                                    |
| `externalDatabase.existingSecret` | Name of the database existing Secret Object | `nil`                                     |

> See [Dependencies](#dependencies) for more.

### Other parameters

| Parameter                  | Description                             | Default |
| -------------------------- | --------------------------------------- | ------- |
| `autoscaling.enabled`      | Enable autoscaling for Invoiceninja     | `false` |
| `autoscaling.minReplicas`  | Minimum number of Invoiceninja replicas | `1`     |
| `autoscaling.maxReplicas`  | Maximum number of Invoiceninja replicas | `11`    |
| `autoscaling.targetCPU`    | Target CPU utilization percentage       | `nil`   |
| `autoscaling.targetMemory` | Target Memory utilization percentage    | `nil`   |

## Installing with Arguments

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
helm install invoiceninja \
  --set appKey=changeit \
  --set replicaCount=3 \
  --set nginx.replicaCount=3 \
  --set redis.cluster.slaveCount=3 \
  --set redis.password=changeit \
  --set mariadb.auth.rootPassword=changeit \
  --set mariadb.auth.password=changeit \
  invoiceninja/invoiceninja
```

The above command sets the number of replicas to 3 for a highly available (HA) setup. Note that you would need to use an external DB such as MariaDB Galera for a full HA production setup.

Alternatively, a YAML file that specifies the values for the parameters can be provided while [installing](https://helm.sh/docs/helm/helm_install/) the chart. For example,

```bash
helm install invoiceninja -f values.yaml invoiceninja/invoiceninja
```

## Upgrading

Nothing yet.
