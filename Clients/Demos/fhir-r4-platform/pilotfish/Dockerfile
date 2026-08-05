FROM pilotfish-eip:23R1 AS pf-runtime
RUN mkdir -p /pf-runtime \
 && cd /usr/local/tomcat/webapps/eip/WEB-INF/classes \
 && jar cf /pf-runtime/eip-runtime.jar .

FROM maven:3.9.9-eclipse-temurin-17 AS fhir-validator-build
WORKDIR /src
COPY custom-modules/fhir-profile-validation-processor/pom.xml ./pom.xml
COPY custom-modules/fhir-profile-validation-processor/src ./src
COPY --from=pf-runtime /pf-runtime/eip-runtime.jar ./pf-runtime/eip-runtime.jar
RUN mvn -q -DskipTests package \
 && cp target/modules-fhir-profile-validation-1.0.0-SNAPSHOT.jar /modules-fhir-profile-validation.jar

FROM maven:3.9.9-eclipse-temurin-17 AS fhir-jwt-build
WORKDIR /src
COPY custom-modules/fhir-jwt-auth-processor/pom.xml ./pom.xml
COPY custom-modules/fhir-jwt-auth-processor/src ./src
COPY --from=pf-runtime /pf-runtime/eip-runtime.jar ./pf-runtime/eip-runtime.jar
RUN mvn -q -DskipTests package \
 && cp target/modules-fhir-jwt-auth-1.0.0-SNAPSHOT.jar /modules-fhir-jwt-auth.jar

FROM maven:3.9.9-eclipse-temurin-17 AS fhir-bulk-build
WORKDIR /src
COPY custom-modules/fhir-bulk-export-processor/pom.xml ./pom.xml
COPY custom-modules/fhir-bulk-export-processor/src ./src
COPY --from=pf-runtime /pf-runtime/eip-runtime.jar ./pf-runtime/eip-runtime.jar
RUN mvn -q -DskipTests package \
 && cp target/modules-fhir-bulk-export-1.0.0-SNAPSHOT.jar /modules-fhir-bulk-export.jar

FROM pilotfish-eip:23R1

RUN rm -rf /usr/local/tomcat/webapps/eip/eip-root/interfaces \
           /usr/local/tomcat/webapps/eip/eip-root/routes \
           /usr/local/tomcat/webapps/eip/eip-root/formats \
 && mkdir -p /usr/local/tomcat/webapps/eip/eip-root/routes \
             /usr/local/tomcat/webapps/eip/eip-root/formats \
             /usr/local/tomcat/webapps/eip/eip-root/interfaces \
             /opt/pilotfish/output/fhir-store \
             /opt/pilotfish/output/outbound-responses \
             /opt/pilotfish/output/bulk-export \
             /opt/pilotfish/input/outbound

ADD https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/12.8.1.jre11/mssql-jdbc-12.8.1.jre11.jar \
    /usr/local/tomcat/webapps/eip/WEB-INF/lib/mssql-jdbc-12.8.1.jre11.jar

COPY --from=fhir-validator-build /modules-fhir-profile-validation.jar \
    /usr/local/tomcat/webapps/eip/WEB-INF/lib/modules-fhir-profile-validation.jar
COPY --from=fhir-jwt-build /modules-fhir-jwt-auth.jar \
    /usr/local/tomcat/webapps/eip/WEB-INF/lib/modules-fhir-jwt-auth.jar
COPY --from=fhir-bulk-build /modules-fhir-bulk-export.jar \
    /usr/local/tomcat/webapps/eip/WEB-INF/lib/modules-fhir-bulk-export.jar

COPY pilotfish/demo-eip-root/ /usr/local/tomcat/webapps/eip/eip-root/
COPY pilotfish/demo-entrypoint.sh /demo-entrypoint.sh

RUN find /usr/local/tomcat/webapps/eip/eip-root -name '.DS_Store' -delete \
 && chmod -R a+rwX /opt/pilotfish/output /opt/pilotfish/input \
 && chmod +x /demo-entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/demo-entrypoint.sh"]
