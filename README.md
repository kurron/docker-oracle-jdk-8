#Overview
This project is a simple Docker image that contains the [Oracle JDK](http://www.oracle.com/technetwork/java/index.html).

#Prerequisites
* a working [Docker](http://docker.io) engine
* a working [Docker Compose](http://docker.io) installation

#Building
Type `docker-compose build` to build the image.

#Installation
Docker will automatically install the newly built image into the cache.

#Tips and Tricks

##Launching The Image

`docker-compose up` will launch the image in a simple test mode to ensure things are wired up correctly. 

##Usage
The `/opt/launch-jvm.sh` script is available to launch the JVM and is the recommended means of doing so. An
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

Since the settings are environment variables, you make customize them at launch time.

#Troubleshooting

#License and Credits
This project is licensed under the [Apache License Version 2.0, January 2004](http://www.apache.org/licenses/).

