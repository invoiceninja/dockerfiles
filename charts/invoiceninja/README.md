# Invoice Ninja Helm Chart

This chart deploys the Debian Invoice Ninja stack based on `debian/docker-compose.yml`:
- `app` (php-fpm + supervisor)
- `nginx`
- `mysql`
- `redis`

## Install

```bash
helm install invoiceninja ./charts/invoiceninja \
  -n invoiceninja \
  --create-namespace \
  --set secret.appKey='base64:YOUR_APP_KEY' \
  --set env.appUrl='http://invoiceninja.local'
```

## Upgrade

```bash
helm upgrade invoiceninja ./charts/invoiceninja \
  -n invoiceninja \
  --set secret.appKey='base64:YOUR_APP_KEY' \
  --set env.appUrl='http://invoiceninja.local'
```

## Access

```bash
kubectl -n invoiceninja port-forward svc/invoiceninja-nginx 8080:80
```

Open http://127.0.0.1:8080

## Persistence

Persistence is disabled by default so the chart works on clusters without a default StorageClass.

To enable persistence, set:
- `persistence.appPublic.enabled=true`
- `persistence.appStorage.enabled=true`
- `persistence.mysqlData.enabled=true`
- `persistence.redisData.enabled=true`

Optionally set `storageClassName` for each claim.
