# docker-minecraft-bedrock
The latest official Minecraft Bedrock Edition server (alpha) running on an Ubuntu 24.04 Docker image.

https://minecraft.net/en-us/download/server/bedrock/

## Build
```
docker build -t minecraft-bedrock-server .
```

## Run
Long version:
```
docker run \
    --name minecraft-bedrock \
    --interactive \
    --tty \
    --detach \
    --restart unless-stopped \
    --publish 19132:19132/udp \
    --publish 19132:19132 \
    --volume minecraft-bedrock-data:/data \
    minecraft-bedrock-server
```

One-liner:
```
docker run --name minecraft-bedrock -itd --restart unless-stopped -p 19132:19132/udp -p 19132:19132 -v minecraft-bedrock-data:/data minecraft-bedrock-server
```

### Run console commands
See https://minecraft.gamepedia.com/Commands#Summary_of_commands
Type `help` followed by 1-15 to see the available console commands.
Example:
```
docker attach minecraft-bedrock
help 15
allowlist add your-minecraft-username
```

### Detach from console
```
Ctrl-p
Ctrl-q
```

## Customize
The data files are copied to the `minecraft-bedrock-data` volume mounted at `/data`, while the originals are stored along with the executable at `/minecraft` in the base container. 

### server.properties
See https://minecraft.gamepedia.com/Server.properties#Bedrock_Edition

Server properties are configured via environment variables at container startup using [remco](https://github.com/HeavyHorst/remco). Each property maps to an environment variable with the `BEDROCK_` prefix, uppercase name, and hyphens replaced by underscores. For example, `server-name` becomes `BEDROCK_SERVER_NAME`.

Extract the generated example env file to see all supported options and their defaults:
```
docker run --rm minecraft-bedrock-server cat /minecraft/example.env > example.env
```

Uncomment and modify the options you want, then pass the file at runtime:
```
docker run \
    --name minecraft-bedrock \
    --interactive \
    --tty \
    --detach \
    --restart unless-stopped \
    --publish 19132:19132/udp \
    --volume minecraft-bedrock-data:/data \
    --env-file example.env \
    minecraft-bedrock-server
```

Individual variables can also be set directly:
```
docker run ... \
    --env BEDROCK_SERVER_NAME="My Server" \
    --env BEDROCK_DIFFICULTY=hard \
    --env BEDROCK_ALLOW_LIST=true \
    minecraft-bedrock-server
```

Alternatively, you can bypass the templating and edit `server.properties` directly in the data volume:
```
docker cp minecraft-bedrock:/minecraft/server.properties .
# edit server.properties
docker cp ./server.properties minecraft-bedrock:/data/
docker restart minecraft-bedrock
```

### Whitelist
allowlist.json example:
```
[
  {
    "ignoresPlayerLimit": false,
    "name": "SomeXBoxLiveHandle",
    "xuid": "XXXXXXXXXXXXXXXX"
  },
  {
    "ignoresPlayerLimit": false,
    "name": "AnotherXBoxLiveHandle",
    "xuid": "XXXXXXXXXXXXXXXX"
  }
]
```

```
docker cp allowlist.json minecraft-bedrock:/data/
docker attach minecraft-bedrock
allowlist reload
Ctrl-p
Ctrl-q
```

### OPs
You can use https://mcuuid.net/ to find a player's UUID.
permissions.json example:
```
[
  {
    "permission": "operator",
    "xuid": "XXXXXXXXXXXXXXXX"
  },
  {
    "permission": "member",
    "xuid": "YYYYYYYYYYYYYYYY"
  },
  {
    "permission": "visitor",
    "xuid": "ZZZZZZZZZZZZZZZZ"
  }
]
```

```
docker cp permissions.json minecraft-bedrock:/data/
docker restart minecraft-bedrock
```
