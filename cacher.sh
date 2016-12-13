#!/bin/bash

if [ -z "$PLUGIN_MOUNT" ]; then
    echo "Specify folders to cache in the mount property! Plugin won't do anything!"
    exit 0;
fi

IFS=','; read -ra SOURCES <<< "$PLUGIN_MOUNT"
if [ -n "$PLUGIN_REBUILD" ]; then
    # Create cache
    for source in "${SOURCES[@]}"; do
        echo "Rebuilding cache for $source..."
        mkdir -p "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$source" && \
            rsync -aHAX --delete "$source/" "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$source"
    done
elif [ -n "$PLUGIN_RESTORE" ]; then
    # Restore from cache
    for source in "${SOURCES[@]}"; do
        if [ -d "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$source" ]; then
            echo "Restoring cache for $source..."
            mkdir -p "$source" && \
                rsync -aHAX --delete "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$source/" "$source"
        else
            echo "No cache for $source"
        fi
    done
else
    echo "No restore or rebuild flag specified, plugin won't do anything!"
fi
