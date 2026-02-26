#!/bin/bash
CTSMS_PROPERTIES=${CTSMS_PROPERTIES:-/ctsms/properties}
CTSMS_JAVA=${CTSMS_JAVA:-/ctsms/java}
if [ -d "/var/lib/tomcat10" ]; then
    CATALINA_BASE=${CATALINA_BASE:-/var/lib/tomcat10}
else
    CATALINA_BASE=${CATALINA_BASE:-/var/lib/tomcat9}
fi
while [ ! -d "$CATALINA_BASE/webapps/ROOT/WEB-INF/lib" ] || [ -z "$(ls $CATALINA_BASE/webapps/ROOT/WEB-INF/lib/ctsms-core-*.jar 2>/dev/null)" ]; do
  sleep 2
done
CORE_JAR=$(ls $CATALINA_BASE/webapps/ROOT/WEB-INF/lib/ctsms-core-*.jar)
LIB_JARS=$(ls $CATALINA_BASE/webapps/ROOT/WEB-INF/lib/*.jar | tr '\n' ':')
java -DCTSMS_PROPERTIES="$CTSMS_PROPERTIES" -DCTSMS_JAVA="$CTSMS_JAVA" -Dfile.encoding=Cp1252 -Djava.awt.headless=true --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED -Xms2048m -Xmx4096m -Xss256k -XX:+UseParallelGC -XX:MaxGCPauseMillis=1500 -XX:GCTimeRatio=9 -XX:ReservedCodeCacheSize=256m -classpath $CORE_JAR:$LIB_JARS org.phoenixctms.ctsms.executable.DBTool $*