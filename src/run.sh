#!/bin/bash

eval $(docker-machine env docker-host)

docker kill $(docker ps -q)

docker run -d --network=reddit \
--network-alias=post_db \
--network-alias=comment_db -v reddit_db:/data/db mongo:latest

docker run -d --network=reddit \
--network-alias=post ge2rg312qe/post:1.0

docker run -d --network=reddit \
--network-alias=comment ge2rg312qe/comment:1.0

docker run -d --network=reddit \
-p 9292:9292 ge2rg312qe/ui:3.0
