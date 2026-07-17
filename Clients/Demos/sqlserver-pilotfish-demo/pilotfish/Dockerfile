# Minimal PilotFish runtime for the SQL Server -> XML export demo.
# Reuses the locally built pilotfish-eip:23R1 image (Tomcat + eiPlatform + license).
FROM pilotfish-eip:23R1

# Remove the sandbox MedReceivables interfaces so only this demo route loads.
RUN rm -rf /usr/local/tomcat/webapps/eip/eip-root/interfaces \
           /usr/local/tomcat/webapps/eip/eip-root/routes \
           /usr/local/tomcat/webapps/eip/eip-root/formats \
 && mkdir -p /usr/local/tomcat/webapps/eip/eip-root/routes \
             /usr/local/tomcat/webapps/eip/eip-root/formats \
             /usr/local/tomcat/webapps/eip/eip-root/interfaces \
             /opt/pilotfish/output

# Microsoft JDBC driver for SQL Server
ADD https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/12.8.1.jre11/mssql-jdbc-12.8.1.jre11.jar \
    /usr/local/tomcat/webapps/eip/WEB-INF/lib/mssql-jdbc-12.8.1.jre11.jar

COPY demo-eip-root/ /usr/local/tomcat/webapps/eip/eip-root/

RUN find /usr/local/tomcat/webapps/eip/eip-root -name '.DS_Store' -delete \
 && chmod -R a+rwX /opt/pilotfish/output

EXPOSE 8080
