<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:java="java" exclude-result-prefixes="java datetime" version="1.0">
  <xsl:output method="html" omit-xml-declaration="yes" />
  <xsl:template match="/EIPData">
    <html>
      <head>
        <style>table, th, td {
				border: 1px solid black;
				}</style>
        <title>Prudential Error Report</title>
      </head>
      <body>
        <p>
          <xsl:value-of select="'PilotFish Server Hostname: '" />
          <xsl:variable name="localHost" select="java:net.InetAddress.getLocalHost()" />
          <xsl:value-of select="java:getHostName($localHost)" />
        </p>
        <p>
          <xsl:value-of select="'Report Date: '" />
          <xsl:value-of select="datetime:format-date(datetime:date-time(),'yyyy-MM-dd HH:mm:ss')" />
        </p>
        <h5>The following Prudential transactions have not been imported in the last 24 hours:</h5>
        <table>
          <tr>
            <th>Policy Number</th>
            <th>Date / Time</th>
            <th>REQ Code</th>
            <th>REQ Description</th>
            <th>Reason for Error</th>
          </tr>
          <xsl:for-each select="ERRORS/ERROR">
            <tr>
              <td>
                <xsl:value-of select="POLNUMBER" />
              </td>
              <td>
                <xsl:value-of select="substring(ERRORDATE,1,19)" />
              </td>
              <td>
                <xsl:value-of select="REQCODETC" />
              </td>
              <td>
                <xsl:value-of select="REQCODETXT" />
              </td>
              <td>
                <xsl:value-of select="REASONFORERROR" />
              </td>
            </tr>
          </xsl:for-each>
        </table>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>

