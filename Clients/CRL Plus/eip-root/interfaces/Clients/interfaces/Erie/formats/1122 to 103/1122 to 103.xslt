<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="ns1 converter datetime dtFormatter" extension-element-prefixes="converter" version="1.0">
  <xsl:variable name="apos">'</xsl:variable>
  <xsl:template match="ns1:TXLife">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <TXLife Version="2.23.00">
      <UserAuthRequest>
        <VendorApp>
          <VendorName VendorCode="{ns1:UserAuthRequest/ns1:VendorApp/ns1:VendorName/@VendorCode}">
            <xsl:value-of select="ns1:UserAuthRequest/ns1:VendorApp/ns1:VendorName" />
          </VendorName>
          <AppName>
            <xsl:value-of select="ns1:UserAuthRequest/ns1:VendorApp/ns1:AppName" />
          </AppName>
          <AppVer>
            <xsl:value-of select="ns1:UserAuthRequest/ns1:VendorApp/ns1:AppVer" />
          </AppVer>
        </VendorApp>
        <OLifEExtension>
          <!-- Copy the OLifEExtension node -->
          <xsl:apply-templates select="ns1:UserAuthReques/ns1:OLifEExtensiont" />
        </OLifEExtension>
      </UserAuthRequest>
      <TXLifeRequest PrimaryObjectID="{ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/@id}">
        <TransRefGUID>
          <xsl:value-of select="converter:getGUIDString()" />
        </TransRefGUID>
        <TransType tc="103">New Business Submission</TransType>
        <TransExeDate>
          <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
        </TransExeDate>
        <TransExeTime>
          <xsl:value-of select="dtFormatter:format(datetime:time(),'HH:mm:ss','HH:mm:ss')" />
        </TransExeTime>
        <OLifE>
          <SourceInfo>
            <CreationDate>
              <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
            </CreationDate>
            <CreationTime>
              <xsl:value-of select="dtFormatter:format(datetime:time(),'HH:mm:ss','HH:mm:ss')" />
            </CreationTime>
            <SourceInfoName>
              <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:SourceInfoName" />
            </SourceInfoName>
            <SourceInfoDescription>
              <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:SourceInfoDescription" />
            </SourceInfoDescription>
            <SourceInfoComment>
              <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:SourceInfoComment" />
            </SourceInfoComment>
          </SourceInfo>
          <Holding id="{ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/@id}">
            <Policy>
              <PolNumber>
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber" />
              </PolNumber>
              <ProductCode>
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ProductCode" />
              </ProductCode>
              <CarrierCode>
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:CarrierCode" />
              </CarrierCode>
              <PlanName>
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PlanName" />
              </PlanName>
              <PolicyStatus tc="56">
                <xsl:text>Reentry Pending</xsl:text>
              </PolicyStatus>
              <ReplacementType tc="{ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ReplacementType/@tc}">
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ReplacementType" />
              </ReplacementType>
              <PaymentMode tc="{ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PaymentMode/@tc}">
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PaymentMode" />
              </PaymentMode>
              <PaymentMethod tc="{ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PaymentMethod/@tc}">
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PaymentMethod" />
              </PaymentMethod>
              <AccountNumber>
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:AccountNumber" />
              </AccountNumber>
              <RoutingNumber>
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RoutingNumber" />
              </RoutingNumber>
              <BankAcctType tc="{ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:BankAcctType/@tc}">
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:BankAcctType" />
              </BankAcctType>
              <Life>
                <!-- Copy the Life node -->
                <xsl:apply-templates select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:Life/*" />
              </Life>
              <ApplicationInfo>
                <!-- Copy the ApplicationInfo node -->
                <xsl:apply-templates select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/*" />
              </ApplicationInfo>
              <!-- Copy the RequirementInfo node -->
              <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo">
                <xsl:apply-templates select="." />
              </xsl:for-each>
            </Policy>
            <!-- Need to get the info for this Attachment node from the original 103 coming in -->
            <Attachment>
              <Description>Multiple Policy? NO Are select rates being applied for? YES</Description>
              <AttachmentType tc="2">Comment</AttachmentType>
            </Attachment>
          </Holding>
          <!-- Copy all Party nodes -->
          <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Party">
            <xsl:apply-templates select="." />
          </xsl:for-each>
          <!-- Copy all Relation nodes -->
          <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Relation">
            <xsl:apply-templates select="." />
          </xsl:for-each>
          <FormInstance id="TermAppGen-GV">
            <FormName>TermAppGen-GV</FormName>
            <FormResponse>
              <QuestionNumber>ChildInsuredCitizenship</QuestionNumber>
              <ResponseCode>2</ResponseCode>
            </FormResponse>
            <FormResponse>
              <QuestionNumber>PrimaryInsuredCitizenship</QuestionNumber>
              <ResponseCode>1</ResponseCode>
            </FormResponse>
            <!-- Copy Attachment node from RequirementInfo node -->
            <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo">
              <xsl:if test="ns1:Attachment">
                <Attachment>
                  <AttachmentData>
                    <xsl:value-of select="ns1:Attachment/ns1:AttachmentData" />
                  </AttachmentData>
                  <ImageType tc="{ns1:Attachment/ns1:ImageType/@tc}">
                    <xsl:value-of select="ns1:Attachment/ns1:ImageType" />
                  </ImageType>
                </Attachment>
              </xsl:if>
            </xsl:for-each>
          </FormInstance>
        </OLifE>
      </TXLifeRequest>
    </TXLife>
  </xsl:template>
  <xsl:template match="*">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates select="@*|node()" />
    </xsl:element>
  </xsl:template>
  <xsl:template match="@*">
    <xsl:attribute name="{local-name()}">
      <xsl:value-of select="." />
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="ns1:RequestedDate">
    <RequestedDate>
      <xsl:value-of select="dtFormatter:format(datetime:dateTime(),concat('yyyy-MM-dd', $apos, 'T', $apos, 'hh:mm:ss'),'yyyy-MM-dd HH:mm:ss.S')" />
    </RequestedDate>
  </xsl:template>
  <xsl:template match="ns1:Attachment">
    <!-- Do nothing with the Attachment node -->
  </xsl:template>
</xsl:stylesheet>

