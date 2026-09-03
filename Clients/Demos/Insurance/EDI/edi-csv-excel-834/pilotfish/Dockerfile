# EDI 834 CSV Excel Conversion — PilotFish 23R1
FROM eip_base

RUN rm -rf /usr/local/tomcat/webapps/eip/eip-root/interfaces \
           /usr/local/tomcat/webapps/eip/eip-root/routes \
           /usr/local/tomcat/webapps/eip/eip-root/formats \
 && mkdir -p /usr/local/tomcat/webapps/eip/eip-root/routes \
             /usr/local/tomcat/webapps/eip/eip-root/formats \
             /usr/local/tomcat/webapps/eip/eip-root/interfaces \
             /opt/pilotfish/input/inbound \
             /opt/pilotfish/input/edi \
             /opt/pilotfish/output/834 \
             /opt/pilotfish/output/csv \
             /opt/pilotfish/output/kickout \
             /opt/pilotfish/output/archive/csv \
             /opt/pilotfish/output/archive/edi

COPY demo-eip-root/ /usr/local/tomcat/webapps/eip/eip-root/
COPY edi-tabledata/ /usr/local/tomcat/webapps/eip/eip-root/edi-tabledata/
COPY demo-entrypoint.sh /demo-entrypoint.sh

RUN find /usr/local/tomcat/webapps/eip/eip-root -name '.DS_Store' -delete \
 && chmod -R a+rwX /opt/pilotfish/output /opt/pilotfish/input \
 && chmod +x /demo-entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/demo-entrypoint.sh"]
