# docker-minecraft-bedrock
The latest official Minecraft Bedrock Edition server (alpha) running on an Ubuntu 18.04 Docker image.

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
whitelist add your-minecraft-username
```

### Detach from console
```
Ctrl-p
Ctrl-q
```

## Customize
The data files are copied to the `minecraft-bedrock-data` volume mounted at `/data`, while the originals are stored along with the executable at `/minecraft` in the base container. 

### server.properties
See https://minecraft.gamepedia.com/Server.properties#Bedrock_Edition_3

Copy the unmodified `server.properties` from the container to the Docker host.
```
docker cp minecraft-bedrock:/minecraft/server.properties .
```

Edit `server.properties` to taste.
Copy your modified `server.properties` to the data volume, then restart the container.
```
docker cp ./server.properties minecraft-bedrock:/data/
docker restart minecraft-bedrock
```

### Whitelist
whitelist.json example:
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
docker cp whitelist.json minecraft-bedrock:/data/
docker attach minecraft-bedrock
whitelist reload
Ctrl-p
Ctrl-q
```

### OPs
You can use https://mcuuid.net/ to find a player's UUID.
ops.json example:
```
[
  {
    "uuid": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
    "name": "SomeXBoxLiveHandle",
    "level": 4,
    "bypassesPlayerLimit": false
  },
  {
    "uuid": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
    "name": "AnotherXBoxLiveHandle",
    "level": 4,
    "bypassesPlayerLimit": false
  }
]
```

```
docker cp ops.json minecraft-bedrock:/data/
docker restart minecraft-bedrock
```
