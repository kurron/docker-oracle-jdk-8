# Overview
This project is a simple Docker image that contains the [Oracle JDK](http://www.oracle.com/technetwork/java/index.html).

# Prerequisites
* a working [Docker](http://docker.io) engine
* a working [Docker Compose](http://docker.io) installation

# Building
Type `docker-compose build` to build the image.

# Installation
Docker will automatically install the newly built image into the cache.

# Tips and Tricks

## Launching The Image

`docker-compose up` will launch the image in a simple test mode to ensure things are wired up correctly. 

## Simple Usage
The `/opt/launch-jvm.sh` script is available to launch the JVM and is convenient means of doing so. An
example of how to use the script might look like this `ENTRYPOINT ["/opt/launch-jvm.sh", "-jar", "/opt/server.jar"]`.

The environment variables in the container control some of the settings in the script:

* JVM_HEAP_MIN -- the minimum heap size. Defaults to 128m.
* JVM_HEAP_MAX -- the maximum heap size. Defaults to 512m.
* JVM_METASPACE -- the maximum Metaspace size. Defaults to 512m.
* JVM_CMS_OCCUPANCY -- the percentage at which the concurrent mark and sweep garbage collector should be triggered. Defaults to 70.
* JVM_GC_LOG_PATH -- where to store the garbage collection logs. Defaults to /var/logs.
* JVM_GC_LOG_FILE_COUNT -- the maximum number of GC log files to keep before rotating. Defaults to 10.
* JVM_GC_LOG_FILE_SIZE -- the maximum size of a single GC log file. Defaults to 100M.
* JVM_DNS_TTL -- how long, in seconds, DNS entries should be cached. Defaults to 30.
* JVM_JMX_HOST -- the interface to bind JMX to.  Defaults to 127.0.0.1.
* JVM_JMX_PORT -- the port to bind JMX to.  Defaults to  9999.

The settings in the script were borrowed from 
[Java VM Options You Should Always Use in Production](http://blog.sokolenko.me/2014/11/javavm-options-production.html).

Since the settings are environment variables, you may customize them at launch time.

**WARNING:** this is simplistic mechanism that, because of the PID 1 problem, will prevent some applications, such as
Spring Boot based ones, from seeing exit signals and cleaning up properly after themselves.
 
## Sophisticated Usage
This image is based on [phusion/baseimage](https://hub.docker.com/r/phusion/baseimage/) and can take advantage of its
watchdog capabilities.  I've found that **not** using this mechanism causes problems when building Spring Boot based
microservices.  If you run something simple like `java -jar foo` as your `ENTRYPOINT` you are probably ok.  If,
however, you decide to launch your JVM via shell script you will run into problems.  In the case of a Spring Boot 
microservice, I've found that the JVM never sees the shutdown signal and the program never gets a chance to clean 
up.  This left stale registrations in our service registry.  Not good.  A more complex, but safer, way of launching 
your application is to create a launch script that follows certain conventions.  Here is an example borrowed from 
 [docker-spring-cloud-configuration-server](https://github.com/kurron/docker-spring-cloud-configuration-server).

### Create a custom launch script

`service.sh`:

```
#!/bin/bash

# Uses settings described in http://blog.sokolenko.me/2014/11/javavm-options-production.html
# Expects to have all values set in the environment
# This command is specific to this service and is required by phusion/baseimage-docker so it can manage PID 1

CMD="$JAVA_HOME/bin/java \
    -server \
    -Xms$JVM_HEAP_MIN \
    -Xmx$JVM_HEAP_MAX \
    -XX:MaxMetaspaceSize=$JVM_METASPACE \
    -XX:+UseConcMarkSweepGC \
    -XX:+CMSParallelRemarkEnabled \
    -XX:+UseCMSInitiatingOccupancyOnly \
    -XX:CMSInitiatingOccupancyFraction=$JVM_CMS_OCCUPANCY \
    -XX:+ScavengeBeforeFullGC \
    -XX:+CMSScavengeBeforeRemark \
    -XX:+PrintGCDateStamps \
    -verbose:gc \
    -XX:+PrintGCDetails \
    -Xloggc:$JVM_GC_LOG_PATH \
    -XX:+UseGCLogFileRotation \
    -XX:NumberOfGCLogFiles=$JVM_GC_LOG_FILE_COUNT \
    -XX:GCLogFileSize=$JVM_GC_LOG_FILE_SIZE \
    -XX:+HeapDumpOnOutOfMemoryError \
    -XX:HeapDumpPath=$JVM_GC_LOG_PATH/heap-dump.hprof \
    -Dsun.net.inetaddr.ttl=$JVM_DNS_TTL \
    -Djava.rmi.server.hostname=$JVM_JMX_HOST \
    -Dcom.sun.management.jmxremote.port=$JVM_JMX_PORT \
    -Dcom.sun.management.jmxremote.authenticate=false \
    -Dcom.sun.management.jmxremote.ssl=false \
    -jar /opt/server.jar"

echo eval $CMD
eval $CMD
```

### Follow the phusion/baseimage conventions

`Dockerfile`:

```
FROM kurron/docker-oracle-jdk-8:latest

MAINTAINER Ron Kurr <kurr@kurron.org>

LABEL org.kurron.name="JVM Guy Configuration Server" org.kurron.ide.version=1.0.4

ADD https://bintray.com/artifact/download/kurron/maven/org/kurron/jvm-guy-configuration-server/1.0.4.RELEASE/jvm-guy-configuration-server-1.0.4.RELEASE.jar /opt/server.jar

# these are the phusion/baseimage conventions
RUN mkdir /etc/service/configuration-server
ADD service.sh /etc/service/configuration-server/run 
RUN chmod a+x /etc/service/configuration-server/run

# start the init service 
ENTRYPOINT ["/sbin/my_init"]
```

### Test out your image by starting it

`docker-compose.yml`:


```
version: '2'
services:
    configuration-server:
        build: .
        container_name: "configuration-server"
        network_mode: "host"
        restart: always
        environment:
            SPRING_CLOUD_CONSUL_HOST: 192.168.1.227
            JVM_JMX_HOST: 192.168.1.227
            JVM_HEAP_MAX: 768m 
```

### Shutdown the container 
`docker stop configuration-server` should cleanly shutdown this example server and the logs should indicate a clean shutdown.

```
configuration-server | {"timestamp":"2016-04-03T18:01:49.275+00:00","message":"Started Application in 10.288 seconds (JVM running for 12.895)","component":"org.kurron.example.Application","level":"INFO"}
configuration-server | *** Shutting down runit daemon (PID 10)...
configuration-server | *** Killing all processes...
configuration-server | {"timestamp":"2016-04-03T18:02:04.601+00:00","message":"Closing org.springframework.boot.context.embedded.AnnotationConfigEmbeddedWebApplicationContext@33f4c061: startup date [Sun Apr 03 18:01:42 UTC 2016]; parent: org.springframework.context.annotation.AnnotationConfigApplicationContext@2680968e","component":"org.springframework.boot.context.embedded.AnnotationConfigEmbeddedWebApplicationContext","level":"INFO"}
configuration-server | {"timestamp":"2016-04-03T18:02:04.605+00:00","message":"Stopping beans in phase 0","component":"org.springframework.context.support.DefaultLifecycleProcessor","level":"INFO"}
configuration-server | {"timestamp":"2016-04-03T18:02:04.740+00:00","message":"Removing {logging-channel-adapter:_org.springframework.integration.errorLogger} as a subscriber to the 'errorChannel' channel","component":"org.springframework.integration.endpoint.EventDrivenConsumer","level":"INFO"}
configuration-server | {"timestamp":"2016-04-03T18:02:04.741+00:00","message":"Channel 'jvm-guy-configuration-server:2020.errorChannel' has 0 subscriber(s).","component":"org.springframework.integration.channel.PublishSubscribeChannel","level":"INFO"}
configuration-server | {"timestamp":"2016-04-03T18:02:04.744+00:00","message":"stopped _org.springframework.integration.errorLogger","component":"org.springframework.integration.endpoint.EventDrivenConsumer","level":"INFO"}
configuration-server | {"timestamp":"2016-04-03T18:02:04.778+00:00","message":"Unregistering JMX-exposed beans on shutdown","component":"org.springframework.boot.actuate.endpoint.jmx.EndpointMBeanExporter","level":"INFO"}
configuration-server | {"timestamp":"2016-04-03T18:02:04.784+00:00","message":"Unregistering JMX-exposed beans","component":"org.springframework.boot.actuate.endpoint.jmx.EndpointMBeanExporter","level":"INFO"}
configuration-server | {"timestamp":"2016-04-03T18:02:04.790+00:00","message":"Shutting down ExecutorService 'taskScheduler'","component":"org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler","level":"INFO"}
configuration-server | {"timestamp":"2016-04-03T18:02:04.801+00:00","message":"Unregistering JMX-exposed beans on shutdown","component":"org.springframework.jmx.export.annotation.AnnotationMBeanExporter","level":"INFO"}
configuration-server | {"timestamp":"2016-04-03T18:02:04.803+00:00","message":"Unregistering JMX-exposed beans","component":"org.springframework.jmx.export.annotation.AnnotationMBeanExporter","level":"INFO"}
configuration-server exited with code 0
```

# Troubleshooting

## Docker Compose Version
You must be running the current version of Docker Compose or it won't recognize the newer format of the build file.

# License and Credits
This project is licensed under the [Apache License Version 2.0, January 2004](http://www.apache.org/licenses/).

