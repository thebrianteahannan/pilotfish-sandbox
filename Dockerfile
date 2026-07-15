# PilotFish eiPlatform on Linux (Tomcat 10 + OpenJDK 17)
# Based on: https://cms.pilotfishtechnology.com/eiplatform-installation-guide-linux/

FROM tomcat:10.1-jdk17-temurin

ENV CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC" \
    JAVA_OPTS="-Djava.security.egd=file:///dev/urandom"

# Drop default Tomcat apps; keep a clean webapps dir
RUN rm -rf /usr/local/tomcat/webapps/*

# Data directories (overridden at runtime by volume mounts when using docker-run.sh)
RUN mkdir -p \
      /opt/pilotfish/input/staging \
      /opt/pilotfish/output \
      /opt/pilotfish/archive \
      /opt/pilotfish/database \
      /usr/local/tomcat/webapps/eip

# Rename-equivalent: install WAR as exploded webapps/eip (same as guide's eip.war deploy)
COPY eip.war.hs.23R1.127 /tmp/eip.war
RUN cd /usr/local/tomcat/webapps/eip \
 && jar -xf /tmp/eip.war \
 && rm -f /tmp/eip.war \
 && mkdir -p /usr/local/tomcat/webapps/eip/logs

# License key (guide: copy into webapps/eip)
COPY pflicense.key /usr/local/tomcat/webapps/eip/pflicense.key

# Interface package -> eip-root
COPY eip-root-fromTEST/ /usr/local/tomcat/webapps/eip/eip-root/
COPY docker/environment-settings.conf /usr/local/tomcat/webapps/eip/eip-root/environment-settings.conf

# Convert hardcoded Windows PilotFish paths (without breaking regex escapes),
# move eip-root/lib jars into WEB-INF/lib.
COPY docker/fix-windows-paths.sh /tmp/fix-windows-paths.sh
RUN chmod +x /tmp/fix-windows-paths.sh \
 && /tmp/fix-windows-paths.sh /usr/local/tomcat/webapps/eip/eip-root \
 && rm -f /tmp/fix-windows-paths.sh \
 && if [ -d /usr/local/tomcat/webapps/eip/eip-root/lib ]; then \
      cp -n /usr/local/tomcat/webapps/eip/eip-root/lib/*.jar /usr/local/tomcat/webapps/eip/WEB-INF/lib/ 2>/dev/null || true; \
      rm -f /usr/local/tomcat/webapps/eip/eip-root/lib/*.jar; \
    fi \
 && find /usr/local/tomcat/webapps/eip/eip-root -name '.DS_Store' -delete

# Seed H2 database used by DATABASE_URL=jdbc:h2:/opt/pilotfish/database/medreceivables
# Entrypoint will copy this into the mounted volume when the volume DB is missing/empty.
COPY database/medreceivables.mv.db /opt/pilotfish/seed/medreceivables.mv.db

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

VOLUME ["/opt/pilotfish/input", "/opt/pilotfish/output", "/opt/pilotfish/archive", "/opt/pilotfish/database", "/usr/local/tomcat/webapps/eip/logs"]

ENTRYPOINT ["/entrypoint.sh"]
