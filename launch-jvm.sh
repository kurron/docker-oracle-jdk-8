#!/bin/bash

# Uses settings described in http://blog.sokolenko.me/2014/11/javavm-options-production.html
# Expects to have all values set in the environment
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
    -Dcom.sun.management.jmxremote.rmi.port=$JVM_JMX_RMI_PORT \
    -Dcom.sun.management.jmxremote.authenticate=false \
    -Dcom.sun.management.jmxremote.ssl=false \
    $*"

echo eval $CMD
eval $CMD
