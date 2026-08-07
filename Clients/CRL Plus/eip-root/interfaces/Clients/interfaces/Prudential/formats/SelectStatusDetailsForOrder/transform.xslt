<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="https://hhws.portamedic.com/wsordresp/hhresponse.asmx" xmlns:ns2="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sql="http://pilotfish.sqlxml" exclude-result-prefixes="ns2 ns1" version="1.0">
  <xsl:template match="/ns2:Envelope">
    <sql:SQLXML>
      <sql:Execute as="transaction" into="results">
        <sql:SQL>select c.* from CRLTRANSACTION c
inner join POLICY p on p.TRANSACTION_ID=c.TRANSACTION_ID
inner join REQ_INFO r on r.POLICY_ID=p.POLICY_ID
where p.POLNUMBER=? and r.UNIQUEID=?</sql:SQL>
        <sql:Params>
          <xsl:value-of select="ns2:Body/ns1:GetOrderResponse/ns1:Policy" />
        </sql:Params>
        <sql:Params>
          <xsl:value-of select="ns2:Body/ns1:GetOrderResponse/ns1:RequirmentInfoUniqueID" />
        </sql:Params>
      </sql:Execute>
      <XMLOut var="results" />
    </sql:SQLXML>
  </xsl:template>
</xsl:stylesheet>

