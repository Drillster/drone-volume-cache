#!/bin/bash
set -e

if [ -z "$PLUGIN_MOUNT" ]; then
    echo "Specify folders to cache in the mount property! Plugin won't do anything!"
    exit 0
fi

if [[ $DRONE_COMMIT_MESSAGE == *"[CLEAR CACHE]"* && -n "$PLUGIN_RESTORE" && "$PLUGIN_RESTORE" == "true" ]]; then
    if [ -d "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME" ]; then
        echo "Found [CLEAR CACHE] in commit message, clearing cache..."
        rm -rf "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER"
        exit 0
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
            echo "Rebuilding cache for folder $source..."
            mkdir -p "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/$source" && \
                rsync -aHA --delete "$source/" "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/$source"
        elif [ -f "$source" ]; then
            echo "Rebuilding cache for file $source..."
            rsync -aHA --delete "$source" "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/"
        else
            echo "$source does not exist, removing from cached folder..."
            rm -rf "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/$source"
        fi
    done
elif [[ -n "$PLUGIN_RESTORE" && "$PLUGIN_RESTORE" == "true" ]]; then
    # Remove files older than TTL
    if [[ -n "$PLUGIN_TTL" && "$PLUGIN_TTL" > "0" ]]; then
        if [[ $PLUGIN_TTL =~ ^[0-9]+$ ]]; then
            echo "Removing files and (empty) folders older than $PLUGIN_TTL days..."
            find "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER" -type f -ctime +$PLUGIN_TTL -delete
            find "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER" -type d -ctime +$PLUGIN_TTL -empty -delete
        else
            echo "Invalid value for ttl, please enter a positive integer. Plugin will ignore ttl."
        fi
    fi
    # Restore from cache
    for source in "${SOURCES[@]}"; do
        if [ -d "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/$source" ]; then
            echo "Restoring cache for folder $source..."
            mkdir -p "$source" && \
                rsync -aHA --delete "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/$source/" "$source"
        elif [ -f "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/$source" ]; then
            echo "Restoring cache for file $source..."
            rsync -aHA --delete "/cache/$DRONE_REPO_OWNER/$DRONE_REPO_NAME/$DRONE_JOB_NUMBER/$source" "./"
        else
            echo "No cache for $source"
        fi
    done
else
    echo "No restore or rebuild flag specified, plugin won't do anything!"
fi
