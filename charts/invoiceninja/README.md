# Invoice Ninja Helm Chart

This helm chart installs Invoice Ninja (IN) and its dependencies into a running
Kubernetes cluster.

The chart installs the [Invoice Ninja](https://hub.docker.com/r/invoiceninja/invoiceninja) docker image.

Please read [Upgrading](#upgrading) section before upgrading MAJOR versions.

## Dependencies

- The Bitnami [common](https://github.com/bitnami/charts/tree/master/bitnami/common) helm chart
- The Bitnami [mariadb](https://github.com/bitnami/charts/tree/master/bitnami/mariadb) helm chart
- The Bitnami [nginx](https://github.com/bitnami/charts/tree/master/bitnami/nginx) helm chart
- The Bitnami [redis](https://github.com/bitnami/charts/tree/master/bitnami/redis) helm chart
- Tested on Kubernetes 1.19+

## Installing the Chart

To install the chart with the release name `invoiceninja`:

```bash
helm repo add invoiceninja https://invoiceninja.github.io/dockerfiles
helm install invoiceninja invoiceninja/invoiceninja --set appKey=changeit --set mariadb.auth.rootPassword=changeit --set mariadb.auth.password=changeit --set redis.auth.password=changeit
```

The command deploys Invoice Ninja on the Kubernetes cluster in the default namespace. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `invoiceninja` deployment:

```bash
helm delete invoiceninja
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

The following table lists the configurable parameters of the Invoice Ninja chart and their default values.

> NOTE: You MUST set any values that default to random or risk losing access after an upgrade. See how [here](#installing-with-arguments)

### Global Configuration

The following table shows the configuration options for the Invoice Ninja helm chart:

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

### Invoice Ninja container parameters

| Parameter                | Description                                                                   | Default                                                 |
| ------------------------ | ----------------------------------------------------------------------------- | ------------------------------------------------------- |
| `image.registry`         | Invoice Ninja image registry                                                  | `docker.io`                                             |
| `image.repository`       | Invoice Ninja image name                                                      | `invoiceninja/invoiceninja`                             |
| `image.tag`              | Invoice Ninja image tag                                                       | Check `values.yaml` file                                |
| `image.pullPolicy`       | Invoice Ninja image pull policy                                               | `IfNotPresent`                                          |
| `image.pullSecrets`      | Specify docker-registry secret names as an array                              | `[]` (does not add image pull secrets to deployed pods) |
| `image.debug`            | Specify if debug logs should be enabled                                       | `false`                                                 |
| `debug`                  | Turn on debug mode on Invoice Ninja                                           | `false`                                                 |
| `appKey`                 | Laravel Application Key (ignored if existing secret is provided)              | _random 32 character alphanumeric string_               |
| `appURL`                 | Override Laravel Application URL (automatically set if blank)                 | `""`                                                    |
| `userEmail`              | Initial user email address                                                    | `admin@example.com`                                     |
| `userPassword`           | Initial user password (ignored if existing secret is provided)                | `changeme!`                                             |
| `logChannel`             | Name of log channel to use                                                    | `nil`                                                   |
| `broadcastDriver`        | Name of broadcast driver to use                                               | `nil`                                                   |
| `cacheDriver`            | Name of cache driver to use                                                   | `nil`                                                   |
| `sessionDriver`          | Name of session driver to use                                                 | `nil`                                                   |
| `queueConnection`        | Name of queue connection to use                                               | `nil`                                                   |
| `pdfGenerator`           | PDF generation method (Allowed values: `snappdf` or `phantom`)                | `snappdf`                                               |
| `mailer`                 | Name of the mailer to use (log, smtp, etc.)                                   | `log`                                                   |
| `requireHttps`           | Force HTTPS for internal connections to Invoice Ninja (see #349)              | `false`                                                 |
| `existingSecret`         | Use existing secret that contain the keys `APP_KEY` and `IN_PASSWORD`         | `nil`                                                   |
| `extraEnvVars`           | Extra environment variables to be set on Invoice Ninja container              | `{}`                                                    |
| `extraEnvVarsCM`         | Name of existing ConfigMap containing extra env vars                          | `nil`                                                   |
| `extraEnvVarsSecret`     | Name of existing Secret containing extra env vars                             | `nil`                                                   |
| `trustedProxy`           | List of trusted proxies for Invoice Ninja to communicate with the nginx proxy | `'*'`                                                   |
| `extraVolumeMounts`      | Additional volume mounts                                                      | `[]`                                                    |
| `resources`              | The resources for the Invoice Ninja container                                 | `{}`                                                    |
| `livenessProbe`          | Liveness probe configuration for Invoice Ninja                                | Check `values.yaml` file                                |
| `readinessProbe`         | Readiness probe configuration for Invoice Ninja                               | Check `values.yaml` file                                |
| `containerPorts.fastcgi` | FastCGI port to expose at container level                                     | `9000`                                                  |

### Inline web server container parameters (only used when `nginx.enabled` is **not** set to true)

| Parameter                | Description                                              | Default                                                 |
| ------------------------ | -------------------------------------------------------- | ------------------------------------------------------- |
| `http.image.registry`    | Nginx image registry                                     | `docker.io`                                             |
| `http.image.repository`  | Nginx image name                                         | `invoiceninja/invoiceninja`                             |
| `http.image.tag`         | Nginx image tag                                          | Check `values.yaml` file                                |
| `http.image.pullPolicy`  | Nginx image pull policy                                  | `IfNotPresent`                                          |
| `http.image.pullSecrets` | Specify docker-registry secret names as an array         | `[]` (does not add image pull secrets to deployed pods) |
| `http.image.debug`       | Specify if debug logs should be enabled                  | `false`                                                 |
| `extraEnvVars`           | Extra environment variables to be set on Nginx container | `{}`                                                    |
| `extraEnvVarsCM`         | Name of existing ConfigMap containing extra env vars     | `nil`                                                   |
| `extraEnvVarsSecret`     | Name of existing Secret containing extra env vars        | `nil`                                                   |
| `extraVolumeMounts`      | Additional volume mounts                                 | `[]`                                                    |
| `resources`              | The resources for the Nginx container                    | `{}`                                                    |
| `livenessProbe`          | Liveness probe configuration for Nginx                   | Check `values.yaml` file                                |
| `readinessProbe`         | Readiness probe configuration for Nginx                  | Check `values.yaml` file                                |
| `containerPorts.http`    | HTTP port to expose at container level                   | `9000`                                                  |
| `containerPorts.https`   | HTTPS port to expose at container level                  | `9000`                                                  |

### Invoice Ninja deployment parameters

| Parameter                   | Description                                                                               | Default                        |
| --------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------ |
| `replicaCount`              | Number of Invoice Ninja Pods to run                                                       | `1`                            |
| `serviceAccountName`        | Name of a service account for the Invoice Ninja pods                                      | `default`                      |
| `containerSecurityContext`  | Invoice Ninja containers' Security Context                                                | Check `values.yaml` file       |
| `podSecurityContext`        | Invoice Ninja pods' Security Context                                                      | Check `values.yaml` file       |
| `updateStrategy`            | Set up update strategy                                                                    | `RollingUpdate`                |
| `podAntiAffinityPreset`     | Pod anti-affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`  | `soft`                         |
| `nodeAffinityPreset.type`   | Node affinity preset type. Ignored if `affinity` is set. Allowed values: `soft` or `hard` | `""`                           |
| `nodeAffinityPreset.key`    | Node label key to match. Ignored if `affinity` is set.                                    | `""`                           |
| `nodeAffinityPreset.values` | Node label values to match. Ignored if `affinity` is set.                                 | `[]`                           |
| `affinity`                  | Affinity for pod assignment                                                               | `{}` (evaluated as a template) |
| `nodeSelector`              | Node labels for pod assignment                                                            | `{}` (evaluated as a template) |
| `tolerations`               | Tolerations for pod assignment                                                            | `[]` (evaluated as a template) |
| `podLabels`                 | Extra labels for Invoice Ninja pods                                                       | `{}`                           |
| `podAnnotations`            | Annotations for Invoice Ninja pods                                                        | `{}`                           |
| `extraVolumes`              | Additional volumes                                                                        | `[]`                           |

### Volume Permissions parameters

| Parameter                             | Description                                                                                                          | Default                                                 |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| `volumePermissions.enabled`           | Enable init container that changes the owner and group of the persistent volume(s) mountpoint to `runAsUser:fsGroup` | `false`                                                 |
| `volumePermissions.image.registry`    | Init container volume-permissions image registry                                                                     | `docker.io`                                             |
| `volumePermissions.image.repository`  | Init container volume-permissions image name                                                                         | `bitnami/bitnami-shell`                                 |
| `volumePermissions.image.tag`         | Init container volume-permissions image tag                                                                          | `"10"`                                                  |
| `volumePermissions.image.pullPolicy`  | Init container volume-permissions image pull policy                                                                  | `Always`                                                |
| `volumePermissions.image.pullSecrets` | Specify docker-registry secret names as an array                                                                     | `[]` (does not add image pull secrets to deployed pods) |
| `volumePermissions.resources`         | Init container volume-permissions resource                                                                           | `{}`                                                    |

### Exposure parameters

#### FastCGI

| Parameter                          | Description                                                                | Default                        |
| ---------------------------------- | -------------------------------------------------------------------------- | ------------------------------ |
| `service.type`                     | Kubernetes Service type                                                    | `ClusterIP`                    |
| `service.port`                     | Service FastCGI port                                                       | `9000`                         |
| `service.nodePort`                 | Kubernetes FastCGI node port                                               | `""`                           |
| `service.clusterIP`                | Invoice Ninja service clusterIP IP                                         | `None`                         |
| `service.loadBalancerSourceRanges` | Restricts access for LoadBalancer (only with `service.type: LoadBalancer`) | `[]`                           |
| `service.loadBalancerIP`           | loadBalancerIP if service type is `LoadBalancer`                           | `nil`                          |
| `service.externalTrafficPolicy`    | Enable client source IP preservation                                       | `Cluster`                      |
| `service.annotations`              | Service annotations                                                        | `{}` (evaluated as a template) |

#### Inline web server (only used when `nginx.enabled` is **not** set to true)

| Parameter                               | Description                                                                | Default                        |
| --------------------------------------- | -------------------------------------------------------------------------- | ------------------------------ |
| `service.http.type`                     | Kubernetes Service type                                                    | `ClusterIP`                    |
| `service.http.ports.http`               | Service HTTP port                                                          | `9000`                         |
| `service.http.ports.https`              | Service HTTPS port                                                         | `9000`                         |
| `service.http.nodePorts.http`           | Kubernetes HTTP node port                                                  | `""`                           |
| `service.http.nodePorts.https`          | Kubernetes HTTPS node port                                                 | `""`                           |
| `service.http.clusterIP`                | Invoice Ninja service clusterIP IP                                         | `None`                         |
| `service.http.loadBalancerSourceRanges` | Restricts access for LoadBalancer (only with `service.type: LoadBalancer`) | `[]`                           |
| `service.http.loadBalancerIP`           | loadBalancerIP if service type is `LoadBalancer`                           | `nil`                          |
| `service.http.externalTrafficPolicy`    | Enable client source IP preservation                                       | `Cluster`                      |
| `service.http.annotations`              | Service annotations                                                        | `{}` (evaluated as a template) |


### Ingress parameters 

#### Inline web server (only used when `nginx.enabled` is **not** set to true)

| Parameter                  | Description                                                                                           | Default                  |
| -------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------ |
| `ingress.enabled`          | Enable ingress                                                                                        | `true`                   |
| `ingress.certManager`      | Add the corresponding annotations for cert-manager integration                                        | `false`                  |
| `ingress.pathType`         | Ingress path type                                                                                     | `ImplementationSpecific` |
| `ingress.apiVersion`       | Force Ingress API version (automatically detected if not set)                                         | `nil`                    |
| `ingress.ingressClassName` | IngressClass that will be be used to implement the Ingress (Kubernetes 1.18+)                         | `nil`                    |
| `ingress.hostname`         | Default host for the ingress record                                                                   | `invoiceninja.local`     |
| `ingress.path`             | Default path for the ingress record                                                                   | `/`                      |
| `ingress.annotations`      | Additional custom annotations for the ingress record                                                  | `{}`                     |
| `ingress.tls`              | Enable TLS configuration for the host defined at `ingress.hostname` parameter                         | `false`                  |
| `ingress.extraHosts`       | An array with additional hostname(s) to be covered with the ingress record                            | `[]`                     |
| `ingress.extraPaths`       | An array with additional arbitrary paths that may need to be added to the ingress under the main host | `[]`                     |
| `ingress.extraTls`         | TLS configuration for additional hostname(s) to be covered with this ingress record                   | `[]`                     |
| `ingress.secrets`          | Custom TLS certificates as secrets                                                                    | `[]`                     |

#### Nginx sub-chart

| Parameter                            | Description                           | Default                                                |
| ------------------------------------ | ------------------------------------- | ------------------------------------------------------ |
| `nginx.enabled`                      | Deploy Nginx sub-chart                | `false`                                                |
| `nginx.service.type`                 | Kubernetes Service type               | `ClusterIP`                                            |
| `nginx.ingress.enabled`              | Enable ingress controller resource    | `true`                                                 |
| `nginx.ingress.hostname`             | Default host for the ingress resource | `invoiceninja.local`                                   |
| `nginx.existingServerBlockConfigmap` | Custom NGINX server block config map  | `{{ include "invoiceninja.nginx.serverBlockName" . }}` |
| `nginx.staticSitePVC`                | Name of Invoice Ninja public PVC      | `{{ include "invoiceninja.public.storageName" . }}`    |

> See [Dependencies](#dependencies) for more.

### Persistence parameters

| Parameter                           | Description                                         | Default           |
| ----------------------------------- | --------------------------------------------------- | ----------------- |
| `persistence.public.enabled`        | Enable persistence using PVC                        | `true`            |
| `persistence.public.existingClaim`  | Enable persistence using an existing PVC            | `nil`             |
| `persistence.public.storageClass`   | PVC Storage Class                                   | `nil`             |
| `persistence.public.accessModes`    | PVC Access Modes                                    | `[ReadWriteOnce]` |
| `persistence.public.size`           | PVC Storage Request                                 | `1Gi`             |
| `persistence.public.dataSource`     | PVC data source                                     | `{}`              |
| `persistence.storage.enabled`       | Enable persistence using PVC (only for FILE driver) | `false`           |
| `persistence.storage.existingClaim` | Enable persistence using an existing PVC            | `nil`             |
| `persistence.storage.storageClass`  | PVC Storage Class                                   | `nil`             |
| `persistence.storage.accessModes`   | PVC Access Modes                                    | `[ReadWriteMany]` |
| `persistence.storage.size`          | PVC Storage Request                                 | `5Gi`             |
| `persistence.storage.dataSource`    | PVC data source                                     | `{}`              |

> See `values.yaml` for more details.

### Redis parameters

| Parameter                         | Description                                  | Default                                   |
| --------------------------------- | -------------------------------------------- | ----------------------------------------- |
| `redis.enabled`                   | If external redis is used, set it to `false` | `true`                                    |
| `redis.auth.password`             | Redis password                               | _random 10 character alphanumeric string_ |
| `redis.auth.sentinel`             | Use password for sentinel containers         | `false`                                   |
| `redis.sentinel.enabled`          | Enable sentinel containers                   | `true`                                    |
| `redis.sentinel.quorum`           | Sentinel Quorum                              | `1`                                       |
| `redis.replica.replicaCount`      | Number of Redis replicas to deploy           | `1`                                       |
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

| Parameter                  | Description                              | Default |
| -------------------------- | ---------------------------------------- | ------- |
| `autoscaling.enabled`      | Enable autoscaling for Invoice Ninja     | `false` |
| `autoscaling.minReplicas`  | Minimum number of Invoice Ninja replicas | `1`     |
| `autoscaling.maxReplicas`  | Maximum number of Invoice Ninja replicas | `11`    |
| `autoscaling.targetCPU`    | Target CPU utilization percentage        | `nil`   |
| `autoscaling.targetMemory` | Target Memory utilization percentage     | `nil`   |

## Installing with Arguments

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
helm install invoiceninja \
  --set appKey=changeit \
  --set replicaCount=3 \
  --set persistence.public.accessModes[0]=ReadWriteMany
  --set redis.auth.password=changeit \
  --set redis.sentinel.quorum=2 \
  --set redis.replica.replicaCount=3 \
  --set mariadb.auth.rootPassword=changeit \
  --set mariadb.auth.password=changeit \
  invoiceninja/invoiceninja
```

The above command sets the number of replicas to 3 for a highly available (HA) setup and uses a `ReadWriteMany` volume. Note that you would need to use an external DB such as MariaDB Galera for a full HA production setup. For a production environment, it is recommended that you spin up the required databases in a separate Helm Chart to decouple the upgrading process.

Alternatively, a YAML file that specifies the values for the parameters can be provided while [installing](https://helm.sh/docs/helm/helm_install/) the chart. For example,

```yaml
# values.yaml
appKey: changeit
persistence:
  public:
    accessModes:
      - ReadWriteMany
redis:
  auth:
    password: changeit
mariadb:
  auth:
    rootPassword: changeit
    password: changeit
```

```bash
helm install invoiceninja -f values.yaml invoiceninja/invoiceninja
```

## Setting Environment Variables

Should you need to inject any environment variables such as those in [here](https://github.com/invoiceninja/dockerfiles/blob/master/env) into the `invoiceninja` container, you can use the `extraEnvVars` option:

```yaml
# ... values.yaml file
# In this example, we are setting the SMTP MAIL_HOST to be 'smtp.mailtrap.io'
extraEnvVars:
  - name: MAIL_HOST
    value: 'smtp.mailtrap.io' # all values must be strings, so other types must be surrounded in quotes
```

Alternatively you can provide the name of an existing `configmap` or `secret` object:

```bash
kubectl create configmap examplemap --from-literal=MAIL_HOST='smtp.mailtrap.io'
```

```yaml
# ... values.yaml file
extraEnvVarsCM: examplemap
```

## Inline webserver vs Nginx sub-chart

Since there are many people without access to a `ReadWriteMany` volume, the inline Nginx web server will allow you to use a `ReadWriteOnce` public volume limited to 1 IN replica.

If you have the ability to use `ReadWriteMany` persistent volume, you can choose between the two by setting the `nginx.enabled` parameter. Setting `nginx.enabled` to true will enable the Nginx sub-chart and will provide you with some additional features, such as:

- independent scaling of Nginx and IN pods
- separate resource limits/requests
- other features available from the sub-chart

## Upgrading

### To 0.10.0

The following chart dependencies have been upgraded.
- MariaDB 
- Redis
- Nginx
- Bitnami common

Please take note that this upgrade MariaDB from 10.5 to 10.6. Please backup your database before proceeding.

### To 0.8.0

To improve the accessibility of this chart to regular users. Some of the defaults have been changed. This include:

- `persistence.public.accessModes` now defaults to `ReadWriteOnce`.
- `nginx.enabled` now defaults to false.
- `redis.replica.replicaCount` and `redis.sentinel.quorum` now defaults to `1`.

Other changes:

- `snappdf` parameter has been replaced by `pdfGenerator`.

### To 0.7.0

- Redis chart dependency has been upgraded and may not be backwards compatible with previous versions. See [here](https://github.com/bitnami/charts/tree/master/bitnami/redis) for more info.
- Storage persitence defaults to `false`. Set to `true` if not using Redis or using FILE driver
