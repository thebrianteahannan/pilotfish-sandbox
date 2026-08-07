<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:err="http://www.pilotfishtechnology.com/eip/RouteErrorReport" version="1.0">
  <xsl:template match="/err:errorReport">
    <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
      <SOAP-ENV:Body>
        <SOAP-ENV:Fault>
          <xsl:choose>
            <xsl:when test="err:errorRoute='Authentication and Validation' or err:errorRoute='Duplicate Transaction'">
              <faultcode>SOAP-ENV:Client</faultcode>
            </xsl:when>
            <xsl:when test="contains(err:rootExceptionMessage, 'The content of elements must consist of well-formed character data or markup')">
              <faultcode>SOAP-ENV:Client</faultcode>
            </xsl:when>
            <xsl:when test="contains(err:errorRoute, '3 - ILS Image Store Signature') or contains(err:errorRoute, '4 - ILS Image Store Consent')">
              <faultcode>SOAP-ENV:Server</faultcode>
            </xsl:when>
            <xsl:when test="contains(err:rootExceptionMessage, 'UnhandledServerErrorFault')">
              <faultcode>SOAP-ENV:Server</faultcode>
            </xsl:when>
            <xsl:when test="contains(err:rootExceptionMessage, '&lt;ns2:FaultMessage&gt;')">
              <faultcode>SOAP-ENV:Client</faultcode>
            </xsl:when>
            <xsl:when test="contains(err:exceptionMessage, 'Could not parse data')">
              <faultcode>SOAP-ENV:Client</faultcode>
            </xsl:when>
            <xsl:when test="contains(err:exceptionTrace, 'The specified sample routing code is not valid for any of the supported facilities.')">
              <faultcode>SOAP-ENV:Client</faultcode>
            </xsl:when>
            <xsl:otherwise>
              <faultcode>SOAP-ENV:Client</faultcode>
            </xsl:otherwise>
          </xsl:choose>
          <faultstring>Server Error</faultstring>
          <detail>
            <text>
              <xsl:choose>
                <xsl:when test="err:errorRoute='Authentication and Validation' or err:errorRoute='Duplicate Transaction'">
                  <xsl:value-of select="concat('Encountered an error processing your request: ', err:exceptionMessage, '; additional information: ', err:exceptionTrace)" />
                </xsl:when>
                <xsl:when test="contains(err:rootExceptionMessage, 'The content of elements must consist of well-formed character data or markup')">
                  <xsl:text>Invalid XML Received; the content of elements must consist of well-formed character data or markup.</xsl:text>
                </xsl:when>
                <xsl:when test="contains(err:errorRoute, '3 - ILS Image Store Signature') or contains(err:errorRoute, '4 - ILS Image Store Consent')">
                  <xsl:text>There was an error while processing your request.  Please try again.</xsl:text>
                </xsl:when>
                <xsl:when test="contains(err:rootExceptionMessage, 'UnhandledServerErrorFault')">
                  <xsl:text>There was an error while processing your request.  Please try again.</xsl:text>
                </xsl:when>
                <xsl:when test="contains(err:rootExceptionMessage, '&lt;ns2:FaultMessage&gt;')">
                  <xsl:value-of select="substring-before(substring-after(err:rootExceptionMessage, '&lt;ns2:FaultMessage&gt;'), '&lt;/ns2:FaultMessage&gt;')" />
                </xsl:when>
                <xsl:when test="contains(err:exceptionMessage, 'Could not parse data')">
                  <xsl:value-of select="concat('Could not parse data: ', err:rootExceptionMessage)" />
                </xsl:when>
                <xsl:otherwise>There was an error while processing your request.  Please try again.</xsl:otherwise>
              </xsl:choose>
            </text>
          </detail>
        </SOAP-ENV:Fault>
      </SOAP-ENV:Body>
    </SOAP-ENV:Envelope>
  </xsl:template>
</xsl:stylesheet>

