<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="ns1 dtFormatter ta td" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:param name="attachmentDescription" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="teledexOrderNumber" select="ta:getAttribute($attributes, 'teledexOrderNumber')" />
  <xsl:variable name="pages" select="ta:getAttribute($attributes, 'PDF.images.count')" />
  <xsl:template match="/ns1:TXLife">
    <xsl:variable name="subject" select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:RequirementAcctNum" />
    <xsl:variable name="caseNo" select="concat('994',$teledexOrderNumber)" />
    <xsl:variable name="insuredParty" select="ns1:TXLifeRequest/ns1:OLifE/ns1:Party[@id = ../ns1:Relation[ns1:RelationRoleCode/@tc=32]/@RelatedObjectID  or @id = ../ns1:Holding/ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant[ns1:LifeParticipantRoleCode/@tc=1]/@PartyID]" />
    <xsl:variable name="polNumber" select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber" />
    <xsl:variable name="physicianParty" select="ns1:OLifE/ns1:Party[@id = ../ns1:Relation[ns1:RelationRoleCode/@tc=41]/@RelatedObjectID]" />
    <xsl:variable name="doctor">
      <xsl:choose>
        <xsl:when test="string-length($physicianParty/ns1:FullName) &gt; 0">
          <xsl:value-of select="$physicianParty/ns1:FullName" />
        </xsl:when>
        <xsl:when test="$physicianParty/ns1:Person">
          <xsl:value-of select="concat($physicianParty/ns1:Person/ns1:FirstName,' ',$physicianParty/ns1:Person/ns1:LastName)" />
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="company">
      <xsl:call-template name="acctToCompanyMapping">
        <xsl:with-param name="value" select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:RequirementAcctNum" />
      </xsl:call-template>
    </xsl:variable>
    <!-- grab only the first attachment since multiple attachments were previously merged into transaction attribute com.crl.mergedTiff -->
    <xsl:for-each select="//ns1:Attachment[ns1:AttachmentBasicType/@tc='2'][1]">
      <xsl:if test="position()=1">
        <Image>
          <PAGES>
            <xsl:choose>
              <xsl:when test="string-length($pages) &gt; 0">
                <xsl:value-of select="$pages" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="1" />
              </xsl:otherwise>
            </xsl:choose>
          </PAGES>
          <SUBJECT>
            <xsl:value-of select="$subject" />
          </SUBJECT>
          <LNAME>
            <xsl:value-of select="$insuredParty/ns1:Person/ns1:LastName" />
          </LNAME>
          <FNAME>
            <xsl:value-of select="$insuredParty/ns1:Person/ns1:FirstName" />
          </FNAME>
          <MI>
            <xsl:value-of select="$insuredParty/ns1:Person/ns1:MiddleName" />
          </MI>
          <DOB>
            <xsl:variable name="dob" select="normalize-space($insuredParty/ns1:Person/ns1:BirthDate)" />
            <xsl:if test="string-length($dob)=10">
              <xsl:value-of select="dtFormatter:format($dob,'yyyy-MM-dd','MM/dd/yyyy')" />
            </xsl:if>
          </DOB>
          <SSN>
            <xsl:value-of select="$insuredParty/ns1:GovtID" />
          </SSN>
          <BSTATE>
            <xsl:variable name="address" select="$insuredParty/ns1:Address" />
            <xsl:choose>
              <xsl:when test="string-length($address/ns1:AddressStateTC/@tc) &gt; 0">
                <xsl:call-template name="TCToStateMapping">
                  <xsl:with-param name="value" select="$address/ns1:AddressStateTC/@tc" />
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="string-length($address/ns1:AddressState) = 2">
                <xsl:value-of select="$address/ns1:AddressState" />
              </xsl:when>
              <xsl:when test="string-length($address/ns1:AddressStateTC) = 2">
                <xsl:value-of select="$address/ns1:AddressStateTC" />
              </xsl:when>
              <xsl:when test="string-length($insuredParty/ns1:ResidenceState/@tc) &gt; 0">
                <xsl:call-template name="TCToStateMapping">
                  <xsl:with-param name="value" select="$insuredParty/ns1:ResidenceState/@tc" />
                </xsl:call-template>
              </xsl:when>
            </xsl:choose>
          </BSTATE>
          <CASENO>
            <xsl:value-of select="$caseNo" />
          </CASENO>
          <POLNO>
            <xsl:value-of select="$polNumber" />
          </POLNO>
          <DOCTOR>
            <xsl:value-of select="$doctor" />
          </DOCTOR>
          <PROVIDER>PMIL</PROVIDER>
          <REQUIRE>
            <xsl:variable name="Description" select="translate($attachmentDescription,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
            <xsl:choose>
              <xsl:when test="$Description = 'ESEARCH'">ESH</xsl:when>
              <xsl:otherwise>INSP</xsl:otherwise>
            </xsl:choose>
          </REQUIRE>
          <COMPANY>
            <xsl:value-of select="$company" />
          </COMPANY>
          <xsl:variable name="baseFilename">
            <xsl:value-of select="$caseNo" />
          </xsl:variable>
          <BASE_FILENAME>
            <xsl:value-of select="$baseFilename" />
          </BASE_FILENAME>
          <INDEX_FILENAME>
            <xsl:value-of select="concat($baseFilename,'.IDX')" />
          </INDEX_FILENAME>
          <IMAGE_FILENAME>
            <xsl:value-of select="concat($baseFilename,'.TIFF')" />
          </IMAGE_FILENAME>
          <DATA>
            <xsl:value-of select="ns1:AttachmentData" />
          </DATA>
        </Image>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  <xsl:template name="uppercase">
    <xsl:param name="value" />
    <xsl:value-of select="translate($value,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
  </xsl:template>
  <xsl:template name="TCToStateMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='0'">
        <xsl:text>UN</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='1'">
        <xsl:text>AL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2'">
        <xsl:text>AK</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4'">
        <xsl:text>AZ</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5'">
        <xsl:text>AR</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='6'">
        <xsl:text>CA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='7'">
        <xsl:text>CO</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='8'">
        <xsl:text>CT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='9'">
        <xsl:text>DE</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='10'">
        <xsl:text>DC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='11'">
        <xsl:text>YAP</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='12'">
        <xsl:text>FL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='13'">
        <xsl:text>GA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='15'">
        <xsl:text>HI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='16'">
        <xsl:text>ID</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='17'">
        <xsl:text>IL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='18'">
        <xsl:text>IN</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='19'">
        <xsl:text>IA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='20'">
        <xsl:text>KS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='21'">
        <xsl:text>KY</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='22'">
        <xsl:text>LA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='23'">
        <xsl:text>ME</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='24'">
        <xsl:text>MRSIS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='25'">
        <xsl:text>MD</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='26'">
        <xsl:text>MA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='27'">
        <xsl:text>MI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='28'">
        <xsl:text>MN</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='29'">
        <xsl:text>MS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='30'">
        <xsl:text>MO</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='31'">
        <xsl:text>MT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='32'">
        <xsl:text>NE</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='33'">
        <xsl:text>NV</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='34'">
        <xsl:text>NH</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='35'">
        <xsl:text>NJ</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='36'">
        <xsl:text>NM</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='37'">
        <xsl:text>NY</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='38'">
        <xsl:text>NC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='39'">
        <xsl:text>ND</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='40'">
        <xsl:text>MARIS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='41'">
        <xsl:text>OH</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='42'">
        <xsl:text>OK</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='43'">
        <xsl:text>OR</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='44'">
        <xsl:text>PALAU</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='45'">
        <xsl:text>PA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='46'">
        <xsl:text>PR</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='47'">
        <xsl:text>RI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='48'">
        <xsl:text>SC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='49'">
        <xsl:text>SD</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='50'">
        <xsl:text>TN</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='51'">
        <xsl:text>TX</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='52'">
        <xsl:text>UT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='53'">
        <xsl:text>VT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='54'">
        <xsl:text>VI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='55'">
        <xsl:text>VA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='56'">
        <xsl:text>WA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='57'">
        <xsl:text>WV</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='58'">
        <xsl:text>WI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='59'">
        <xsl:text>WY</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='101'">
        <xsl:text>AB</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='102'">
        <xsl:text>BC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='103'">
        <xsl:text>MB</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='104'">
        <xsl:text>NB</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='105'">
        <xsl:text>NF</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='106'">
        <xsl:text>NT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='107'">
        <xsl:text>NS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='108'">
        <xsl:text>ON</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='109'">
        <xsl:text>PE</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='110'">
        <xsl:text>QC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='111'">
        <xsl:text>SK</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='112'">
        <xsl:text>YT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='113'">
        <xsl:text>NU</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>UN</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="acctToCompanyMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <!-- TODO Get Company codes for each account number -->
      <xsl:when test="$value='71437'">HOU</xsl:when>
      <xsl:when test="$value='73176'">MOC</xsl:when>
      <xsl:when test="$value='09848'">HOU</xsl:when>
      <xsl:when test="$value='89916'">MOC</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

