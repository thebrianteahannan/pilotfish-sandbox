<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:acord="http://ACORD.org/Standards/Life/2" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:err="http://www.pilotfishtechnology.com/eip/RouteErrorReport" xmlns:ns1="http://pilotfish.sqlxml" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="ta td err datetime" extension-element-prefixes="ta td" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="/">
    <ns1:SQLXML>
      <xsl:if test="/Messages/Message or /err:errorReport/err:exceptionMessage or //acord:ResultCode[@tc=5][../acord:ResultInfo/acord:ResultInfoDesc]">
        <!-- DO THE INSERTING OF THE 121 ORIGINAL TEXT INTO THE TRANSACTION_TEXT TABLE -->
        <ns1:Insert>
          <TRANSACTION_TEXT>
            <ORIGINAL_TXT>
              <xsl:text>$$ATTRIBUTE.Incoming121XML</xsl:text>
            </ORIGINAL_TXT>
            <ORIGINAL_TYPE>121</ORIGINAL_TYPE>
          </TRANSACTION_TEXT>
        </ns1:Insert>
        <!-- NOW THAT WE'VE INSERTED THE ORIGINAL TRANSACTION TEXT INTO THE DATABASE, LET'S GET THAT NEW ROW'S SEQUENCE NUMBER FOR USE LATER -->
        <ns1:Execute as="row" into="results">
          <ns1:SQL>SELECT TRANSACTION_TEXT_SEQ.CURRVAL AS CURR_TRANSACTION_TEXT_ID FROM DUAL</ns1:SQL>
        </ns1:Execute>
        <ns1:Iterate as="row" over="results">
          <xsl:variable name="transTextID">ognl:#row.getFieldValue('CURR_TRANSACTION_TEXT_ID')</xsl:variable>
          <!-- Insert the validation errors into the VALIDATION_ERROR table -->
          <ns1:Execute>
            <ns1:SQL>INSERT INTO VALIDATION_ERROR (PF_SOURCE_CLIENT, POLNUMBER, ERROR_DATE, REQ_CODE_TC, REQ_CODE_TXT, REASON_FOR_ERROR, TRANSACTION_TEXT_ID) VALUES (?, ?, to_date(?, 'MM/DD/YYYY HH24:MI:SS'), ?, ?, ?, ?)</ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attributes, 'sourceClient')" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attributes, 'PolNumber')" />
            </ns1:Params>
            <ns1:Params>
              <xsl:call-template name="currentDateTime" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attributes, 'ReqCodeTC')" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attributes, 'ReqCodeText')" />
            </ns1:Params>
            <ns1:Params>
              <xsl:variable name="allmessages">
                <xsl:for-each select="/Messages/Message">
                  <xsl:call-template name="formatMessageForDB">
                    <xsl:with-param name="message">
                      <xsl:value-of select="." />
                    </xsl:with-param>
                  </xsl:call-template>
                  <xsl:value-of select="'. '" />
                </xsl:for-each>
                <xsl:for-each select="err:errorReport">
                  <xsl:value-of select="err:exceptionMessage" />
                  <xsl:value-of select="'. '" />
                </xsl:for-each>
                <xsl:for-each select="//acord:ResultCode[@tc=5][../acord:ResultInfo/acord:ResultInfoDesc]">
                  <xsl:value-of select="../acord:ResultInfo/acord:ResultInfoDesc" />
                  <xsl:value-of select="'. '" />
                </xsl:for-each>
              </xsl:variable>
              <xsl:value-of select="substring(normalize-space($allmessages),1,4000)" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$transTextID" />
            </ns1:Params>
          </ns1:Execute>
        </ns1:Iterate>
      </xsl:if>
    </ns1:SQLXML>
  </xsl:template>
  <xsl:template name="formatMessageForDB">
    <xsl:param name="message" />
    <!-- strip out contents of parenthesis to make the message more compact -->
    <xsl:choose>
      <xsl:when test="contains($message, '(') and contains(substring-after($message,'('),')')">
        <xsl:value-of select="concat(substring-before($message,'('),substring-after($message,')'))" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$message" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="currentDateTime">
    <xsl:value-of select="datetime:month-in-year()" />
    <xsl:value-of select="'/'" />
    <xsl:value-of select="datetime:day-in-month()" />
    <xsl:value-of select="'/'" />
    <xsl:value-of select="datetime:year()" />
    <xsl:value-of select="' '" />
    <xsl:value-of select="datetime:hour-in-day()" />
    <xsl:value-of select="':'" />
    <xsl:call-template name="makeTwoDigit">
      <xsl:with-param name="value" select="datetime:minute-in-hour()" />
    </xsl:call-template>
    <xsl:value-of select="':'" />
    <xsl:call-template name="makeTwoDigit">
      <xsl:with-param name="value" select="datetime:second-in-minute()" />
    </xsl:call-template>
  </xsl:template>
  <xsl:template name="makeTwoDigit">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="string-length($value) &gt;1">
        <xsl:value-of select="$value" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('0',$value)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

