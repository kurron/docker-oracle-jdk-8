#!/bin/bash

if [ "$1" = "" ]
then
 echo "Usage: $0 tag"
 exit
fi

TAG=$1

TAG_COMMAND="docker tag jdk:compose kurron/docker-oracle-jdk-8:$TAG"
echo $TAG_COMMAND
$TAG_COMMAND

PUSH_COMMAND="docker push kurron/docker-oracle-jdk-8:$TAG"
echo $PUSH_COMMAND
$PUSH_COMMAND
