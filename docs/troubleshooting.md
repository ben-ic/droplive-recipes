# Troubleshooting recipes

Start with the first failing step. Do not add fields before an error asks for
them.

## DropLive found several build files

Select the upstream file and, for Compose, its main service:

```yaml
build:
  docker-compose: deploy/docker-compose.yml
  service: web
```

## The image builds but the application does not start

Run it with a read-only root filesystem. This is the most common failure.

```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp
      - /app/cache
    volumes:
      - data:/app/data
```

If startup writes a configuration file, generate it during the image build or
write it to a `tmpfs` path. If startup changes users, ownership, or files under
`/etc`, replace the entrypoint and perform that work during the build.

Do not disable the read-only root.

## The application starts but never becomes ready

Check the main port and health path:

```yaml
run:
  port: 3000
  health: /health
```

Use response text when HTTP 200 is not enough:

```yaml
run:
  health:
    path: /api/status
    contains:
      - '"ready":true'
```

## A required environment variable is missing

First decide who owns it:

- Put a public default in Docker Compose.
- Use a required Compose variable for a value a person must provide.
- Use the DropLive annotation for a generated owner credential.
- Use a companion for a database or cache connection.
- Use an emulator binding for a supported external service.

Never add a real secret to Git.

## An external API is required

Check [`capabilities/v1.yaml`](../capabilities/v1.yaml). If the capability is
present, declare an emulator binding. If it is absent, state the missing
capability in the pull request. Do not point the recipe at your own server.

## The emulator answers 401 for every call

The `seed` introduced an identity the dataset's tokens do not know, or the capability
was given no dataset at all. The emulator log names the vendor at startup.

A recipe cannot create identities; layer content over a reviewed `dataset` and let it
own the users and tokens. See [seeding](seeding.md).

## The project needs a database or cache

Declare a named companion:

```yaml
companions:
  database: postgres
```

Do not add a second application service with an arbitrary database image to the
recipe Compose file.

## The project needs privileged mode, host networking, or a writable root

These modes are not supported. Change the build or entrypoint so the project can
run without them. If the software fundamentally requires one of these modes, it
cannot run as a DropLive recipe.

## The validator rejects a base image

Pin the image by digest:

```dockerfile
FROM ghcr.io/example/image@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

Tags are mutable and are not accepted in recipe-owned Dockerfiles.

## Sample data breaks after an update

Use the application's API, official CLI, or official import format. Do not write
directly to private database tables. If the project has no stable import path,
remove `seed.sh`. Sample data is useful, but it must not make the recipe fragile.
