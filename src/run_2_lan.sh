#!/bin/bash

eval $(docker-machine env docker-host)

docker kill $(docker ps -q)

docker run -d --network=back_net --name mongo_db \
--network-alias=post_db \
--network-alias=comment_db -v reddit_db:/data/db mongo:latest

docker run -d --network=back_net --name post \
--network-alias=post ge2rg312qe/post:1.0

docker run -d --network=back_net --name comment \
--network-alias=comment ge2rg312qe/comment:1.0

docker run -d --network=front_net \
-p 9292:9292 --name ui ge2rg312qe/ui:3.0

#sleep 30

docker network connect front_net post
docker network connect front_net comment
