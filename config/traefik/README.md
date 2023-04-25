# Docker for [Invoice Ninja](https://www.invoiceninja.com/) using [Traefik proxy](https://doc.traefik.io/traefik/)

## Why use Traefik Proxy

Traefik is an open-source Edge Router that makes publishing your services a fun and easy experience. It receives requests on behalf of your system and finds out which components are responsible for handling them.

What sets Traefik apart, besides its many features, is that it automatically discovers the right configuration for your services. The magic happens when Traefik inspects your infrastructure, where it finds relevant information and discovers which service serves which request.

Traefik in combination with [Cloudflare](https://cloudflare.com) receives and serves all SSL certificates for each service domain automaticly by issuing a wildcard SSL certificate.

## Requirements

1. A domain using the Cloudflare nameservers [Cloudflare Docs](https://developers.cloudflare.com/registrar/get-started/transfer-domain-to-cloudflare/)
1. An API token with at least the following permissions: `Zone:Read, Zone Settings:Read, DNS:Edit` [Cloudflare Docs](https://developers.cloudflare.com/fundamentals/api/)

## Usage

1. Copy the [docker-compose.override.yml](./docker-compose.override.yml) to the repositorie's root directory
1. Set the Traefik proxy vars in the [env](../../env) file
1. Update the basic-auth username and password in [dynamic.yml](./config/dynamic.yml)
1. Start the docker compose stack

A few seconds later, you should be able to visit `https://${APP_URL_DOMAIN}:8080/dashboard/` and should be prompted for a username and password. If you have not changed it, it should be `username` and `EncryptedPassword`.

If there are no errors listed, you should be able to visit InvoiceNinja via `${APP_URL}`.

## Troubleshooting

If anything does not work as expected, consider checking Traefik's container logs via

```bash
docker compose logs -tf traefik
```
