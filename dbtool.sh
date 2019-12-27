#!/bin/bash
java -DCTSMS_PROPERTIES="/ctsms/properties" -DCTSMS_JAVA="/ctsms/java" -Dfile.encoding=Cp1252 -Djava.awt.headless=true -Xms2048m -Xmx4096m -Xss256k -XX:+UseParallelGC -XX:MaxGCPauseMillis=1500 -XX:GCTimeRatio=9 -XX:+CMSClassUnloadingEnabled -XX:ReservedCodeCacheSize=256m -classpath /var/lib/tomcat8/webapps/ROOT/WEB-INF/lib/ctsms-core-1.6.9.jar:/var/lib/tomcat8/webapps/ROOT/WEB-INF/lib/* org.phoenixctms.ctsms.executable.DBTool $*