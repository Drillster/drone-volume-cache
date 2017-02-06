#!/bin/bash
set -e

if [ -z "$PLUGIN_MOUNT" ]; then
    echo "Specify folders to cache in the mount property! Plugin won't do anything!"
    exit 0
fi

if [[ $DRONE_COMMIT_MESSAGE == *"[CLEAR CACHE]"* && -n "$PLUGIN_RESTORE" && "$PLUGIN_RESTORE" == "true" ]]; then
    if [ -d "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME" ]; then
        echo "Found [CLEAR CACHE] in commit message, clearing cache!"
        rm -rf "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER"
    fi
fi

if [[ $DRONE_COMMIT_MESSAGE == *"[NO CACHE]"* ]]; then
    echo "Found [NO CACHE] in commit message, skipping cache restore and rebuild!"
    exit 0
fi

IFS=','; read -ra SOURCES <<< "$PLUGIN_MOUNT"
if [[ -n "$PLUGIN_REBUILD" && "$PLUGIN_REBUILD" == "true" ]]; then
    # Create cache
    for source in "${SOURCES[@]}"; do
        if [ -d "$source" ]; then
            echo "Rebuilding cache for $source..."
            mkdir -p "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/$source" && \
                rsync -aHAX --delete "$source/" "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/$source"
        else
            echo "$source does not exist, removing from cached folder..."
            rm -rf "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/$source"
        fi
    done
elif [[ -n "$PLUGIN_RESTORE" && "$PLUGIN_RESTORE" == "true" ]]; then
    # Restore from cache
    for source in "${SOURCES[@]}"; do
        if [ -d "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/$source" ]; then
            echo "Restoring cache for $source..."
            mkdir -p "$source" && \
                rsync -aHAX --delete "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/$source/" "$source"
        else
            echo "No cache for $source"
        fi
    done
else
    echo "No restore or rebuild flag specified, plugin won't do anything!"
fi
