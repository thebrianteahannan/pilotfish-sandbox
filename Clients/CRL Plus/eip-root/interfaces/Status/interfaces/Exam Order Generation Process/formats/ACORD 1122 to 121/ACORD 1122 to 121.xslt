<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="ns1 converter datetime dtFormatter" extension-element-prefixes="converter" version="1.0">
  <xsl:variable name="InsuredID" select="string(/node()[local-name(.)='TXLife']/node()[local-name(.)='TXLifeRequest']/node()[local-name(.)='OLifE']/node()[local-name(.)='Relation']/node()[local-name(.)='RelationRoleCode'][contains(@tc, '32')]/../@RelatedObjectID)" />
  <xsl:variable name="InsuredState" select="/node()[local-name(.)='TXLife']/node()[local-name(.)='TXLifeRequest']/node()[local-name(.)='OLifE']/node()[local-name(.)='Party'][contains(@id, $InsuredID)]/node()[local-name(.)='Address']/node()[local-name(.)='AddressState']/text()" />
  <xsl:template match="ns1:TXLife">
    <TXLife xmlns="http://ACORD.org/Standards/Life/2" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <UserAuthRequest>
        <UserLoginName />
        <UserPswd>
          <CryptType>NONE</CryptType>
          <Pswd />
        </UserPswd>
        <UserDate>
          <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
        </UserDate>
        <UserTime>
          <xsl:value-of select="dtFormatter:format(datetime:time(),'HH:mm:ss','HH:mm:ss')" />
        </UserTime>
        <VendorApp>
          <VendorName VendorCode="118">CRL-Plus</VendorName>
          <AppName>XMLPROC</AppName>
          <AppVer>1.0.0</AppVer>
        </VendorApp>
      </UserAuthRequest>
      <TXLifeRequest>
        <TransRefGUID>
          <xsl:value-of select="converter:getGUIDString()" />
        </TransRefGUID>
        <TransType tc="121">General Requirements Order Request</TransType>
        <TransExeDate>
          <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
        </TransExeDate>
        <TransExeTime>
          <xsl:value-of select="dtFormatter:format(datetime:time(),'HH:mm:ss','HH:mm:ss')" />
        </TransExeTime>
        <TransMode tc="2">Original</TransMode>
        <NoResponseOK tc="0">False</NoResponseOK>
        <TestIndicator tc="0">False</TestIndicator>
        <OLifE>
          <SourceInfo>
            <CreationDate>
              <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
            </CreationDate>
            <CreationTime>
              <xsl:value-of select="dtFormatter:format(datetime:time(),'HH:mm:ss','HH:mm:ss')" />
            </CreationTime>
            <SourceInfoName>CRL-Plus</SourceInfoName>
            <SourceInfoDescription>Email : INSURANCECS@CRLCORP.COM</SourceInfoDescription>
            <SourceInfoComment>Phone : 8558507587</SourceInfoComment>
          </SourceInfo>
          <Holding id="{ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/@id}">
            <xsl:variable name="policy" select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy" />
            <Policy CarrierPartyID="{$policy/@CarrierPartyID}">
              <PolNumber>
                <xsl:value-of select="$policy/ns1:PolNumber" />
              </PolNumber>
              <xsl:choose>
                <xsl:when test="$policy/ns1:LineOfBusiness != ''">
                  <LineOfBusiness tc="{$policy/ns1:LineOfBusiness/@tc}">
                    <xsl:value-of select="$policy/ns1:LineOfBusiness" />
                  </LineOfBusiness>
                </xsl:when>
                <xsl:otherwise>
                  <LineOfBusiness tc="1">Life</LineOfBusiness>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="$policy/ns1:Jurisdiction != ''">
                <Jurisdiction tc="{$policy/ns1:Jurisdiction/@tc}">
                  <xsl:value-of select="$policy/ns1:Jurisdiction" />
                </Jurisdiction>
              </xsl:if>
              <xsl:if test="$policy/ns1:EffDate != ''">
                <EffDate>
                  <xsl:value-of select="$policy/ns1:EffDate" />
                </EffDate>
              </xsl:if>
              <xsl:if test="$policy/ns1:PaymentMode != ''">
                <PaymentMode tc="{$policy/ns1:PaymentMode/@tc}">
                  <xsl:value-of select="$policy/ns1:PaymentMode" />
                </PaymentMode>
              </xsl:if>
              <xsl:if test="$policy/ns1:PaymentMethod != ''">
                <PaymentMethod tc="{$policy/ns1:PaymentMethod/@tc}">
                  <xsl:value-of select="$policy/ns1:PaymentMethod" />
                </PaymentMethod>
              </xsl:if>
              <ProductType id="{$policy/ns1:ProductType/@tc}">
                <xsl:value-of select="$policy/ns1:ProductType" />
              </ProductType>
              <xsl:apply-templates select="$policy/ns1:Life" />
              <ApplicationInfo>
                <TrackingID>
                  <xsl:value-of select="$policy/ns1:ApplicationInfo/ns1:TrackingID" />
                </TrackingID>
                <!-- Use Insured State if Application Jurisdiction is empty -->
                <xsl:choose>
                  <xsl:when test="$policy/ns1:ApplicationInfo/ns1:ApplicationJurisdiction/text()">
                    <ApplicationJurisdiction tc="{$policy/ns1:ApplicationInfo/ns1:ApplicationJurisdiction/@tc}">
                      <xsl:value-of select="$policy/ns1:ApplicationInfo/ns1:ApplicationJurisdiction" />
                    </ApplicationJurisdiction>
                  </xsl:when>
                  <xsl:otherwise>
                    <ApplicationJurisdiction tc="">
                      <xsl:value-of select="$InsuredState" />
                    </ApplicationJurisdiction>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="$policy/ns1:ApplicationInfo/ns1:PrefLanguage != ''">
                  <PrefLanguage tc="{$policy/ns1:ApplicationInfo/ns1:PrefLanguage/@tc}">
                    <xsl:value-of select="$policy/ns1:ApplicationInfo/ns1:PrefLanguage" />
                  </PrefLanguage>
                </xsl:if>
              </ApplicationInfo>
              <RequirementInfo RequesterPartyID="Party_Carrier">
                <ReqCode tc="535">Diagnose</ReqCode>
                <ReqStatus tc="2">Submitted</ReqStatus>
                <RequestedDate>
                  <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
                </RequestedDate>
                <RequirementAcctNum>
                  <xsl:call-template name="TabularMapping_RequirementAcctNum_Mapping">
                    <xsl:with-param name="value" select="$policy/ns1:RequirementInfo[1]/ns1:RequirementAcctNum" />
                  </xsl:call-template>
                </RequirementAcctNum>
              </RequirementInfo>
            </Policy>
          </Holding>
          <!-- Copy all Party nodes -->
          <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Party">
            <xsl:apply-templates select="." />
          </xsl:for-each>
          <!-- Copy all Relation nodes -->
          <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Relation">
            <xsl:apply-templates select="." />
          </xsl:for-each>
        </OLifE>
      </TXLifeRequest>
    </TXLife>
  </xsl:template>
  <xsl:template match="*">
    <xsl:element name="{local-name()}" namespace="{namespace-uri(.)}">
      <xsl:apply-templates select="@*|node()" />
    </xsl:element>
  </xsl:template>
  <xsl:template match="@*">
    <xsl:attribute name="{local-name()}">
      <xsl:value-of select="." />
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="*[not(@*[.!='']|*|comment()|processing-instruction())       and normalize-space()=''       ]" />
  <xsl:template name="TabularMapping_RequirementAcctNum_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <!-- Axa -->
      <xsl:when test="normalize-space($value)='71711'">
        <xsl:text>02510</xsl:text>
      </xsl:when>
      <!-- Erie -->
      <xsl:when test="normalize-space($value)='71661'">
        <xsl:text>01155</xsl:text>
      </xsl:when>
      <!-- Motorist 1 -->
      <xsl:when test="normalize-space($value)='71789'">
        <xsl:text>05103</xsl:text>
      </xsl:when>
      <!-- Motorist 2 -->
      <xsl:when test="normalize-space($value)='70291'">
        <xsl:text>05103</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>UNKNOWN</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

