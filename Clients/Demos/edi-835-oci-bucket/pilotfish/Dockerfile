# EDI 835 → OCI Object Storage demo runtime on pilotfish-eip:23R1
FROM pilotfish-eip:23R1

RUN rm -rf /usr/local/tomcat/webapps/eip/eip-root/interfaces \
           /usr/local/tomcat/webapps/eip/eip-root/routes \
           /usr/local/tomcat/webapps/eip/eip-root/formats \
 && mkdir -p /usr/local/tomcat/webapps/eip/eip-root/routes \
             /usr/local/tomcat/webapps/eip/eip-root/formats \
             /usr/local/tomcat/webapps/eip/eip-root/interfaces \
             /opt/pilotfish/output/archive \
             /opt/pilotfish/output/staged \
             /opt/pilotfish/output/json \
             /opt/pilotfish/output/oci-received \
             /opt/pilotfish/output/kickout

COPY demo-eip-root/ /usr/local/tomcat/webapps/eip/eip-root/
COPY demo-entrypoint.sh /demo-entrypoint.sh
# Custom OCI Object Storage Transport (OCI Java SDK shaded)
COPY custom-lib/modules-oci-object-storage.jar /usr/local/tomcat/webapps/eip/WEB-INF/lib/

RUN find /usr/local/tomcat/webapps/eip/eip-root -name '.DS_Store' -delete \
 && chmod -R a+rwX /opt/pilotfish/output \
 && chmod +x /demo-entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/demo-entrypoint.sh"]
