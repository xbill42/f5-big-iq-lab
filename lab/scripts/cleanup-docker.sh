#!/bin/bash

# before
df -i
echo
df -h
echo
docker system df

# remove exited containers:
docker ps --filter status=dead --filter status=exited -aq | xargs -r docker rm -v

# remove unused images:
docker images --no-trunc | grep '<none>' | awk '{ print $3 }' | xargs -r docker rmi

# remove unused data
docker system prune -af
docker system prune --volumes -f

# after
df -i
echo
df -h
echo
docker system df
echo
docker images
echo
docker ps