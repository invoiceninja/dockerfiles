{{/*
Return the proper image name
*/}}
{{- define "invoiceninja.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "invoiceninja.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.volumePermissions.image) "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "invoiceninja.volumePermissions.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.volumePermissions.image "global" .Values.global) }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "invoiceninja.mariadb.fullname" -}}
{{- printf "%s-%s" .Release.Name "mariadb" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "invoiceninja.nginx.fullname" -}}
{{- printf "%s-%s" .Release.Name "nginx" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "invoiceninja.redis.fullname" -}}
{{- printf "%s-%s" .Release.Name "redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create the name of the service account to use
*/}}
{{- define "invoiceninja.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
{{- default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Storage Class
*/}}
{{- define "invoiceninja.public.storageClass" -}}
{{- include "common.storage.class" (dict "persistence" .Values.persistence.public "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Storage Class
*/}}
{{- define "invoiceninja.storage.storageClass" -}}
{{- include "common.storage.class" (dict "persistence" .Values.persistence.storage "global" .Values.global) -}}
{{- end -}}

{{/*
Return the proper Storage Name
*/}}
{{- define "invoiceninja.public.storageName" -}}
{{- printf "%s-%s" .Release.Name "public" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper Storage Name
*/}}
{{- define "invoiceninja.storage.storageName" -}}
{{- printf "%s-%s" .Release.Name "storage" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the MariaDB Hostname
*/}}
{{- define "invoiceninja.databaseHost" -}}
{{- if .Values.mariadb.enabled }}
    {{- if eq .Values.mariadb.architecture "replication" }}
        {{- printf "%s-%s" (include "invoiceninja.mariadb.fullname" .) "primary" | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
        {{- printf "%s" (include "invoiceninja.mariadb.fullname" .) -}}
    {{- end -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the MariaDB Port
*/}}
{{- define "invoiceninja.databasePort" -}}
{{- if .Values.mariadb.enabled }}
    {{- printf "3306" -}}
{{- else -}}
    {{- printf "%d" (.Values.externalDatabase.port | int ) -}}
{{- end -}}
{{- end -}}

{{/*
Return the MariaDB Database Name
*/}}
{{- define "invoiceninja.databaseName" -}}
{{- if .Values.mariadb.enabled }}
    {{- printf "%s" .Values.mariadb.auth.database -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
Return the MariaDB User
*/}}
{{- define "invoiceninja.databaseUser" -}}
{{- if .Values.mariadb.enabled }}
    {{- printf "%s" .Values.mariadb.auth.username -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.user -}}
{{- end -}}
{{- end -}}

{{/*
Return the MariaDB Secret Name
*/}}
{{- define "invoiceninja.databaseSecretName" -}}
{{- if .Values.externalDatabase.existingSecret -}}
    {{- printf "%s" .Values.externalDatabase.existingSecret -}}
{{- else -}}
    {{- printf "%s" (include "invoiceninja.mariadb.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis Hostname
*/}}
{{- define "invoiceninja.redisHost" -}}
{{- if .Values.redis.enabled }}
    {{- if .Values.redis.sentinel.enabled }}
    {{- printf "%s-%s" (include "invoiceninja.redis.fullname" .) "headless" | trunc 63 | trimSuffix "-" -}}
    {{- else }}
    {{- printf "%s-%s" (include "invoiceninja.redis.fullname" .) "master" | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
{{- else -}}
    {{- printf "%s" .Values.externalRedis.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis Port
*/}}
{{- define "invoiceninja.redisPort" -}}
{{- if .Values.redis.enabled }}
    {{- if .Values.redis.sentinel.enabled }}
    {{- printf "26379" -}}
    {{- else }}
    {{- printf "6379" -}}
    {{- end -}}
{{- else -}}
    {{- printf "%d" (.Values.externalRedis.port | int ) -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis Database
*/}}
{{- define "invoiceninja.redisDatabase" -}}
{{- if .Values.redis.enabled }}
    {{- printf "0" -}}
{{- else -}}
    {{- printf "%s" .Values.externalRedis.databases.default -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis Database
*/}}
{{- define "invoiceninja.redisCacheDatabase" -}}
{{- if .Values.redis.enabled }}
    {{- printf "1" -}}
{{- else -}}
    {{- printf "%s" .Values.externalRedis.databases.cache -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis Secret Name
*/}}
{{- define "invoiceninja.redisSecretName" -}}
{{- if .Values.externalRedis.existingSecret -}}
    {{- printf "%s" .Values.externalRedis.existingSecret -}}
{{- else -}}
    {{- printf "%s" (include "invoiceninja.redis.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the Broadcast Connection Name
*/}}
{{- define "invoiceninja.redisBroadcastConnection" -}}
{{- if or (and .Values.redis.enabled .Values.redis.sentinel.enabled) (and .Values.externalRedis.host .Values.externalRedis.sentinel) }}
    {{- printf "sentinel-default" -}}
{{- else -}}
    {{- printf "default" -}}
{{- end -}}
{{- end -}}

{{/*
Return the Cache Connection Name
*/}}
{{- define "invoiceninja.redisCacheConnection" -}}
{{- if or (and .Values.redis.enabled .Values.redis.sentinel.enabled) (and .Values.externalRedis.host .Values.externalRedis.sentinel) }}
    {{- printf "sentinel-cache" -}}
{{- else -}}
    {{- printf "cache" -}}
{{- end -}}
{{- end -}}

{{/*
Return the Queue Connection Name
*/}}
{{- define "invoiceninja.redisQueueConnection" -}}
{{- if or (and .Values.redis.enabled .Values.redis.sentinel.enabled) (and .Values.externalRedis.host .Values.externalRedis.sentinel) }}
    {{- printf "sentinel-default" -}}
{{- else -}}
    {{- printf "default" -}}
{{- end -}}
{{- end -}}

{{/*
Return the Session Connection Name
*/}}
{{- define "invoiceninja.redisSessionConnection" -}}
{{- if or (and .Values.redis.enabled .Values.redis.sentinel.enabled) (and .Values.externalRedis.host .Values.externalRedis.sentinel) }}
    {{- printf "sentinel-default" -}}
{{- else -}}
    {{- printf "default" -}}
{{- end -}}
{{- end -}}
