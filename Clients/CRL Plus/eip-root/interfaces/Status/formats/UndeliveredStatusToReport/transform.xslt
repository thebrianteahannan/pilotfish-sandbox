<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:java="java" exclude-result-prefixes="java datetime" version="1.0">
  <xsl:output method="html" omit-xml-declaration="yes" />
  <xsl:template match="/EIPData">
    <html>
      <head>
        <title>Undelivered Activities/Statuses</title>
      </head>
      <body>
        <p>
          <xsl:value-of select="'PilotFish server hostname: '" />
          <xsl:variable name="localHost" select="java:net.InetAddress.getLocalHost()" />
          <xsl:value-of select="java:getHostName($localHost)" />
        </p>
        <p>
          <xsl:value-of select="'Report date: '" />
          <xsl:value-of select="datetime:format-date(datetime:date-time(),'yyyy-MM-dd HH:mm:ss')" />
        </p>
        <h5>The following FlowNet activities have not been delivered and belong to orders that have not been modified in the last 24 hours:</h5>
        <table>
          <tr>
            <th>Client</th>
            <th>FlowNet Order</th>
            <th>TransactionID</th>
            <th>Policy Number</th>
            <th>Test Indicator</th>
            <th>Last Modified</th>
            <th>Provider Event Code</th>
            <th>Status Event Detail</th>
            <th>Status Date</th>
          </tr>
          <xsl:for-each select="RESULTS/TRANSACTION">
            <tr>
              <td>
                <xsl:value-of select="PFSOURCECLIENT" />
              </td>
              <td>
                <xsl:value-of select="FLOWNETORDERNUM" />
              </td>
              <td>
                <xsl:value-of select="TRANSACTIONID" />
              </td>
              <td>
                <xsl:value-of select="POLNUMBER" />
              </td>
              <td>
                <xsl:value-of select="TESTINDICATOR" />
              </td>
              <td>
                <xsl:value-of select="LASTMODIFIEDDATE" />
              </td>
              <td>
                <xsl:value-of select="PROVIDEREVENTCODE" />
              </td>
              <td>
                <xsl:value-of select="STATUSEVENTDETAIL" />
              </td>
              <td>
                <xsl:value-of select="STATUSEVENTDATE" />
              </td>
            </tr>
          </xsl:for-each>
        </table>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>

