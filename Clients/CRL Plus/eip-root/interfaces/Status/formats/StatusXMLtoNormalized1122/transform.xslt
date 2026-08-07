<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="datetime dtFormatter ns2 converter" extension-element-prefixes="converter" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.10.00.xsd">
  <xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'" />
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
  <xsl:template match="/RESULTS">
    <xsl:variable name="sourceClient" select="PFSOURCECLIENT" />
    <xsl:variable name="fulfilledDate" select="ORDERCOMPLETEDATE" />
    <xsl:variable name="dbStatuses" select="TRANSACTIONSTATUSES" />
    <xsl:variable name="dbPolicies" select="TRANSACTIONPOLICY" />
    <xsl:variable name="dbReqInfo" select="TRANSACTIONREQINFO" />
    <xsl:variable name="dbAttachments" select="TRANSACTIONATTACHMENT" />
    <xsl:variable name="flowNetOrderNum" select="FLOWNETORDERNUM" />
    <xsl:variable name="createdDate" select="CREATEDDATE" />
    <xsl:variable name="completeDate" select="ORDERCOMPLETEDATE" />
    <xsl:variable name="includePreviouslySentStatuses">
      <xsl:choose>
        <xsl:when test="$sourceClient = 'AIGP'">
          <xsl:value-of select="'true'" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'false'" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:for-each select="TRANSACTIONTEXT[1]/NORMALIZEDTXT[1]/ns2:TXLife[1] | TRANSACTIONTEXT[1]/RECORD[1]/NORMALIZEDTXT[1]/ns2:TXLife[1] | TRANSACTIONTEXT[1]/DATA[1]/NORMALIZEDTXT[1]/ns2:TXLife[1] | data[@id='Generated1122']/ns2:TXLife">
      <ns2:TXLife>
        <ns2:UserAuthRequest>
          <ns2:UserLoginName />
          <ns2:UserPswd>
            <ns2:CryptType>
              <xsl:text>NONE</xsl:text>
            </ns2:CryptType>
            <ns2:CryptPswd />
          </ns2:UserPswd>
          <ns2:UserDate>
            <xsl:value-of select="substring-before(datetime:date-time(),'T')" />
          </ns2:UserDate>
          <ns2:UserTime>
            <xsl:value-of select="substring-after(datetime:date-time(),'T')" />
          </ns2:UserTime>
          <ns2:VendorApp>
            <ns2:VendorName VendorCode="118">CRL-Plus</ns2:VendorName>
            <ns2:AppName>XMLPROC</ns2:AppName>
            <ns2:AppVer>1.0.0</ns2:AppVer>
          </ns2:VendorApp>
        </ns2:UserAuthRequest>
        <ns2:TXLifeRequest>
          <ns2:TransRefGUID>
            <!--<xsl:value-of select="ns2:TXLifeRequest/ns2:TransRefGUID" />-->
            <!-- New GUID generated for each status transmittal -->
            <xsl:value-of select="converter:getGUIDString()" />
          </ns2:TransRefGUID>
          <ns2:TransType tc="1122">
            <xsl:text>Requirement Notification Transmittal</xsl:text>
          </ns2:TransType>
          <ns2:TransExeDate>
            <!--<xsl:value-of select="ns2:TXLifeRequest/ns2:TransExeDate" />-->
            <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
          </ns2:TransExeDate>
          <ns2:TransExeTime>
            <!--<xsl:value-of select="ns2:TXLifeRequest/ns2:TransExeTime" />-->
            <xsl:value-of select="dtFormatter:format(datetime:time(),'HH:mm:ss','HH:mm:ss')" />
          </ns2:TransExeTime>
          <ns2:TransMode tc="{ancestor::RESULTS/MODETC}">
            <xsl:value-of select="ancestor::RESULTS/MODETXT" />
          </ns2:TransMode>
          <xsl:choose>
            <xsl:when test="ancestor::RESULTS/TESTINDICATOR = '0'">
              <ns2:TestIndicator tc="0">
                <xsl:value-of select="'False'" />
              </ns2:TestIndicator>
            </xsl:when>
            <xsl:otherwise>
              <ns2:TestIndicator tc="1">
                <xsl:value-of select="'True'" />
              </ns2:TestIndicator>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:for-each select="ns2:TXLifeRequest/ns2:OLifE">
            <ns2:OLifE>
              <!-- Replace the SourceInfo to show message is coming from CRL Plus -->
              <ns2:SourceInfo>
                <ns2:SourceInfoName>CRL-Plus</ns2:SourceInfoName>
                <ns2:SourceInfoDescription>Email : INSURANCECS@CRLCORP.COM</ns2:SourceInfoDescription>
                <ns2:SourceInfoComment>Phone : 8558507587</ns2:SourceInfoComment>
              </ns2:SourceInfo>
              <xsl:for-each select="ns2:Holding">
                <xsl:variable name="holdingID" select="@id" />
                <ns2:Holding id="{@id}">
                  <xsl:apply-templates select="ns2:HoldingTypeCode" />
                  <xsl:for-each select="ns2:Policy">
                    <xsl:variable name="incomingPolicy" select="." />
                    <ns2:Policy>
                      <xsl:if test="@CarrierPartyID">
                        <xsl:attribute name="CarrierPartyID">
                          <xsl:value-of select="@CarrierPartyID" />
                        </xsl:attribute>
                      </xsl:if>
                      <xsl:if test="@id">
                        <xsl:attribute name="id">
                          <xsl:value-of select="@id" />
                        </xsl:attribute>
                      </xsl:if>
                      <ns2:PolNumber>
                        <xsl:value-of select="ns2:PolNumber" />
                      </ns2:PolNumber>
                      <ns2:CarrierCode>
                        <xsl:value-of select="ns2:CarrierCode" />
                      </ns2:CarrierCode>
                      <xsl:apply-templates select="ns2:LineOfBusiness" />
                      <xsl:apply-templates select="ns2:ProductType" />
                      <xsl:apply-templates select="ns2:Jurisdiction" />
                      <xsl:apply-templates select="ns2:Life" />
                      <xsl:apply-templates select="ns2:ApplicationInfo" />
                      <xsl:for-each select="$dbPolicies/POLICY">
                        <xsl:if test="HOLDINGID = $holdingID">
                          <xsl:variable name="dbPolicyID" select="POLICYID" />
                          <xsl:for-each select="$dbReqInfo/REQINFO[POLICYID=$dbPolicyID]">
                            <xsl:sort data-type="number" select="REQINFOID" />
                            <xsl:variable name="dbReqInfoID" select="REQINFOID" />
                            <xsl:variable name="dbReqInfoPosition" select="position()" />
                            <ns2:RequirementInfo>
                              <xsl:variable name="mostRecentStatusID">
                                <xsl:for-each select="$dbStatuses/STATUS[REQINFOID=$dbReqInfoID and string-length(STATUSEVENTDATE) &gt; 0]">
                                  <xsl:sort data-type="number" order="descending" select="STATUSID" />
                                  <xsl:if test="position() = 1">
                                    <xsl:value-of select="STATUSID" />
                                  </xsl:if>
                                </xsl:for-each>
                              </xsl:variable>
                              <xsl:variable name="mostRecentStatus" select="$dbStatuses/STATUS[STATUSID=$mostRecentStatusID]" />
                              <xsl:if test="APPLIESTOPARTYID">
                                <xsl:attribute name="AppliesToPartyID">
                                  <xsl:value-of select="APPLIESTOPARTYID" />
                                </xsl:attribute>
                              </xsl:if>
                              <xsl:for-each select="$incomingPolicy/ns2:RequirementInfo[position()=$dbReqInfoPosition]">
                                <xsl:if test="@RequesterPartyID">
                                  <xsl:attribute name="RequesterPartyID">
                                    <xsl:value-of select="@RequesterPartyID" />
                                  </xsl:attribute>
                                </xsl:if>
                                <xsl:if test="@FulfillerPartyID">
                                  <xsl:attribute name="FulfillerPartyID">
                                    <xsl:value-of select="@FulfillerPartyID" />
                                  </xsl:attribute>
                                </xsl:if>
                                <xsl:if test="ns2:RequirementDetails">
                                  <xsl:apply-templates select="ns2:RequirementDetails" />
                                </xsl:if>
                                <xsl:if test="ns2:ReceivedAtLocationDate">
                                  <xsl:apply-templates select="ns2:ReceivedAtLocationDate" />
                                </xsl:if>
                                <xsl:if test="ns2:CarrierOrderNum">
                                  <xsl:apply-templates select="ns2:CarrierOrderNum" />
                                </xsl:if>
                              </xsl:for-each>
                              <ns2:ReqCode tc="{REQCODETC}">
                                <xsl:value-of select="REQCODETXT" />
                              </ns2:ReqCode>
                              <ns2:RequirementInfoUniqueID>
                                <xsl:value-of select="UNIQUEID" />
                              </ns2:RequirementInfoUniqueID>
                              <ns2:ReqStatus>
                                <xsl:choose>
                                  <xsl:when test="string-length(REQSTATUS) &gt; 0">
                                    <xsl:attribute name="tc">
                                      <xsl:call-template name="TabularMapping_ReqStatusToTC">
                                        <xsl:with-param name="value" select="REQSTATUS" />
                                      </xsl:call-template>
                                    </xsl:attribute>
                                    <xsl:value-of select="REQSTATUS" />
                                  </xsl:when>
                                  <xsl:when test="string-length($completeDate) &gt; 0">
                                    <xsl:attribute name="tc">11</xsl:attribute>
                                    <xsl:text>Completed</xsl:text>
                                  </xsl:when>
                                  <xsl:when test="count($dbStatuses/STATUS[REQINFOID=$dbReqInfoID]) &gt; 0 and not($dbStatuses/STATUS[REQINFOID=$dbReqInfoID][PROVIDEREVENTCODE!='S85' and PROVIDEREVENTCODE!='S65' and PROVIDEREVENTCODE!='S79'])">
                                    <xsl:attribute name="tc">7</xsl:attribute>
                                    <xsl:text>Received</xsl:text>
                                  </xsl:when>
                                  <xsl:when test="string-length($mostRecentStatus/STATUSEVENTTYPECODE) &gt; 0">
                                    <xsl:variable name="reqStatusTc">
                                      <xsl:call-template name="TabularMapping_StatusEventTcToResStatusTc">
                                        <xsl:with-param name="value" select="$mostRecentStatus/STATUSEVENTTYPECODE" />
                                      </xsl:call-template>
                                    </xsl:variable>
                                    <xsl:attribute name="tc">
                                      <xsl:value-of select="$reqStatusTc" />
                                    </xsl:attribute>
                                    <xsl:call-template name="TabularMapping_ReqStatusFromTC">
                                      <xsl:with-param name="value" select="$reqStatusTc" />
                                    </xsl:call-template>
                                  </xsl:when>
                                  <xsl:otherwise />
                                </xsl:choose>
                              </ns2:ReqStatus>
                              <ns2:RequestedDate>
                                <xsl:value-of select="REQDATE" />
                              </ns2:RequestedDate>
                              <xsl:if test="string-length($fulfilledDate) &gt; 0">
                                <ns2:FulfilledDate>
                                  <xsl:call-template name="dateTimeToDate">
                                    <xsl:with-param name="value" select="$fulfilledDate" />
                                  </xsl:call-template>
                                </ns2:FulfilledDate>
                              </xsl:if>
                              <ns2:StatusDate>
                                <xsl:call-template name="dateTimeToDate">
                                  <xsl:with-param name="value" select="$mostRecentStatus/STATUSEVENTDATE" />
                                </xsl:call-template>
                              </ns2:StatusDate>
                              <ns2:ReleasePartyOrgCode>
                                <xsl:value-of select="RELEASEPARTYORGCODE" />
                              </ns2:ReleasePartyOrgCode>
                              <ns2:RequirementAcctNum>
                                <xsl:value-of select="REQACCTNUM" />
                              </ns2:RequirementAcctNum>
                              <ns2:RequirementDetails>
                                <xsl:value-of select="REQ_DETAILS" />
                              </ns2:RequirementDetails>
                              <ns2:ProviderOrderNum>
                                <xsl:value-of select="$flowNetOrderNum" />
                              </ns2:ProviderOrderNum>
                              <ns2:OrderReceivedDate>
                                <xsl:call-template name="dateTimeToDate">
                                  <xsl:with-param name="value" select="$createdDate" />
                                </xsl:call-template>
                              </ns2:OrderReceivedDate>
                              <xsl:for-each select="$dbStatuses/STATUS[REQINFOID=$dbReqInfoID][$includePreviouslySentStatuses='true' or not(string-length(MESSAGESENTDATE) &gt; 0)]">
                                <xsl:sort select="STATUSID" />
                                <xsl:variable name="statusID" select="STATUSID" />
                                <ns2:StatusEvent>
                                  <ns2:StatusEventCode tc="{STATUSEVENTTYPECODE}" />
                                  <ns2:ProviderEventCode>
                                    <xsl:value-of select="PROVIDEREVENTCODE" />
                                  </ns2:ProviderEventCode>
                                  <ns2:StatusEventDate>
                                    <xsl:call-template name="dateTimeToDate">
                                      <xsl:with-param name="value" select="STATUSEVENTDATE" />
                                    </xsl:call-template>
                                  </ns2:StatusEventDate>
                                  <ns2:StatusEventTime>
                                    <xsl:call-template name="formatDateTime">
                                      <xsl:with-param name="inputFormat" select="'yyyy-MM-dd HH:mm:ss'" />
                                      <xsl:with-param name="outputFormat" select="'HH:mm:ssXXX'" />
                                      <xsl:with-param name="inputValue" select="STATUSEVENTDATE" />
                                    </xsl:call-template>
                                  </ns2:StatusEventTime>
                                  <ns2:StatusEventDetail>
                                    <xsl:value-of select="STATUSEVENTDETAIL" />
                                  </ns2:StatusEventDetail>
                                </ns2:StatusEvent>
                                <xsl:for-each select="$dbAttachments/ATTACHMENT[STATUSID=$statusID]">
                                  <xsl:call-template name="WriteAttachment">
                                    <xsl:with-param name="attachment" select="." />
                                  </xsl:call-template>
                                </xsl:for-each>
                              </xsl:for-each>
                            </ns2:RequirementInfo>
                          </xsl:for-each>
                        </xsl:if>
                      </xsl:for-each>
                    </ns2:Policy>
                  </xsl:for-each>
                  <xsl:for-each select="$dbAttachments/ATTACHMENT[string-length(STATUSID) = 0]">
                    <xsl:call-template name="WriteAttachment">
                      <xsl:with-param name="attachment" select="." />
                    </xsl:call-template>
                  </xsl:for-each>
                </ns2:Holding>
              </xsl:for-each>
              <xsl:for-each select="ns2:Party">
                <xsl:apply-templates select="." />
              </xsl:for-each>
              <xsl:for-each select="ns2:Relation">
                <xsl:apply-templates select="." />
              </xsl:for-each>
            </ns2:OLifE>
          </xsl:for-each>
        </ns2:TXLifeRequest>
      </ns2:TXLife>
    </xsl:for-each>
  </xsl:template>
  <!--
	<xsl:template match="*">
		<xsl:element name="{local-name()}">
			<xsl:apply-templates select="@* | node()" />
		</xsl:element>
	</xsl:template>
	<xsl:template match="@*">
		<xsl:attribute name="{local-name()}">
			<xsl:value-of select="." />
		</xsl:attribute>
	</xsl:template>
	<xsl:template match="comment() | text() | processing-instruction()">
		<xsl:copy />
	</xsl:template>
	-->
  <xsl:template match="/ | @* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template name="TabularMapping_ReqStatusToTC">
    <xsl:param name="value" />
    <xsl:variable name="lower">
      <xsl:call-template name="toLowercase">
        <xsl:with-param name="value" select="$value" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="normalize-space($lower)='add'">
        <xsl:text>23</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='approved / accepted'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='approved'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='accepted'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='acknowledged'">
        <xsl:text>19</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='cancelled'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='completed'">
        <xsl:text>11</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='completed with warnings'">
        <xsl:text>13</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='declined / rejected'">
        <xsl:text>6</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='declined'">
        <xsl:text>6</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='rejected'">
        <xsl:text>6</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='document unavailable'">
        <xsl:text>14</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='evaluated'">
        <xsl:text>21</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='in error'">
        <xsl:text>12</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='incomplete'">
        <xsl:text>25</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='order'">
        <xsl:text>22</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='outstanding'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='pending'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='published'">
        <xsl:text>20</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='received'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='requirement reviewed by the underwriter'">
        <xsl:text>17</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='response received - send again'">
        <xsl:text>15</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='submitted'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='unable to evaluate'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='waived'">
        <xsl:text>3</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='other'">
        <xsl:text>2147483647</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($lower)='unknown'">
        <xsl:text>0</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>0</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_ReqStatusFromTC">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='23'">
        <xsl:text>Add</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5'">
        <xsl:text>Approved / Accepted</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='19'">
        <xsl:text>Acknowledged</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='8'">
        <xsl:text>Cancelled</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='11'">
        <xsl:text>Completed</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='13'">
        <xsl:text>Completed with warnings</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='6'">
        <xsl:text>Declined / Rejected</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='14'">
        <xsl:text>Document Unavailable</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='21'">
        <xsl:text>Evaluated</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='12'">
        <xsl:text>In error</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='25'">
        <xsl:text>Incomplete</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='22'">
        <xsl:text>Order</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4'">
        <xsl:text>Outstanding</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='1'">
        <xsl:text>Pending</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='20'">
        <xsl:text>Published</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='7'">
        <xsl:text>Received</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='17'">
        <xsl:text>Requirement reviewed by the underwriter</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='15'">
        <xsl:text>Response Received - send again</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2'">
        <xsl:text>Submitted</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='10'">
        <xsl:text>Unable to evaluate</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='3'">
        <xsl:text>Waived</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2147483647'">
        <xsl:text>Other</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='0'">
        <xsl:text>Unknown</xsl:text>
      </xsl:when>
      <xsl:otherwise>Unknown</xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_StatusEventTcToResStatusTc">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='0'">
        <xsl:text>0</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='28'">
        <xsl:text>11</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='29'">
        <xsl:text>11</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='30'">
        <xsl:text>11</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='31'">
        <xsl:text>11</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='185'">
        <xsl:text>11</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='64'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='236'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='7'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='205'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='105'">
        <xsl:text>25</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='224'">
        <xsl:text>25</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>1</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="toLowercase">
    <xsl:param name="value" />
    <xsl:value-of select="translate($value, $uppercase, $smallcase)" />
  </xsl:template>
  <xsl:template name="dateTimeToDate">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="contains($value, ' ')">
        <xsl:value-of select="substring-before($value,' ')" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="WriteAttachment">
    <xsl:param name="attachment" />
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <ns2:Attachment xmlns="http://ACORD.org/Standards/Life/2">
      <xsl:if test="string-length($attachment/DESCR) &gt; 0">
        <ns2:Description>
          <xsl:value-of select="$attachment/DESCR" />
        </ns2:Description>
      </xsl:if>
      <ns2:FileName>
        <xsl:choose>
          <xsl:when test="string-length($attachment/CRLORIGINALFILENAME) &gt; 0">
            <xsl:value-of select="$attachment/CRLORIGINALFILENAME" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat(converter:getGUIDString(), '.tif')" />
          </xsl:otherwise>
        </xsl:choose>
      </ns2:FileName>
      <xsl:if test="string-length($attachment/CRLDOCUMENTID) &gt; 0">
        <ns2:AttachmentData>
          <xsl:value-of select="$attachment/CRLDOCUMENTID" />
        </ns2:AttachmentData>
      </xsl:if>
      <xsl:if test="string-length($attachment/CRLMIMETYPE) &gt; 0">
        <ns2:MimeTypeTC>
          <xsl:value-of select="$attachment/CRLMIMETYPE" />
        </ns2:MimeTypeTC>
      </xsl:if>
      <xsl:if test="(string-length($attachment/TYPETC) &gt; 0) or (string-length($attachment/TYPETXT) &gt; 0)">
        <ns2:AttachmentType tc="{$attachment/TYPETC}">
          <xsl:value-of select="$attachment/TYPETXT" />
        </ns2:AttachmentType>
      </xsl:if>
      <xsl:if test="string-length($attachment/ENCTYPESTR) &gt; 0">
        <ns2:TransferEncodingTypeString>
          <xsl:value-of select="$attachment/ENCTYPESTR" />
        </ns2:TransferEncodingTypeString>
      </xsl:if>
      <xsl:if test="string-length($attachment/LOCATIONTC) &gt; 0">
        <ns2:AttachmentLocation tc="{$attachment/LOCATIONTC}" />
      </xsl:if>
      <xsl:if test="(string-length($attachment/BASICTYPETC) &gt; 0) or (string-length($attachment/BASICTYPETXT) &gt; 0)">
        <ns2:AttachmentBasicType tc="{$attachment/BASICTYPETC}">
          <xsl:value-of select="$attachment/BASICTYPETXT" />
        </ns2:AttachmentBasicType>
      </xsl:if>
      <xsl:if test="string-length($attachment/ENCTYPETC) &gt; 0">
        <ns2:TransferEncodingTypeTC tc="{$attachment/ENCTYPETC}" />
      </xsl:if>
    </ns2:Attachment>
  </xsl:template>
  <xsl:template name="formatDateTime">
    <!-- Define parameters -->
    <xsl:param name="inputFormat" />
    <xsl:param name="outputFormat" />
    <xsl:param name="inputValue" />
    <!-- Define input and output parameters -->
    <xsl:variable xmlns:java="xalan://java.text.SimpleDateFormat" name="inputDateFormat" select="java:new($inputFormat)" />
    <xsl:variable xmlns:java="xalan://java.text.SimpleDateFormat" name="outputDateFormat" select="java:new($outputFormat)" />
    <!-- Create and set timezone -->
    <xsl:variable xmlns:java="xalan://java.util.TimeZone" name="timeZoneInstance" select="java:getTimeZone('CST6CDT')" />
    <xsl:variable xmlns:java="xalan://java.text.SimpleDateFormat" name="dummy" select="java:setTimeZone($inputDateFormat, $timeZoneInstance)" />
    <xsl:variable xmlns:java="xalan://java.text.SimpleDateFormat" name="dummy" select="java:setTimeZone($outputDateFormat, $timeZoneInstance)" />
    <!-- Parse the input, then format it out -->
    <xsl:variable xmlns:java="xalan://java.text.SimpleDateFormat" name="date" select="java:parse($inputDateFormat, $inputValue)" />
    <xsl:value-of xmlns:java="xalan://java.text.SimpleDateFormat" select="java:format($outputDateFormat, $date)" />
  </xsl:template>
</xsl:stylesheet>

