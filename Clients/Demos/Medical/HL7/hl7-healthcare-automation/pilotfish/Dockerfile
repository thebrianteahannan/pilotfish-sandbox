# HL7 Healthcare Automation demo runtime on pilotfish-eip:23R1
FROM pilotfish-eip:23R1

RUN rm -rf /usr/local/tomcat/webapps/eip/eip-root/interfaces \
           /usr/local/tomcat/webapps/eip/eip-root/routes \
           /usr/local/tomcat/webapps/eip/eip-root/formats \
 && mkdir -p /usr/local/tomcat/webapps/eip/eip-root/routes \
             /usr/local/tomcat/webapps/eip/eip-root/formats \
             /usr/local/tomcat/webapps/eip/eip-root/interfaces \
             /opt/pilotfish/input/inbound \
             /opt/pilotfish/output/archive \
             /opt/pilotfish/output/clearinghouse \
             /opt/pilotfish/output/validation \
             /opt/pilotfish/output/kickout

ADD https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/12.8.1.jre11/mssql-jdbc-12.8.1.jre11.jar \
    /usr/local/tomcat/webapps/eip/WEB-INF/lib/mssql-jdbc-12.8.1.jre11.jar

COPY demo-eip-root/ /usr/local/tomcat/webapps/eip/eip-root/
COPY demo-entrypoint.sh /demo-entrypoint.sh

RUN find /usr/local/tomcat/webapps/eip/eip-root -name '.DS_Store' -delete \
 && chmod -R a+rwX /opt/pilotfish/output /opt/pilotfish/input \
 && chmod +x /demo-entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/demo-entrypoint.sh"]
