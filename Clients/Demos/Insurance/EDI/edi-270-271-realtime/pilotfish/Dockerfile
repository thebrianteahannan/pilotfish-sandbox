# EDI 270/271 Realtime Eligibility — PilotFish 23R1
FROM pilotfish-eip:23R1

RUN rm -rf /usr/local/tomcat/webapps/eip/eip-root/interfaces \
           /usr/local/tomcat/webapps/eip/eip-root/routes \
           /usr/local/tomcat/webapps/eip/eip-root/formats \
 && mkdir -p /usr/local/tomcat/webapps/eip/eip-root/routes \
             /usr/local/tomcat/webapps/eip/eip-root/formats \
             /usr/local/tomcat/webapps/eip/eip-root/interfaces \
             /opt/pilotfish/output/requests \
             /opt/pilotfish/output/270 \
             /opt/pilotfish/output/271 \
             /opt/pilotfish/output/responses

COPY demo-eip-root/ /usr/local/tomcat/webapps/eip/eip-root/
COPY demo-entrypoint.sh /demo-entrypoint.sh

RUN find /usr/local/tomcat/webapps/eip/eip-root -name '.DS_Store' -delete \
 && chmod -R a+rwX /opt/pilotfish/output \
 && chmod +x /demo-entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/demo-entrypoint.sh"]
