#!/bin/bash
set -e

# Ensure symlinks to critical resources exist
for dir in behavior_packs definitions resource_packs structures; do
    if ! [ -a "/data/$dir" ]; then
        mkdir "/data/$dir"
    fi
    for subdir in /minecraft/$dir/*; do
        symlink="/data/$dir/$(basename $subdir)"
        if ! [ -a "$symlink" ]; then
            ln -s "$subdir" "$symlink"
        fi
    done
done


exec "$@"
