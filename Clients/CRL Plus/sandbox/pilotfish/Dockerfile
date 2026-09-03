# CRL Plus eiPlatform 26R1 — Tomcat 10 / JDK 21 (WAR is class file 65).
ARG TOMCAT_IMAGE=tomcat:10.1-jdk21-temurin
FROM ${TOMCAT_IMAGE}
ARG TOMCAT_IMAGE
LABEL pf.tomcat_image="${TOMCAT_IMAGE}"
LABEL pf.client="crl-plus"

ENV CATALINA_OPTS="-Xms512M -Xmx2048M -server -XX:+UseG1GC" \
    JAVA_OPTS="-Djava.security.egd=file:///dev/urandom"

RUN rm -rf /usr/local/tomcat/webapps/* \
 && mkdir -p /opt/pilotfish/input /opt/pilotfish/output /opt/pilotfish/archive \
             /opt/pilotfish/errors /opt/pilotfish/staging /opt/pilotfish/database \
             /usr/local/tomcat/webapps/eip

COPY eip.war /tmp/eip.war
COPY pflicense.key /usr/local/tomcat/webapps/eip/pflicense.key
RUN cd /usr/local/tomcat/webapps/eip \
 && jar -xf /tmp/eip.war \
 && rm -f /tmp/eip.war \
 && mkdir -p /usr/local/tomcat/webapps/eip/logs /usr/local/tomcat/webapps/eip/eip-root

ADD https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/12.8.1.jre11/mssql-jdbc-12.8.1.jre11.jar \
    /usr/local/tomcat/webapps/eip/WEB-INF/lib/mssql-jdbc-12.8.1.jre11.jar

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
