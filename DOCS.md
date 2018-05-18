Use the Volume-cache plugin to preserve files and directories between builds.
Because it uses a mounted volume, it requires repositories using it to enable the *"Trusted"* flag.

## Config
The following parameters are used to configure the plugin:
- **restore** - instruct plugin to restore cache, can be `true` or `false`
- **rebuild** - instruct plugin to rebuild cache, can be `true` or `false`
- **mount** - list of folders or files to cache
- **ttl** - maximum cache lifetime in days
- **cache_key** - list of environment variables to use for constructing the cache path

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

## Using the cache_key option
By default, this plugin uses the repo owner, repo name, and job number to construct a cache key. Say the repository owner is `foo`, the repository name is `bar`, and the job number is `1`,
the cache key (folder) the plugin will use for the build will be `foo/bar/1`.
If this is not optimal for your specific situation, it is possible to modify the cache key. For example, let's say that your project differs quite a bit between different branches, you may want to include the branch somewhere in the cache key:

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
    cache_key: [ DRONE_REPO_OWNER, DRONE_REPO_NAME, DRONE_BRANCH, DRONE_JOB_NUMBER ]
```

This would lead to the following cache key if a build is triggered for the master branch (and the rest of the situation is the same as the example illustrated above): `foo/bar/master/1`.

In theory you could even use this to share cache between different projects, but extreme caution is advised doing so.

## Using the `.cache_key` file
Instead of using a `cache_key` option in your Drone yaml file, you may generate a cache key and write it to the `.cache_key` file in the root of your repo. If a `.cache_key` file is present, the first [NAME_MAX](https://www.gnu.org/software/libc/manual/html_node/Limits-for-Files.html) characters of the first line of this file is read and (by default) its MD5 is used as the actual key for sanitization purposes. You may disable MD5'ing by setting `cache_key_disable_sanitize: true`.

This feature allows you to generate the cache key dynamically (e.g. by calculating the checksum of your `package.json`). Note that if a `.cache_key` file is present, it overrides your settings of `cache_key`.

```yaml
pipeline:
  build:
    image: ubuntu
    commands:
      - [...]
      - echo -n "my custom cache key" > .cache_key
  restore-cache:
    image: drillster/drone-volume-cache
    restore: true
    mount:
      - ./node_modules
    # Mount the cache volume, needs "Trusted"
    volumes:
      - /tmp/cache:/cache
```

## Clearing Cache
Should you want to clear the cache for a project, you can do so by including `[CLEAR CACHE]` in the commit message. The entire cache folder for the project will be cleared before it is restored. The rebuilding of cache will proceed as normal.

## Skipping Cache
If you want to run a build without using cache, put `[NO CACHE]` in the commit message. Both the restoring and rebuilding of cache will be skipped. Your cache will remain intact.