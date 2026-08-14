# Wikimedia dev debian images with Dockerfiles
This tool and script helps to create arm/(Mac M1 compatible) images for the developer environment on the Wikimedia framework. Which helps with performance and debugging on arm machines.
 
## How to use Arm Docker images in your project

- Run the following to create local images

    ```shell
    ./build.sh
    ```

- Create `docker-compose.override.yml` file in your core project and put the following in:
    ```yaml
    version: '3.7'
    services:
      mediawiki:
        image: docker-registry.wikimedia.org/dev/bookworm-php83-fpm:1.0.0-arm1
      mediawiki-web:
        image: docker-registry.wikimedia.org/dev/bookworm-apache2:1.0.1-arm1
      mediawiki-jobrunner:
        image: docker-registry.wikimedia.org/dev/bookworm-php83-jobrunner:1.0.0-arm1
    ```

- Shutdown the current containers:
  ```shell
  docker-compose down
  ```

- Start the containers:
  ```shell
  docker-compose up -d
  ```

## test-kitchen (arm64)

`build.sh` also builds an arm64 image of the Wikimedia `test-kitchen` service
(used by the `TestKitchen` MediaWiki extension devserver). Upstream ships an
amd64-only image, so on Apple silicon it runs under qemu emulation.

The build lives in `test-kitchen/`. `build-test-kitchen.sh` clones the service
source into `test-kitchen/src/` (gitignored), swaps the amd64-only WMF
`nodejs22-slim` Blubber base for the multi-arch official `node:22-slim`, and
builds a native arm64 image:

```
docker-registry.wikimedia.org/repos/data-engineering/test-kitchen:latest-dev-arm1
```

Build just this image on its own (also runs as part of `./build.sh`):

```shell
./test-kitchen/build-test-kitchen.sh
```

Set `TK_REF` to pin a branch, tag, or commit of the service source, e.g.
`TK_REF=v1.2.3 ./test-kitchen/build-test-kitchen.sh`.

The `test-kitchen` service is defined by the `TestKitchen` extension devserver
compose, not by MediaWiki core, so point it at the arm image with an `image:`
override in that service's `docker-compose.override.yml`:

```yaml
services:
  test-kitchen:
    image: docker-registry.wikimedia.org/repos/data-engineering/test-kitchen:latest-dev-arm1
```
