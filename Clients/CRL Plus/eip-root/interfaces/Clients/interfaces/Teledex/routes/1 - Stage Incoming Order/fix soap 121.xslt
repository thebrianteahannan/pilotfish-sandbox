<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.0">
  <!-- IdentityTransform -->
  <xsl:template match="/ | @* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:TransType[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:call-template name="transTypeMapping">
          <xsl:with-param name="value" select="." />
        </xsl:call-template>
      </xsl:attribute>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:TestIndicator[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:call-template name="testIndicatorMapping">
          <xsl:with-param name="value" select="." />
        </xsl:call-template>
      </xsl:attribute>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:HoldingTypeCode[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:value-of select="." />
      </xsl:attribute>
      <xsl:call-template name="holdingTypeMapping">
        <xsl:with-param name="value" select="." />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:ProductType[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:value-of select="." />
      </xsl:attribute>
      <xsl:call-template name="productTypeMapping">
        <xsl:with-param name="value" select="." />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:ReqCode[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:value-of select="." />
      </xsl:attribute>
      <xsl:call-template name="reqCodeMapping">
        <xsl:with-param name="value" select="." />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:AttachmentType[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:call-template name="attachmentTypeCodeMapping">
          <xsl:with-param name="value" select="." />
        </xsl:call-template>
      </xsl:attribute>
      <xsl:call-template name="attachmentTypeMapping">
        <xsl:with-param name="value" select="." />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:PartyTypeCode[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:value-of select="." />
      </xsl:attribute>
      <xsl:call-template name="partyTypeCodeMapping">
        <xsl:with-param name="value" select="." />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:GovtIDTC[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:value-of select="." />
      </xsl:attribute>
      <xsl:call-template name="govIDTCMapping">
        <xsl:with-param name="value" select="." />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:AddressTypeCode[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:value-of select="." />
      </xsl:attribute>
      <xsl:call-template name="addressTypeCodeMapping">
        <xsl:with-param name="value" select="." />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:PhoneTypeCode[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:value-of select="." />
      </xsl:attribute>
      <xsl:call-template name="phoneTypeCodeMapping">
        <xsl:with-param name="value" select="." />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:OriginatingObjectType[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:value-of select="." />
      </xsl:attribute>
      <xsl:call-template name="originatingObjectTypeMapping">
        <xsl:with-param name="value" select="." />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:RelatedObjectType[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:value-of select="." />
      </xsl:attribute>
      <xsl:call-template name="relatedObjectTypeMapping">
        <xsl:with-param name="value" select="." />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:RelationRoleCode[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:value-of select="." />
      </xsl:attribute>
      <xsl:call-template name="relationRoleCodeMapping">
        <xsl:with-param name="value" select="." />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:RelationDescription[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:value-of select="." />
      </xsl:attribute>
      <xsl:call-template name="relationDescriptionMapping">
        <xsl:with-param name="value" select="." />
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:Gender[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:choose>
          <xsl:when test="normalize-space(.)='M'">1</xsl:when>
          <xsl:when test="normalize-space(.)='F'">2</xsl:when>
          <xsl:when test="normalize-space(.)='N'">0</xsl:when>
          <xsl:when test="normalize-space(.)='O'">2147483647</xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:value-of select="." />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:PrefPhone[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:choose>
          <xsl:when test="normalize-space(.)='T'">1</xsl:when>
          <xsl:when test="normalize-space(.)='F'">0</xsl:when>
          <xsl:when test="normalize-space(.)='True'">1</xsl:when>
          <xsl:when test="normalize-space(.)='False'">0</xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:value-of select="." />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:ApplicationJurisdiction[string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:call-template name="applicationJurisdictionMapping">
          <xsl:with-param name="value" select="." />
        </xsl:call-template>
      </xsl:attribute>
      <xsl:value-of select="." />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:OLifEExtension[string-length(@tc)=0 and @VendorCode=118 and string-length(@ExtensionCode)=0 and ns1:HearingImpaired='Hearing Impaired']">
    <xsl:copy>
      <xsl:attribute name="VendorCode">
        <xsl:value-of select="@VendorCode" />
      </xsl:attribute>
      <xsl:value-of select="'Hearing Impaired'" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:LanguageInterpreterNeeded[.='Yes' and string-length(@tc)=0]">
    <xsl:copy>
      <xsl:attribute name="tc">
        <xsl:value-of select="'1'" />
      </xsl:attribute>
      <xsl:value-of select="." />
    </xsl:copy>
  </xsl:template>
  <!-- Start of Mapping templates -->
  <xsl:template name="transTypeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="starts-with($value,'General')">121</xsl:when>
      <xsl:when test="starts-with($value,'New ')">103</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="testIndicatorMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='No'">0</xsl:when>
      <xsl:when test="$value='no'">0</xsl:when>
      <xsl:when test="$value='NO'">0</xsl:when>
      <xsl:when test="$value='False'">0</xsl:when>
      <xsl:when test="$value='false'">0</xsl:when>
      <xsl:when test="$value='FALSE'">0</xsl:when>
      <xsl:when test="$value='0'">0</xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="holdingTypeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='2'">Policy</xsl:when>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="productTypeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='0'">L</xsl:when>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="reqCodeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='2'">Collect Blood Sample</xsl:when>
      <xsl:when test="$value='5'">Collect Urine Specimen (HOS)</xsl:when>
      <xsl:when test="$value='10'">Perform Examination By Paramed</xsl:when>
      <xsl:when test="$value='11'">Obtain Attending Physician Statement</xsl:when>
      <xsl:when test="$value='106'">Questionnaire - Medical</xsl:when>
      <xsl:when test="$value='137'">Conduct Tele-Interview</xsl:when>
      <xsl:when test="$value='138'">Inspection Report</xsl:when>
      <xsl:when test="$value='139'">Prepare Inspection Report</xsl:when>
      <xsl:when test="$value='147'">Obtain Motor Vehicle Report</xsl:when>
      <xsl:when test="$value='330'">Criminal Records Report</xsl:when>
      <xsl:when test="$value='334'">Financial Credit Check</xsl:when>
      <xsl:when test="$value='535'">Diagnose</xsl:when>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="attachmentTypeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='1'">Document</xsl:when>
      <xsl:when test="$value='2'">Comment</xsl:when>
      <xsl:when test="$value='3'">Letter</xsl:when>
      <xsl:when test="$value='4'">E-Mail</xsl:when>
      <xsl:when test="$value='5'">Form</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="attachmentTypeCodeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='Document'">1</xsl:when>
      <xsl:when test="$value='Comment'">2</xsl:when>
      <xsl:when test="$value='Comment/Remark'">2</xsl:when>
      <xsl:when test="$value='Letter'">3</xsl:when>
      <xsl:when test="$value='E-Mail'">4</xsl:when>
      <xsl:when test="$value='Form'">5</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="partyTypeCodeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='1'">Person</xsl:when>
      <xsl:when test="$value='2'">Organization</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="govIDTCMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='1'">Social Security Number US</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="addressTypeCodeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='0'">Unknown</xsl:when>
      <xsl:when test="$value='1'">Residence</xsl:when>
      <xsl:when test="$value='2'">Business</xsl:when>
      <xsl:when test="$value='3'">Vacation</xsl:when>
      <xsl:when test="$value='17'">Mailing</xsl:when>
      <xsl:when test="$value='26'">Billing Mailing</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="phoneTypeCodeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='1'">Home</xsl:when>
      <xsl:when test="$value='2'">Business</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="originatingObjectTypeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='1'">Client</xsl:when>
      <xsl:when test="$value='2'">Address</xsl:when>
      <xsl:when test="$value='3'">Phone</xsl:when>
      <xsl:when test="$value='4'">Holding</xsl:when>
      <xsl:when test="$value='6'">Party</xsl:when>
      <xsl:when test="$value='7'">Activity</xsl:when>
      <xsl:when test="$value='8'">Relation</xsl:when>
      <xsl:when test="$value='9'">Attachment</xsl:when>
      <xsl:when test="$value='10'">License</xsl:when>
      <xsl:when test="$value='18'">Policy</xsl:when>
      <xsl:when test="$value='19'">Life</xsl:when>
      <xsl:when test="$value='25'">Annuity</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="relatedObjectTypeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='6'">Party</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="relationRoleCodeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='1'">Spouse</xsl:when>
      <xsl:when test="$value='2'">Child</xsl:when>
      <xsl:when test="$value='3'">Parent</xsl:when>
      <xsl:when test="$value='4'">Sibling</xsl:when>
      <xsl:when test="$value='5'">Family</xsl:when>
      <xsl:when test="$value='6'">Employee</xsl:when>
      <xsl:when test="$value='7'">Employer</xsl:when>
      <xsl:when test="$value='8'">Owner</xsl:when>
      <xsl:when test="$value='9'">Partner</xsl:when>
      <xsl:when test="$value='10'">Advisor</xsl:when>
      <xsl:when test="$value='11'">Agent</xsl:when>
      <xsl:when test="$value='12'">Referral</xsl:when>
      <xsl:when test="$value='14'">Friend</xsl:when>
      <xsl:when test="$value='21'">Client</xsl:when>
      <xsl:when test="$value='31'">Payer</xsl:when>
      <xsl:when test="$value='32'">Insured</xsl:when>
      <xsl:when test="$value='34'">Beneficiary</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="relationDescriptionMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='0'">Son (s)</xsl:when>
      <xsl:when test="$value='1'">Husband</xsl:when>
      <xsl:when test="$value='2'">Wife</xsl:when>
      <xsl:when test="$value='3'">Father</xsl:when>
      <xsl:when test="$value='4'">Mother</xsl:when>
      <xsl:when test="$value='5'">Son</xsl:when>
      <xsl:when test="$value='6'">Daughter</xsl:when>
      <xsl:when test="$value='7'">Brother</xsl:when>
      <xsl:when test="$value='8'">Sister</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="applicationJurisdictionMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='UN'">
        <xsl:text>0</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AL'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AK'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AZ'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AR'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CA'">
        <xsl:text>6</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CO'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CT'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DE'">
        <xsl:text>9</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DC'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='YAP'">
        <xsl:text>11</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FL'">
        <xsl:text>12</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GA'">
        <xsl:text>13</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='HI'">
        <xsl:text>15</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ID'">
        <xsl:text>16</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IL'">
        <xsl:text>17</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IN'">
        <xsl:text>18</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IA'">
        <xsl:text>19</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KS'">
        <xsl:text>20</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KY'">
        <xsl:text>21</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='LA'">
        <xsl:text>22</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ME'">
        <xsl:text>23</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MRSIS'">
        <xsl:text>24</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MD'">
        <xsl:text>25</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MA'">
        <xsl:text>26</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MI'">
        <xsl:text>27</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MN'">
        <xsl:text>28</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MS'">
        <xsl:text>29</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MO'">
        <xsl:text>30</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MT'">
        <xsl:text>31</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NE'">
        <xsl:text>32</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NV'">
        <xsl:text>33</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NH'">
        <xsl:text>34</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NJ'">
        <xsl:text>35</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NM'">
        <xsl:text>36</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NY'">
        <xsl:text>37</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NC'">
        <xsl:text>38</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ND'">
        <xsl:text>39</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MARIS'">
        <xsl:text>40</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OH'">
        <xsl:text>41</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OK'">
        <xsl:text>42</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OR'">
        <xsl:text>43</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PALAU'">
        <xsl:text>44</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PA'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PR'">
        <xsl:text>46</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='RI'">
        <xsl:text>47</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SC'">
        <xsl:text>48</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SD'">
        <xsl:text>49</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TN'">
        <xsl:text>50</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TX'">
        <xsl:text>51</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='UT'">
        <xsl:text>52</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VT'">
        <xsl:text>53</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VI'">
        <xsl:text>54</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VA'">
        <xsl:text>55</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WA'">
        <xsl:text>56</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WV'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WI'">
        <xsl:text>58</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WY'">
        <xsl:text>59</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AB'">
        <xsl:text>101</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='BC'">
        <xsl:text>102</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MB'">
        <xsl:text>103</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NB'">
        <xsl:text>104</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NF'">
        <xsl:text>105</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NT'">
        <xsl:text>106</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NS'">
        <xsl:text>107</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ON'">
        <xsl:text>108</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PE'">
        <xsl:text>109</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='QC'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SK'">
        <xsl:text>111</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='YT'">
        <xsl:text>112</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NU'">
        <xsl:text>113</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>0</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

