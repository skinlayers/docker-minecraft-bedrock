#!/bin/bash
set -e
[ "${DEBUG:-}" = "true" ] && set -v

# 1. Symlink critical resources safely
for dir in /minecraft/*/; do
    dir_base="$(basename "$dir")"
    mkdir -p "/data/$dir_base"

    for subdir in "/minecraft/$dir_base"/*/; do
        target_name="$(basename "$subdir")"
        ln -sf "$subdir" "/data/$dir_base/$target_name"
    done
done

# Cleanup broken symlinks only
find /data/ -xtype l -delete

# 2. Run Remco (ensure your remco config is set to onetime = true)
if [ -x /bin/remco ]; then
    /bin/remco
elif [ -x /usr/local/bin/remco ]; then
    /usr/local/bin/remco
else
    echo "Warning: remco not found, skipping configuration templating."
fi

# 3. Generate permissions.json from roles
# Expected format: BEDROCK_OPERATORS=123,456
if env | grep -qE '^BEDROCK_(OPERATORS|MEMBERS|VISITORS)='; then
    echo "Generating permissions.json from environment roles..."
    {
        printf '[\n'
        first_entry=true

        for role in BEDROCK_OPERATORS BEDROCK_MEMBERS BEDROCK_VISITORS; do
            list="${!role}"
            # Map 'BEDROCK_OPERATORS' -> 'operator', etc.
            role_name="${role#BEDROCK_}"
            role_name="${role_name,,}"
            role_name="${role_name%s}"

            if [ -n "$list" ]; then
                IFS=',' read -ra xuids <<< "$list"
                for xuid in "${xuids[@]}"; do
                    if [ -n "$xuid" ]; then
                        $first_entry || printf ',\n'
                        first_entry=false
                        printf '  { "permission": "%s", "xuid": "%s" }' "$role_name" "$xuid"
                    fi
                done
            fi
        done
        printf '\n]\n'
    } > /data/permissions.json
fi

# 4. Generate allowlist.json
# Format: BEDROCK_ALLOWLIST_PlayerName=XUID[,ignoresPlayerLimit]
if env | grep -q "^BEDROCK_ALLOWLIST_"; then
    echo "Generating allowlist.json..."
    {
        printf '[\n'
        first=true
        while IFS='=' read -r key value; do
            [[ $key != BEDROCK_ALLOWLIST_* ]] && continue
            [ -z "$value" ] && continue

            $first || printf ',\n'
            first=false

            name="${key#BEDROCK_ALLOWLIST_}"
            xuid="${value%%,*}"
            ignores="false"
            [[ "$value" == *,* ]] && ignores="${value##*,}"

            printf '  { "ignoresPlayerLimit": %s, "name": "%s", "xuid": "%s" }' "$ignores" "$name" "$xuid"
        done < <(env)
        printf '\n]\n'
    } > /data/allowlist.json
fi

# 5. Final Handover
echo "Starting Bedrock Server..."
exec "$@"
