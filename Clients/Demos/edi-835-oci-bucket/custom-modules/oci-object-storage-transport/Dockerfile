# Build custom OciObjectStorageTransport shaded jar against PilotFish 23R1 classpath
FROM pilotfish-eip:23R1 AS pf
# Collect runtime classes + a handful of API jars into one compile classpath jar set
RUN mkdir -p /pf-runtime \
 && cd /usr/local/tomcat/webapps/eip/WEB-INF/classes \
 && jar cf /pf-runtime/eip-runtime.jar .

FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /src
COPY pom.xml .
COPY src ./src
COPY --from=pf /pf-runtime/eip-runtime.jar ./pf-runtime/eip-runtime.jar
RUN mvn -q -DskipTests package

FROM scratch AS export
COPY --from=build /src/target/modules-oci-object-storage-1.0.0-SNAPSHOT.jar /modules-oci-object-storage.jar
