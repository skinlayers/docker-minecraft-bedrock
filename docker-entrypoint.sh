#!/bin/bash
set -e
set -v

# Ensure symlinks to critical resources exist
for dir in /minecraft/*/; do
    dir_base="$(basename $dir)"
    if ! [ -e "/data/$dir_base" ]; then
        mkdir "/data/$dir_base"
    fi
    for subdir in /minecraft/$dir_base/*/; do
        symlink="/data/$dir_base/$(basename $subdir)"
        if ! [ -e "$symlink" ]; then
            ln -s "$subdir" "$symlink"
        fi
    done
done

# Clean up old/broken symlinks and empty directories
#for subdir in /data/*/*; do
#    if [ -L "$subdir" ]; then
#        if ! [ -e "$subdir" ]; then
#            rm "$subdir"
#        fi
#    fi
#done
find /data/ -xtype l -delete
find /data/ -empty -type d -delete


exec "$@"
