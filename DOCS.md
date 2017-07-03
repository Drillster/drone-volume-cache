Use the Volume-cache plugin to preserve files and directories between builds.
Because it uses a mounted volume, it requires repositories using it to enable the *"Trusted"* flag.

## Config
The following parameters are used to configure the plugin:
- **restore** - instruct plugin to restore cache, can be `true` or `false`
- **rebuild** - instruct plugin to rebuild cache, can be `true` or `false`
- **mount** - list of folders or files to cache
- **ttl** - maximum cache lifetime in days

## Examples
```yaml
pipeline:
  restore-cache:
    image: drillster/drone-volume-cache
    restore: true
    mount:
      - ./node_modules
    # Mount the cache volume, needs "Trusted"
    volumes:
      - /tmp/cache:/cache

  build:
    image: node
    commands:
      - npm install

  rebuild-cache:
    image: drillster/drone-volume-cache
    rebuild: true
    mount:
      - ./node_modules
    # Mount the cache volume, needs "Trusted"
    volumes:
      - /tmp/cache:/cache
```

The example above illustrates a typical Node.js project Drone configuration. It caches the `./node_modules` directory to a mounted volume on the host system: `/tmp/cache`. This prevents `npm` from downloading and installing the dependencies for every build.

## Using cache lifetime
It is possible to limit the lifetime of cached files and folders.

```yaml
pipeline:
  restore-cache:
    image: drillster/drone-volume-cache
    restore: true
    mount:
      - ./node_modules
    # Mount the cache volume, needs "Trusted"
    volumes:
      - /tmp/cache:/cache
    ttl: 7
```

The example above shows a situation where cached items older than 7 days will not be restored (they will be removed instead). Only the restore step needs the `ttl` parameter.

## Clearing Cache
Should you want to clear the cache for a project, you can do so by including `[CLEAR CACHE]` in the commit message. The entire cache folder for the project will be cleared before it is restored. The rebuilding of cache will proceed as normal.

## Skipping Cache
If you want to run a build without using cache, put `[NO CACHE]` in the commit message. Both the restoring and rebuilding of cache will be skipped. Your cache will remain intact.