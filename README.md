# docker-minecraft-bedrock

## Build
```
docker build -t minecraft-bedrock-server:1.7.0.13 .
```

## Run
```
docker run \
    --name minecraft-bedrock \
    --interactive \
    --tty \
    --detach \
    --restart unless-stopped \
    --publish 19132:19132/udp \
    --publish 19132:19132 \
    --volume minecraft-bedrock:/bedrock \
    minecraft-bedrock-server:1.7.0.13
```

### Run console commands
Type `help` followed by 1-15 to see the available console commands.
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

## Customize server.properties
```
docker cp minecraft-bedrock:/minecraft/server.properties .
```

Edit `server.properties` to taste.
Copy your modified `server.properties` to the data volume, then restart the container.
```
docker cp ./server.properties minecraft-bedrock:/data/
docker restart minecraft-bedrock
```
