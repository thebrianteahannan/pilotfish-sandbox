<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:exslt="http://exslt.org/common" xmlns:java="http://xml.apache.org/xalan/java" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:sql="http://pilotfish.sqlxml" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="sourceClient" select="ta:getAttribute($attributes, 'sourceClient')" />
  <xsl:variable name="timeZoneConversion" select="ta:getAttribute($attributes, 'timeZoneConversion')" />
  <xsl:template match="/ns1:TXLife">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <sql:SQLXML>
      <!-- process new orders -->
      <xsl:for-each select="ns1:TXLifeRequest[ns1:TransMode/@tc = 2 or string-length(ns1:TransMode/@tc) = 0]">
        <!-- check for duplicate order -->
        <sql:Execute as="existingRow" into="existingOrders">
          <xsl:choose>
            <xsl:when test="$sourceClient = 'PACT' or $sourceClient = 'LADDER'">
              <sql:SQL>select c.TRANSACTION_ID, c.FLOWNET_ORDER_NUM, c.TRANSREFGUID, c.PF_SOURCE_CLIENT, p.POLNUMBER from CRLTRANSACTION c inner join POLICY p on c.TRANSACTION_ID=p.TRANSACTION_ID where c.PF_SOURCE_CLIENT = ? and (c.TRANSREFGUID=? or p.TRACKING_ID=?) and decode(c.FLOWNET_ORDER_NUM,'INVALID',1,0)=0</sql:SQL>
              <sql:Params>
                <xsl:value-of select="$sourceClient" />
              </sql:Params>
              <sql:Params>
                <xsl:value-of select="ns1:TransRefGUID" />
              </sql:Params>
              <sql:Params>
                <xsl:choose>
                  <xsl:when test="string-length(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID) &gt; 0">
                    <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="'PF_NO_TRACKING_ID_IN_ACORD_FILE'" />
                  </xsl:otherwise>
                </xsl:choose>
              </sql:Params>
            </xsl:when>
            <xsl:when test="$sourceClient = 'PRUX'">
              <xsl:variable name="insuredParty" select="ns1:OLifE/ns1:Party[@id = ../ns1:Relation[ns1:RelationRoleCode/@tc=32]/@RelatedObjectID]" />
              <sql:SQL>select c.TRANSACTION_ID, c.FLOWNET_ORDER_NUM, c.TRANSREFGUID, c.PF_SOURCE_CLIENT, p.POLNUMBER from CRLTRANSACTION c inner join POLICY p on c.TRANSACTION_ID=p.TRANSACTION_ID and p.IS_PRIMARY_POLICY='Y' inner join PARTY y on c.TRANSACTION_ID=y.TRANSACTION_ID where c.PF_SOURCE_CLIENT = ? and (c.TRANSREFGUID=? or p.TRACKING_ID=? or (decode(y.FIRSTNAME,?,1,0)=1 and decode(y.MIDDLENAME,?,1,0)=1 and decode(y.LASTNAME,?,1,0)=1 and y.BIRTHDATE=to_date(?,'YYYY-MM-DD') and p.POLNUMBER=? and c.CREATED_DATE &gt; (sysdate - 60))) and decode(c.FLOWNET_ORDER_NUM,'INVALID',1,0)=0</sql:SQL>
              <sql:Params>
                <xsl:value-of select="$sourceClient" />
              </sql:Params>
              <sql:Params>
                <xsl:value-of select="ns1:TransRefGUID" />
              </sql:Params>
              <sql:Params>
                <xsl:choose>
                  <xsl:when test="string-length(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID) &gt; 0">
                    <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="'PF_NO_TRACKING_ID_IN_ACORD_FILE'" />
                  </xsl:otherwise>
                </xsl:choose>
              </sql:Params>
              <sql:Params>
                <xsl:value-of select="$insuredParty/ns1:Person/ns1:FirstName" />
              </sql:Params>
              <sql:Params>
                <xsl:value-of select="$insuredParty/ns1:Person/ns1:MiddleName" />
              </sql:Params>
              <sql:Params>
                <xsl:value-of select="$insuredParty/ns1:Person/ns1:LastName" />
              </sql:Params>
              <sql:Params>
                <xsl:value-of select="$insuredParty/ns1:Person/ns1:BirthDate" />
              </sql:Params>
              <sql:Params>
                <xsl:choose>
                  <xsl:when test="string-length(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber) &gt; 0">
                    <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="'PF_NO_POLICY_NUMBER_IN_ACORD_FILE'" />
                  </xsl:otherwise>
                </xsl:choose>
              </sql:Params>
            </xsl:when>
            <xsl:otherwise>
              <sql:SQL>select c.TRANSACTION_ID, c.FLOWNET_ORDER_NUM, c.TRANSREFGUID, c.PF_SOURCE_CLIENT, p.POLNUMBER from CRLTRANSACTION c inner join POLICY p on c.TRANSACTION_ID=p.TRANSACTION_ID where c.PF_SOURCE_CLIENT = ? and c.TRANSREFGUID=? and decode(c.FLOWNET_ORDER_NUM,'INVALID',1,0)=0 and (select max(r.REQ_ACCT_NUM) from REQ_INFO r where r.POLICY_ID=p.POLICY_ID)=?</sql:SQL>
              <sql:Params>
                <xsl:value-of select="$sourceClient" />
              </sql:Params>
              <sql:Params>
                <xsl:value-of select="ns1:TransRefGUID" />
              </sql:Params>
              <sql:Params>
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:RequirementAcctNum" />
              </sql:Params>
            </xsl:otherwise>
          </xsl:choose>
        </sql:Execute>
        <!-- only insert if order isn't already in the database -->
        <sql:If test="#existingOrders.getRecords().length &gt; 0">
          <!-- log warning if order is already in the database -->
          <sql:Assign exp="#existingRecords=#existingOrders.getRecords(), (#existingRecords.length == 0) || @com.pilotfish.eip.server.log.EIPLogManager@getModuleLogger().warn('New order is already in the database. Source client='+#txData.getAttributes().getAttribute('sourceClient')+', Policy number={ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber}, Tracking ID={ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID}, new TransRefGUID={ns1:TransRefGUID}, existing TransRefGUID='+#existingRecords[0].getFieldValue('TRANSREFGUID')+', existing CRLTRANSACTION.TRANSACTION_ID='+#existingRecords[0].getFieldValue('TRANSACTION_ID'))" name="log" />
          <!-- set the 'insert.order.error' transaction attribute with the error message if the order is already in the database -->
          <sql:Assign exp="#existingRecords=#existingOrders.getRecords(), (#existingRecords.length == 0) || #txData.getAttributes().setAttribute('insert.order.error','New order is already in the database. Policy number={ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber}, Tracking ID={ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID}, new TransRefGUID={ns1:TransRefGUID}, existing TransRefGUID='+#existingRecords[0].getFieldValue('TRANSREFGUID'))" name="log" />
          <!--<sql:Assign exp="#existingRecords=#existingOrders.getRecords(), #executionContext.put('errorMessage','New order is already in the database. Policy number={ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber}, new TransRefGUID={ns1:TransRefGUID}, existing TransRefGUID='+#existingRecords[0].getFieldValue('TRANSREFGUID'))" name="log" />-->
          <sql:Assign exp="#existingRecords=#existingOrders.getRecords(), #existingRecords[0].getFieldValue('TRANSACTION_ID')" name="CRLTransactionID" />
          <sql:Assign exp="#existingRecords=#existingOrders.getRecords(), #existingRecords[0].getFieldValue('FLOWNET_ORDER_NUM')" name="FlownetOrderNum" />
          <!-- DO THE INSERTING OF THE 121 ORIGINAL TEXT INTO THE TRANSACTION_TEXT TABLE -->
          <sql:Insert>
            <TRANSACTION_TEXT>
              <ORIGINAL_TXT>
                <xsl:text>$$ATTRIBUTE.com.pilotfish.crl.original.txt</xsl:text>
              </ORIGINAL_TXT>
              <ORIGINAL_TYPE>121</ORIGINAL_TYPE>
            </TRANSACTION_TEXT>
          </sql:Insert>
          <!-- NOW THAT WE'VE INSERTED THE ORIGINAL TRANSACTION TEXT INTO THE DATABASE, LET'S GET THAT NEW ROW'S SEQUENCE NUMBER FOR USE LATER -->
          <sql:Execute as="row" into="results">
            <sql:SQL>SELECT TRANSACTION_TEXT_SEQ.CURRVAL AS CURR_TRANSACTION_TEXT_ID FROM DUAL</sql:SQL>
          </sql:Execute>
          <sql:Iterate as="row" over="results">
            <!-- Insert the validation errors into the VALIDATION_ERROR table -->
            <xsl:variable name="transTextID">ognl:#row.getFieldValue('CURR_TRANSACTION_TEXT_ID')</xsl:variable>
            <sql:Assign name="ReasonForError">
              <xsl:attribute name="exp">
                <xsl:text>'</xsl:text>
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:RequirementAcctNum" />
                <xsl:value-of select="' | '" />
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID" />
                <xsl:value-of select="' | '" />
                <xsl:value-of select="ns1:TransRefGUID" />
                <xsl:value-of select="' | '" />
                <xsl:text>' + #CRLTransactionID + '</xsl:text>
                <xsl:value-of select="' | '" />
                <xsl:text>' + #FlownetOrderNum + '</xsl:text>
                <xsl:value-of select="' | '" />
                <xsl:value-of select="'Duplicate Order'" />
                <xsl:text>'</xsl:text>
              </xsl:attribute>
            </sql:Assign>
            <sql:Execute>
              <sql:SQL>INSERT INTO VALIDATION_ERROR (PF_SOURCE_CLIENT, POLNUMBER, ERROR_DATE, REQ_CODE_TC, REQ_CODE_TXT, REASON_FOR_ERROR, TRANSACTION_TEXT_ID) VALUES (?, ?, sysdate, ?, ?, ?, ?)</sql:SQL>
              <sql:Params>
                <xsl:value-of select="concat('R1_',ta:getAttribute($attributes, 'sourceClient'))" />
              </sql:Params>
              <sql:Params>
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber" />
              </sql:Params>
              <sql:Params>
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:ReqCode/@tc" />
              </sql:Params>
              <sql:Params>
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:ReqCode" />
              </sql:Params>
              <sql:Params>ognl:#ReasonForError</sql:Params>
              <sql:Params>
                <xsl:value-of select="$transTextID" />
              </sql:Params>
            </sql:Execute>
          </sql:Iterate>
          <sql:XMLOut var="existingOrders" />
        </sql:If>
        <sql:If test="#existingOrders.getRecords().length == 0">
          <xsl:variable name="isTeledex">
            <xsl:choose>
              <xsl:when test="string-length(ta:getAttribute($attributes, concat('teledex.ordernum.for.transrefguid.', ns1:TransRefGUID))) &gt; 0">
                <xsl:value-of select="'true'" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'false'" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <sql:Insert>
            <CRLTRANSACTION>
              <TRANSREFGUID>
                <xsl:value-of select="ns1:TransRefGUID" />
              </TRANSREFGUID>
              <TYPE_TC>
                <xsl:value-of select="ns1:TransType/@tc" />
              </TYPE_TC>
              <TYPE_TXT>
                <xsl:value-of select="ns1:TransType" />
              </TYPE_TXT>
              <!-- Oracle date format string is different than Java format string.  See http://www.techonthenet.com/oracle/functions/to_date.php -->
              <EXE_DATE pattern="to_date(?, 'YYYY-MM-DD HH24:MI:SS')" type="VARCHAR">
                <xsl:choose>
                  <xsl:when test="string-length(ns1:TransExeDate) &gt; 0">
                    <xsl:call-template name="formatDateTime">
                      <xsl:with-param name="date" select="ns1:TransExeDate" />
                      <xsl:with-param name="time" select="ns1:TransExeTime" />
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="formatDateTime">
                      <xsl:with-param name="date" select="ns1:OLifE/ns1:SourceInfo/ns1:CreationDate" />
                      <xsl:with-param name="time" select="ns1:OLifE/ns1:SourceInfo/ns1:CreationTime" />
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </EXE_DATE>
              <MODE_TC>
                <xsl:value-of select="ns1:TransMode/@tc" />
              </MODE_TC>
              <MODE_TXT>
                <xsl:value-of select="ns1:TransMode" />
              </MODE_TXT>
              <TESTINDICATOR>
                <xsl:choose>
                  <xsl:when test="ns1:TestIndicator/@tc='2'">
                    <xsl:value-of select="'2'" />
                  </xsl:when>
                  <xsl:when test="ns1:TestIndicator/@tc='1' or ns1:TestIndicator='1' or ns1:TestIndicator='true' or ns1:TestIndicator='yes' or ns1:TestIndicator='t' or ns1:TestIndicator='y' or ns1:TestIndicator='TRUE' or ns1:TestIndicator='YES' or ns1:TestIndicator='T' or ns1:TestIndicator='Y'">
                    <xsl:value-of select="'1'" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="'0'" />
                  </xsl:otherwise>
                </xsl:choose>
              </TESTINDICATOR>
              <CREATION_DATE pattern="to_date(?, 'YYYY-MM-DD HH24:MI:SS')" type="VARCHAR">
                <xsl:choose>
                  <xsl:when test="string-length(ns1:OLifE/ns1:SourceInfo/ns1:CreationDate) &gt; 0">
                    <xsl:call-template name="formatDateTime">
                      <xsl:with-param name="date" select="ns1:OLifE/ns1:SourceInfo/ns1:CreationDate" />
                      <xsl:with-param name="time" select="ns1:OLifE/ns1:SourceInfo/ns1:CreationTime" />
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="formatDateTime">
                      <xsl:with-param name="date" select="ns1:TransExeDate" />
                      <xsl:with-param name="time" select="ns1:TransExeTime" />
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </CREATION_DATE>
              <SOURCE_INFO_NAME>
                <xsl:choose>
                  <xsl:when test="string-length(ns1:OLifE/ns1:SourceInfo/ns1:SourceInfoName) &gt; 0">
                    <xsl:value-of select="ns1:OLifE/ns1:SourceInfo/ns1:SourceInfoName" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="ta:getAttribute($attributes, 'defaultSourceInfoName')" />
                  </xsl:otherwise>
                </xsl:choose>
              </SOURCE_INFO_NAME>
              <SOURCE_INFO_DESCR>
                <xsl:choose>
                  <xsl:when test="string-length(ns1:OLifE/ns1:SourceInfo/ns1:SourceInfoDescription) &gt; 0">
                    <xsl:value-of select="ns1:OLifE/ns1:SourceInfo/ns1:SourceInfoDescription" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="ta:getAttribute($attributes, 'defaultSourceInfoDescr')" />
                  </xsl:otherwise>
                </xsl:choose>
              </SOURCE_INFO_DESCR>
              <PF_SOURCE_CLIENT>
                <xsl:value-of select="$sourceClient" />
              </PF_SOURCE_CLIENT>
              <TELEDEX_REMOTE_ID>
                <xsl:if test="$isTeledex = 'true'">
                  <xsl:value-of select="ta:getAttribute($attributes, concat('teledex.remoteid.for.transrefguid.', ns1:TransRefGUID))" />
                </xsl:if>
              </TELEDEX_REMOTE_ID>
              <TELEDEX_ORDER_NUM>
                <xsl:if test="$isTeledex = 'true'">
                  <xsl:value-of select="ta:getAttribute($attributes, concat('teledex.ordernum.for.transrefguid.', ns1:TransRefGUID))" />
                </xsl:if>
              </TELEDEX_ORDER_NUM>
              <CREATED_BY>
                <xsl:text>pilotfish</xsl:text>
              </CREATED_BY>
              <CREATED_DATE pattern="to_date(?, 'YYYY-MM-DD HH24:MI:SS')" type="VARCHAR">
                <xsl:call-template name="currentDateTime" />
              </CREATED_DATE>
              <LAST_MODIFIED_BY>
                <xsl:text>pilotfish</xsl:text>
              </LAST_MODIFIED_BY>
              <LAST_MODIFIED_DATE pattern="to_date(?, 'YYYY-MM-DD HH24:MI:SS')" type="VARCHAR">
                <xsl:call-template name="currentDateTime" />
              </LAST_MODIFIED_DATE>
            </CRLTRANSACTION>
          </sql:Insert>
          <sql:Execute as="transrow" into="transaction">
            <sql:SQL>SELECT MAX(TRANSACTION_ID) AS TRANSACTION_ID FROM CRLTRANSACTION WHERE TransRefGUID = ?</sql:SQL>
            <sql:Params>
              <xsl:value-of select="ns1:TransRefGUID" />
            </sql:Params>
          </sql:Execute>
          <sql:XMLOut var="transaction" />
          <sql:Iterate as="transrow" over="transaction">
            <sql:Assign exp="@com.pilotfish.eip.server.log.EIPLogManager@getModuleLogger().warn('Created new order. Source client='+#txData.getAttributes().getAttribute('sourceClient')+', Policy number={ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber}, CRLTRANSACTION.TRANSACTION_ID='+#transrow.getFieldValue('TRANSACTION_ID'))" name="log" />
            <xsl:variable name="transactionID">ognl:#transrow.getFieldValue('TRANSACTION_ID')</xsl:variable>
            <!-- INSERT AIE INFO INTO DB THAT CAME IN FROM HTTP HEADERS BUT ONLY IF : sourceClient = 'AIE' -->
            <xsl:choose>
              <xsl:when test="$sourceClient = 'AIE'">
                <sql:Insert>
                  <ACORD_INFORMATION_EXCHANGE>
                    <TRANSACTION_ID>
                      <xsl:value-of select="$transactionID" />
                    </TRANSACTION_ID>
                    <AIE_MESSAGE_ID>
                      <!-- POPULATED FROM HTTP HEADERS IN THE INCOMING 121 HTTP POST REQUEST -->
                      <xsl:value-of select="converter:getAttributeString('com.pilotfish.MessageId')" />
                    </AIE_MESSAGE_ID>
                    <AIE_FROM>
                      <!-- POPULATED FROM HTTP HEADERS IN THE INCOMING 121 HTTP POST REQUEST -->
                      <xsl:value-of select="converter:getAttributeString('com.pilotfish.AieFrom')" />
                    </AIE_FROM>
                    <AIE_FROM_SERVICE>
                      <!-- POPULATED FROM HTTP HEADERS IN THE INCOMING 121 HTTP POST REQUEST -->
                      <xsl:value-of select="converter:getAttributeString('com.pilotfish.AieFromService')" />
                    </AIE_FROM_SERVICE>
                    <AIE_TO>
                      <!-- POPULATED FROM HTTP HEADERS IN THE INCOMING 121 HTTP POST REQUEST -->
                      <xsl:value-of select="converter:getAttributeString('com.pilotfish.AieTo')" />
                    </AIE_TO>
                    <AIE_TO_SERVICE>
                      <!-- POPULATED FROM HTTP HEADERS IN THE INCOMING 121 HTTP POST REQUEST -->
                      <xsl:value-of select="converter:getAttributeString('com.pilotfish.AieToService')" />
                    </AIE_TO_SERVICE>
                    <AIE_REPLY_TO>
                      <!-- MIGHT BE POPULATED FROM HTTP HEADERS IN THE INCOMING 121 HTTP POST REQUEST, BUT IF NOT IN THE HEADERS THEN THE VALUE IS PULLED FROM THE DATABASE -->
                      <xsl:value-of select="converter:getAttributeString('com.pilotfish.AieReplyTo')" />
                    </AIE_REPLY_TO>
                    <AIE_REPLY_TO_SERVICE>
                      <!-- MIGHT BE POPULATED FROM HTTP HEADERS IN THE INCOMING 121 HTTP POST REQUEST, BUT IF NOT IN THE HEADERS THEN THE VALUE IS PULLED FROM THE DATABASE -->
                      <xsl:value-of select="converter:getAttributeString('com.pilotfish.AieReplyToService')" />
                    </AIE_REPLY_TO_SERVICE>
                  </ACORD_INFORMATION_EXCHANGE>
                </sql:Insert>
              </xsl:when>
            </xsl:choose>
            <sql:Insert>
              <TRANSACTION_TEXT>
                <TRANSACTION_ID>
                  <xsl:value-of select="$transactionID" />
                </TRANSACTION_ID>
                <!--<ORIGINAL_TXT literal="true">-->
                <!--<xsl:value-of select="ta:getAttribute($attributes, 'com.pilotfish.crl.original.txt')" />-->
                <ORIGINAL_TXT>
                  <xsl:text>$$ATTRIBUTE.com.pilotfish.crl.original.txt</xsl:text>
                </ORIGINAL_TXT>
                <ORIGINAL_TYPE>
                  <xsl:choose>
                    <xsl:when test="ta:getAttribute($attributes, 'isNailba')='true'">
                      <xsl:value-of select="'NAILBA'" />
                    </xsl:when>
                    <xsl:when test="ta:getAttribute($attributes, 'acordDoctype')='103'">
                      <xsl:value-of select="'ACORD 103'" />
                    </xsl:when>
                    <xsl:when test="ta:getAttribute($attributes, 'acordDoctype')='121'">
                      <xsl:value-of select="'ACORD 121'" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="'OTHER'" />
                    </xsl:otherwise>
                  </xsl:choose>
                </ORIGINAL_TYPE>
                <NORMALIZED_TXT>
                  <!-- Save the normalized text, but only the the current TXLifeRequest element.-->
                  <xsl:variable name="normalizedtxt">
                    <ns2:TXLife xmlns:ns2="http://ACORD.org/Standards/Life/2" Version="">
                      <xsl:apply-templates select="../@*" />
                      <xsl:apply-templates select="../ns2:UserAuthRequest" />
                      <xsl:apply-templates select="." />
                    </ns2:TXLife>
                  </xsl:variable>
                  <xsl:apply-templates mode="escape" select="exslt:node-set($normalizedtxt)" />
                </NORMALIZED_TXT>
              </TRANSACTION_TEXT>
            </sql:Insert>
            <xsl:for-each select="ns1:OLifE/ns1:Holding">
              <sql:Insert>
                <POLICY>
                  <TRANSACTION_ID>
                    <xsl:value-of select="$transactionID" />
                  </TRANSACTION_ID>
                  <HOLDING_ID>
                    <xsl:value-of select="@id" />
                  </HOLDING_ID>
                  <HOLDING_TC>
                    <xsl:value-of select="ns1:HoldingTypeCode/@tc" />
                  </HOLDING_TC>
                  <HOLDING_TC_TXT>
                    <xsl:value-of select="ns1:HoldingTypeCode" />
                  </HOLDING_TC_TXT>
                  <POLNUMBER>
                    <xsl:value-of select="ns1:Policy/ns1:PolNumber" />
                  </POLNUMBER>
                  <LINEOFBUSINESS_TC>
                    <xsl:value-of select="ns1:Policy/ns1:LineOfBusiness/@tc" />
                  </LINEOFBUSINESS_TC>
                  <LINEOFBUSINESS_TC_TXT>
                    <xsl:value-of select="ns1:Policy/ns1:LineOfBusiness" />
                  </LINEOFBUSINESS_TC_TXT>
                  <PRODUCT_TYPE_TC>
                    <xsl:value-of select="ns1:Policy/ns1:ProductType/@tc" />
                  </PRODUCT_TYPE_TC>
                  <PRODUCT_TYPE_TC_TXT>
                    <xsl:value-of select="ns1:Policy/ns1:ProductType" />
                  </PRODUCT_TYPE_TC_TXT>
                  <PRODUCT_CODE>
                    <xsl:value-of select="ns1:Policy/ns1:ProductCode" />
                  </PRODUCT_CODE>
                  <CARRIER_CODE>
                    <xsl:value-of select="ns1:Policy/ns1:CarrierCode" />
                  </CARRIER_CODE>
                  <PAYMENT_MODE_TC>
                    <xsl:value-of select="ns1:Policy/ns1:PaymentMode/@tc" />
                  </PAYMENT_MODE_TC>
                  <PAYMENT_MODE_TXT>
                    <xsl:value-of select="ns1:Policy/ns1:PaymentMode" />
                  </PAYMENT_MODE_TXT>
                  <PAYMENT_METHOD_TC>
                    <xsl:value-of select="ns1:Policy/ns1:PaymentMethod/@tc" />
                  </PAYMENT_METHOD_TC>
                  <PAYMENT_METHOD_TXT>
                    <xsl:value-of select="ns1:Policy/ns1:PaymentMethod" />
                  </PAYMENT_METHOD_TXT>
                  <INITIAL_PREM_AMT>
                    <xsl:value-of select="ns1:Policy/ns1:Life/ns1:InitialPremAmt" />
                    <xsl:choose>
                      <xsl:when test="number(ns1:Policy/ns1:Life/ns1:InitialPremAmt) &gt; 999999999">
                        <xsl:value-of select="'999999999'" />
                      </xsl:when>
                      <xsl:when test="number(ns1:Policy/ns1:Life/ns1:InitialPremAmt) &gt; 0">
                        <xsl:value-of select="ns1:Policy/ns1:Life/ns1:InitialPremAmt" />
                      </xsl:when>
                      <xsl:otherwise />
                    </xsl:choose>
                  </INITIAL_PREM_AMT>
                  <FACE_AMT>
                    <xsl:choose>
                      <xsl:when test="number(ns1:Policy/ns1:Life/ns1:FaceAmt) &gt; 999999999">
                        <xsl:value-of select="'999999999'" />
                      </xsl:when>
                      <xsl:when test="number(ns1:Policy/ns1:Life/ns1:FaceAmt) &gt; 0">
                        <xsl:value-of select="ns1:Policy/ns1:Life/ns1:FaceAmt" />
                      </xsl:when>
                      <xsl:when test="string-length(ns1:Policy/ns1:Life/ns1:TotalRiskAmt) &gt; 0">
                        <xsl:value-of select="ns1:Policy/ns1:Life/ns1:TotalRiskAmt" />
                      </xsl:when>
                      <xsl:otherwise />
                    </xsl:choose>
                  </FACE_AMT>
                  <PLAN_NAME>
                    <xsl:value-of select="ns1:Policy/ns1:PlanName" />
                  </PLAN_NAME>
                  <SHORT_NAME>
                    <xsl:value-of select="ns1:Policy/ns1:Life/ns1:Coverage/ns1:ShortName" />
                  </SHORT_NAME>
                  <LIFECOVSTATUS_TC>
                    <xsl:value-of select="ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeCovStatus/@tc" />
                  </LIFECOVSTATUS_TC>
                  <LIFECOVSTATUS_TXT>
                    <xsl:value-of select="ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeCovStatus" />
                  </LIFECOVSTATUS_TXT>
                  <LIFECOVTYPECODE_TC>
                    <xsl:value-of select="ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeCovTypeCode/@tc" />
                  </LIFECOVTYPECODE_TC>
                  <LIFECOVTYPECODE_TXT>
                    <xsl:value-of select="ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeCovTypeCode" />
                  </LIFECOVTYPECODE_TXT>
                  <INDICATORCODE_TC>
                    <xsl:value-of select="ns1:Policy/ns1:Life/ns1:Coverage/ns1:IndicatorCode/@tc" />
                  </INDICATORCODE_TC>
                  <INDICATORCODE_TXT>
                    <xsl:value-of select="ns1:Policy/ns1:Life/ns1:Coverage/ns1:IndicatorCode" />
                  </INDICATORCODE_TXT>
                  <CURRENTAMT>
                    <xsl:value-of select="ns1:Policy/ns1:Life/ns1:Coverage/ns1:CurrentAmt" />
                  </CURRENTAMT>
                  <PARTICIPANT_PARTY_ID>
                    <xsl:value-of select="ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant/@PartyID" />
                  </PARTICIPANT_PARTY_ID>
                  <PARTICIPANT_ID>
                    <xsl:choose>
                      <xsl:when test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant/@id) &gt; 0">
                        <xsl:value-of select="ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant/@id" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="../ns1:Relation[ns1:RelatedObjectType/@tc=6 and ns1:RelationRoleCode/@tc=32]/@RelatedObjectID" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </PARTICIPANT_ID>
                  <PARTICIPANT_ROLE_CODE_TC>
                    <xsl:value-of select="ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant/ns1:LifeParticipantRoleCode/@tc" />
                  </PARTICIPANT_ROLE_CODE_TC>
                  <PARTICIPANT_ROLE_CODE_TXT>
                    <xsl:value-of select="ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant/ns1:LifeParticipantRoleCode" />
                  </PARTICIPANT_ROLE_CODE_TXT>
                  <TRACKING_ID>
                    <xsl:value-of select="ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID" />
                  </TRACKING_ID>
                  <APP_JURISDICTION_TC>
                    <xsl:value-of select="ns1:Policy/ns1:ApplicationInfo/ns1:ApplicationJurisdiction/@tc" />
                  </APP_JURISDICTION_TC>
                  <APP_JURISDICTION_TXT>
                    <xsl:value-of select="ns1:Policy/ns1:ApplicationInfo/ns1:ApplicationJurisdiction" />
                  </APP_JURISDICTION_TXT>
                  <SIGNED_DATE pattern="to_date(?, 'YYYY-MM-DD HH24:MI:SS')" type="VARCHAR">
                    <xsl:call-template name="formatDate">
                      <xsl:with-param name="date" select="ns1:Policy/ns1:ApplicationInfo/ns1:SignedDate" />
                    </xsl:call-template>
                  </SIGNED_DATE>
                  <PREF_LANG_TC>
                    <xsl:value-of select="ns1:Policy/ns1:ApplicationInfo/ns1:PrefLanguage/@tc" />
                  </PREF_LANG_TC>
                  <PREF_LANG_TXT>
                    <xsl:value-of select="ns1:Policy/ns1:ApplicationInfo/ns1:PrefLanguage" />
                  </PREF_LANG_TXT>
                  <IS_PRIMARY_POLICY>
                    <xsl:choose>
                      <xsl:when test="position()=1">Y</xsl:when>
                      <xsl:otherwise>N</xsl:otherwise>
                    </xsl:choose>
                  </IS_PRIMARY_POLICY>
                  <PRIORITY>
                    <xsl:choose>
                      <xsl:when test="../../ns1:ProcessingInstruction[ns1:ProcessingInstructionType/@tc='9' and ns1:ProcessingInstructionDesc='RAMM']">
                        <xsl:text>High</xsl:text>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:text>Medium</xsl:text>
                      </xsl:otherwise>
                    </xsl:choose>
                  </PRIORITY>
                  <PRIORITY_REASON_ID>
                    <xsl:choose>
                      <xsl:when test="../../ns1:ProcessingInstruction[ns1:ProcessingInstructionType/@tc='9' and ns1:ProcessingInstructionDesc='RAMM']">
                        <xsl:text>1</xsl:text>
                      </xsl:when>
                      <xsl:otherwise />
                    </xsl:choose>
                  </PRIORITY_REASON_ID>
                </POLICY>
              </sql:Insert>
              <sql:Execute as="polrow" into="policy">
                <sql:SQL>SELECT MAX(POLICY_ID) AS POLICY_ID FROM POLICY WHERE TRANSACTION_ID = ?</sql:SQL>
                <sql:Params>
                  <xsl:value-of select="$transactionID" />
                </sql:Params>
              </sql:Execute>
              <sql:Iterate as="polrow" over="policy">
                <xsl:variable name="policyID">ognl:#polrow.getFieldValue('POLICY_ID')</xsl:variable>
                <xsl:for-each select="ns1:Policy/ns1:RequirementInfo[ns1:ReqCode/@tc != 535]">
                  <sql:Insert>
                    <REQ_INFO>
                      <POLICY_ID>
                        <xsl:value-of select="$policyID" />
                      </POLICY_ID>
                      <APPLIES_TO_PARTY_ID>
                        <xsl:value-of select="@AppliesToPartyID" />
                      </APPLIES_TO_PARTY_ID>
                      <REQ_CODE_TC>
                        <xsl:value-of select="ns1:ReqCode/@tc" />
                      </REQ_CODE_TC>
                      <REQ_CODE_TXT>
                        <xsl:value-of select="ns1:ReqCode" />
                      </REQ_CODE_TXT>
                      <UNIQUEID>
                        <xsl:value-of select="ns1:RequirementInfoUniqueID" />
                      </UNIQUEID>
                      <REQ_DATE pattern="to_date(?, 'YYYY-MM-DD HH24:MI:SS')" type="VARCHAR">
                        <xsl:call-template name="formatDate">
                          <xsl:with-param name="date" select="ns1:RequestedDate" />
                        </xsl:call-template>
                      </REQ_DATE>
                      <REQ_SCHEDULED_DATE_TIME pattern="to_date(?, 'YYYY-MM-DD HH24:MI:SS')" type="VARCHAR">
                        <xsl:call-template name="formatDateTime">
                          <xsl:with-param name="date">
                            <xsl:choose>
                              <xsl:when test="string-length(ns1:RequestedScheduleDate) &gt; 0">
                                <xsl:value-of select="ns1:RequestedScheduleDate" />
                              </xsl:when>
                              <xsl:when test="string-length(ns1:ScheduledDate) &gt; 0">
                                <xsl:value-of select="ns1:ScheduledDate" />
                              </xsl:when>
                              <xsl:when test="string-length(ns1:RequestedScheduleTimeStart) &gt; 0">
                                <!-- start time provided without date.  so just use the requested date. -->
                                <xsl:value-of select="ns1:RequestedDate" />
                              </xsl:when>
                              <xsl:otherwise>
                                <!--<xsl:value-of select="ns1:RequestedDate" />-->
                                <xsl:value-of select="''" />
                              </xsl:otherwise>
                            </xsl:choose>
                          </xsl:with-param>
                          <xsl:with-param name="time" select="ns1:RequestedScheduleTimeStart" />
                        </xsl:call-template>
                      </REQ_SCHEDULED_DATE_TIME>
                      <xsl:if test="string-length(ns1:RequestedScheduleTimeEnd) &gt; 0">
                        <REQ_SCHEDULED_END_TIME pattern="to_date(?, 'YYYY-MM-DD HH24:MI:SS')" type="VARCHAR">
                          <xsl:call-template name="formatDateTime">
                            <xsl:with-param name="date">
                              <xsl:choose>
                                <xsl:when test="string-length(ns1:RequestedScheduleDate) &gt; 0">
                                  <xsl:value-of select="ns1:RequestedScheduleDate" />
                                </xsl:when>
                                <xsl:when test="string-length(ns1:ScheduledDate) &gt; 0">
                                  <xsl:value-of select="ns1:ScheduledDate" />
                                </xsl:when>
                                <xsl:when test="string-length(ns1:RequestedScheduleTimeEnd) &gt; 0">
                                  <!-- end time provided without date.  so just use the requested date. -->
                                  <xsl:value-of select="ns1:RequestedDate" />
                                </xsl:when>
                                <xsl:otherwise>
                                  <!--<xsl:value-of select="ns1:RequestedDate" />-->
                                  <xsl:value-of select="''" />
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:with-param>
                            <xsl:with-param name="time" select="ns1:RequestedScheduleTimeEnd" />
                          </xsl:call-template>
                        </REQ_SCHEDULED_END_TIME>
                      </xsl:if>
                      <RELEASE_PARTY_ORG_CODE>
                        <xsl:value-of select="ns1:ReleasePartyOrgCode" />
                      </RELEASE_PARTY_ORG_CODE>
                      <REQ_ACCT_NUM>
                        <xsl:value-of select="ns1:RequirementAcctNum" />
                      </REQ_ACCT_NUM>
                      <REQ_STATUS>
                        <xsl:value-of select="ns1:ReqStatus" />
                      </REQ_STATUS>
                      <REQ_DETAILS>
                        <xsl:value-of select="ns1:RequirementDetails" />
                      </REQ_DETAILS>
                      <CARRIER_ORDER_NUM>
                        <xsl:choose>
                          <xsl:when test="$sourceClient = 'PACT'">
                            <xsl:value-of select="../ns1:PolNumber" />
                          </xsl:when>
                          <xsl:when test="$isTeledex = 'true'">
                            <xsl:value-of select="ta:getAttribute($attributes, concat('teledex.ordernum.for.transrefguid.', ancestor::ns1:TXLifeRequest/ns1:TransRefGUID))" />
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of select="ns1:CarrierOrderNum" />
                          </xsl:otherwise>
                        </xsl:choose>
                      </CARRIER_ORDER_NUM>
                      <LANG_INTERP_NEEDED>
                        <xsl:choose>
                          <xsl:when test="ns1:LanguageInterpreterNeeded/@tc='1'">
                            <xsl:text>Y</xsl:text>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:text>N</xsl:text>
                          </xsl:otherwise>
                        </xsl:choose>
                      </LANG_INTERP_NEEDED>
                      <INTERP_LANG>
                        <xsl:value-of select="ns1:InterpretedLanguage" />
                      </INTERP_LANG>
                      <HEARING_IMPAIRED>
                        <xsl:choose>
                          <xsl:when test="ns1:OLifEExtension[@VendorCode='118']='Hearing Impaired'">
                            <xsl:text>Y</xsl:text>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:text>N</xsl:text>
                          </xsl:otherwise>
                        </xsl:choose>
                      </HEARING_IMPAIRED>
                    </REQ_INFO>
                  </sql:Insert>
                </xsl:for-each>
              </sql:Iterate>
            </xsl:for-each>
            <xsl:for-each select="//ns1:Attachment">
              <sql:Insert>
                <ATTACHMENT>
                  <TRANSACTION_ID>
                    <xsl:value-of select="$transactionID" />
                  </TRANSACTION_ID>
                  <STATUS_ID />
                  <BASICTYPE_TC>
                    <xsl:value-of select="ns1:AttachmentBasicType/@tc" />
                  </BASICTYPE_TC>
                  <BASICTYPE_TXT>
                    <xsl:value-of select="ns1:AttachmentBasicType" />
                  </BASICTYPE_TXT>
                  <DESCR>
                    <xsl:value-of select="substring(ns1:Description,1,2000)" />
                  </DESCR>
                  <TYPE_TC>
                    <xsl:value-of select="ns1:AttachmentType/@tc" />
                  </TYPE_TC>
                  <TYPE_TXT>
                    <xsl:value-of select="ns1:AttachmentType" />
                  </TYPE_TXT>
                  <MIMETYPE>
                    <xsl:value-of select="ns1:MimeType" />
                  </MIMETYPE>
                  <ENCTYPESTR>
                    <xsl:value-of select="ns1:TransferEncodingTypeString" />
                  </ENCTYPESTR>
                  <ENCTYPE_TC>
                    <xsl:value-of select="ns1:TransferEncodingTypeTC/@tc" />
                  </ENCTYPE_TC>
                  <LOCATION_TC>
                    <xsl:value-of select="ns1:AttachmentLocation/@tc" />
                  </LOCATION_TC>
                  <!-- These 4 fields are populated with the results of the imaging service call -->
                  <CRL_DOCUMENT_ID>
                    <xsl:value-of select="ns1:OLifEExtension/ns1:CRL_DOCUMENT_ID" />
                  </CRL_DOCUMENT_ID>
                  <CRL_FOLDER_ID>
                    <xsl:value-of select="ns1:OLifEExtension/ns1:CRL_FOLDER_ID" />
                  </CRL_FOLDER_ID>
                  <CRL_DRAWER_NAME>
                    <xsl:value-of select="ns1:OLifEExtension/ns1:CRL_DRAWER_NAME" />
                  </CRL_DRAWER_NAME>
                  <CRL_PAGE_COUNT>
                    <xsl:value-of select="ns1:OLifEExtension/ns1:CRL_PAGE_COUNT" />
                  </CRL_PAGE_COUNT>
                </ATTACHMENT>
              </sql:Insert>
            </xsl:for-each>
            <xsl:for-each select="ns1:OLifE/ns1:Party">
              <sql:Insert>
                <PARTY>
                  <TRANSACTION_ID>
                    <xsl:value-of select="$transactionID" />
                  </TRANSACTION_ID>
                  <ACORD_PARTY_ID>
                    <xsl:value-of select="@id" />
                  </ACORD_PARTY_ID>
                  <PARTY_TC>
                    <xsl:value-of select="ns1:PartyTypeCode/@tc" />
                  </PARTY_TC>
                  <PARTY_TC_TXT>
                    <xsl:value-of select="ns1:PartyTypeCode" />
                  </PARTY_TC_TXT>
                  <GOVTID>
                    <xsl:value-of select="ns1:GovtID" />
                  </GOVTID>
                  <FIRSTNAME>
                    <!--<xsl:value-of select="ns1:Person/ns1:FirstName" />-->
                    <xsl:value-of select="normalize-space(ns1:Person/ns1:FirstName)" />
                  </FIRSTNAME>
                  <LASTNAME>
                    <xsl:value-of select="ns1:Person/ns1:LastName" />
                  </LASTNAME>
                  <MIDDLENAME>
                    <xsl:value-of select="ns1:Person/ns1:MiddleName" />
                  </MIDDLENAME>
                  <OCCUPATION>
                    <xsl:value-of select="ns1:Person/ns1:Occupation" />
                  </OCCUPATION>
                  <GENDER_TC>
                    <xsl:value-of select="ns1:Person/ns1:Gender/@tc" />
                  </GENDER_TC>
                  <GENDER_TXT>
                    <xsl:value-of select="substring(ns1:Person/ns1:Gender,1,45)" />
                  </GENDER_TXT>
                  <BIRTHDATE pattern="to_date(?, 'YYYY-MM-DD HH24:MI:SS')" type="VARCHAR">
                    <xsl:call-template name="formatDate">
                      <xsl:with-param name="date" select="ns1:Person/ns1:BirthDate" />
                    </xsl:call-template>
                  </BIRTHDATE>
                  <CITIZENSHIP_TC>
                    <xsl:value-of select="ns1:Person/ns1:Citizenship/@tc" />
                  </CITIZENSHIP_TC>
                  <CITIZENSHIP_TXT>
                    <xsl:value-of select="substring(ns1:Person/ns1:Citizenship,1,45)" />
                  </CITIZENSHIP_TXT>
                  <BIRTHCOUNTRY_TC>
                    <xsl:value-of select="ns1:Person/ns1:BirthCountry/@tc" />
                  </BIRTHCOUNTRY_TC>
                  <BIRTHCOUNTRY_TXT>
                    <xsl:value-of select="substring(ns1:Person/ns1:BirthCountry,1,45)" />
                  </BIRTHCOUNTRY_TXT>
                  <BIRTHJURISDICTION_TC>
                    <xsl:value-of select="ns1:Person/ns1:BirthJurisdictionTC/@tc" />
                  </BIRTHJURISDICTION_TC>
                  <PREFIX>
                    <xsl:value-of select="ns1:Person/ns1:Prefix" />
                  </PREFIX>
                  <FULLNAME>
                    <xsl:choose>
                      <xsl:when test="ns1:FullName">
                        <xsl:value-of select="substring(ns1:FullName,1,255)" />
                      </xsl:when>
                      <xsl:when test="ns1:Organization/ns1:DBA">
                        <xsl:value-of select="substring(ns1:Organization/ns1:DBA,1,255)" />
                      </xsl:when>
                      <xsl:otherwise />
                    </xsl:choose>
                  </FULLNAME>
                  <RESIDENCE_ST_TC>
                    <xsl:value-of select="ns1:ResidenceState/@tc" />
                  </RESIDENCE_ST_TC>
                  <RESIDENCE_ST_TXT>
                    <xsl:value-of select="substring(ns1:ResidenceState,1,45)" />
                  </RESIDENCE_ST_TXT>
                  <RESIDENCE_CTRY_TC>
                    <xsl:value-of select="ns1:ResidenceCountry/@tc" />
                  </RESIDENCE_CTRY_TC>
                  <RESIDENCE_CTRY_TXT>
                    <xsl:value-of select="substring(ns1:ResidenceCountry,1,45)" />
                  </RESIDENCE_CTRY_TXT>
                  <BESTTIMETOCALLFROM>
                    <xsl:choose>
                      <xsl:when test="ns1:BestTimeToCallFrom">
                        <xsl:value-of select="substring(ns1:BestTimeToCallFrom,1,14)" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="substring(ns1:Phone/ns1:BestTimeToCallFrom,1,14)" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </BESTTIMETOCALLFROM>
                  <BESTTIMETOCALLTO>
                    <xsl:choose>
                      <xsl:when test="ns1:BestTimeToCallFrom">
                        <xsl:value-of select="substring(ns1:BestTimeToCallTo,1,14)" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="substring(ns1:Phone/ns1:BestTimeToCallTo,1,14)" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </BESTTIMETOCALLTO>
                  <CLIENT_KEY>
                    <xsl:value-of select="substring(ns1:Client/ns1:ClientKey,1,45)" />
                  </CLIENT_KEY>
                </PARTY>
              </sql:Insert>
              <sql:Execute as="partyrow" into="party">
                <sql:SQL>SELECT MAX(PARTY_ID) AS PARTY_ID FROM PARTY WHERE TRANSACTION_ID = ?</sql:SQL>
                <sql:Params>
                  <xsl:value-of select="$transactionID" />
                </sql:Params>
              </sql:Execute>
              <sql:Iterate as="partyrow" over="party">
                <xsl:variable name="partyID">ognl:#partyrow.getFieldValue('PARTY_ID')</xsl:variable>
                <xsl:for-each select="ns1:Address[ns1:AddressTypeCode/@tc='1' or not(../ns1:Address[ns1:AddressTypeCode/@tc='1'])][1]">
                  <sql:Insert>
                    <ADDRESS>
                      <PARTY_ID>
                        <xsl:value-of select="$partyID" />
                      </PARTY_ID>
                      <!-- For 1 Address, default it to 1 (home), otherwise do normal operation -->
                      <ADDRESS_TC>
                        <xsl:value-of select="'1'" />
                      </ADDRESS_TC>
                      <ADDRESS_TC_TXT>
                        <xsl:value-of select="'Home'" />
                      </ADDRESS_TC_TXT>
                      <LINE1>
                        <xsl:value-of select="ns1:Line1" />
                      </LINE1>
                      <LINE2>
                        <xsl:value-of select="ns1:Line2" />
                      </LINE2>
                      <LINE3 />
                      <CITY>
                        <xsl:value-of select="ns1:City" />
                      </CITY>
                      <STATE_TC>
                        <xsl:value-of select="ns1:AddressStateTC/@tc" />
                      </STATE_TC>
                      <STATE_TXT>
                        <xsl:choose>
                          <xsl:when test="ns1:AddressState">
                            <xsl:value-of select="ns1:AddressState" />
                          </xsl:when>
                          <xsl:when test="string-length(ns1:AddressStateTC) &gt; 0">
                            <xsl:value-of select="ns1:AddressStateTC" />
                          </xsl:when>
                          <xsl:otherwise />
                        </xsl:choose>
                      </STATE_TXT>
                      <ZIP>
                        <xsl:value-of select="ns1:Zip" />
                      </ZIP>
                      <PREVENTOVERRIDEIND_TC>
                        <xsl:value-of select="ns1:PreventOverrideInd/@tc" />
                      </PREVENTOVERRIDEIND_TC>
                    </ADDRESS>
                  </sql:Insert>
                </xsl:for-each>
                <xsl:for-each select="ns1:Phone[string-length(ns1:DialNumber) &gt; 0]">
                  <sql:Insert>
                    <PHONE>
                      <PARTY_ID>
                        <xsl:value-of select="$partyID" />
                      </PARTY_ID>
                      <PHONE_TC>
                        <xsl:value-of select="ns1:PhoneTypeCode/@tc" />
                      </PHONE_TC>
                      <AREACODE>
                        <xsl:value-of select="ns1:AreaCode" />
                      </AREACODE>
                      <DIALNUM>
                        <xsl:value-of select="ns1:DialNumber" />
                      </DIALNUM>
                      <BESTTIMETOCALLFROM>
                        <xsl:value-of select="ns1:BestTimeToCallFrom" />
                      </BESTTIMETOCALLFROM>
                      <BESTTIMETOCALLTO>
                        <xsl:value-of select="ns1:BestTimeToCallTo" />
                      </BESTTIMETOCALLTO>
                      <EXTENSION>
                        <xsl:value-of select="ns1:Ext" />
                      </EXTENSION>
                      <PREF_PHONE>
                        <xsl:choose>
                          <xsl:when test="ns1:PrefPhone/@tc='1'">Y</xsl:when>
                          <xsl:otherwise>N</xsl:otherwise>
                        </xsl:choose>
                      </PREF_PHONE>
                    </PHONE>
                  </sql:Insert>
                </xsl:for-each>
                <!-- CHECK if the party is person and there is a business phone number -->
                <xsl:if test="$isTeledex='true' and ../ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:ReleasePartyOrgCode='AIGP' and ns1:PartyTypeCode/@tc = '1' and ../ns1:Party[ns1:PartyTypeCode/@tc='2']/ns1:Phone/ns1:PhoneTypeCode[@tc='2']">
                  <xsl:variable name="businessPhone" select="../ns1:Party[ns1:PartyTypeCode/@tc='2']/ns1:Phone/ns1:PhoneTypeCode[@tc='2']/.." />
                  <sql:Insert>
                    <PHONE>
                      <PARTY_ID>
                        <xsl:value-of select="$partyID" />
                      </PARTY_ID>
                      <PHONE_TC>
                        <xsl:value-of select="$businessPhone/ns1:PhoneTypeCode/@tc" />
                      </PHONE_TC>
                      <AREACODE>
                        <xsl:value-of select="$businessPhone/ns1:AreaCode" />
                      </AREACODE>
                      <DIALNUM>
                        <xsl:value-of select="$businessPhone/ns1:DialNumber" />
                      </DIALNUM>
                      <BESTTIMETOCALLFROM>
                        <xsl:value-of select="$businessPhone/ns1:BestTimeToCallFrom" />
                      </BESTTIMETOCALLFROM>
                      <BESTTIMETOCALLTO>
                        <xsl:value-of select="$businessPhone/ns1:BestTimeToCallTo" />
                      </BESTTIMETOCALLTO>
                      <EXTENSION>
                        <xsl:value-of select="$businessPhone/ns1:Ext" />
                      </EXTENSION>
                      <PREF_PHONE>
                        <xsl:choose>
                          <xsl:when test="$businessPhone/ns1:PrefPhone/@tc='1'">Y</xsl:when>
                          <xsl:otherwise>N</xsl:otherwise>
                        </xsl:choose>
                      </PREF_PHONE>
                    </PHONE>
                  </sql:Insert>
                </xsl:if>
                <!-- END OF CHECK -->
                <xsl:for-each select="ns1:EMailAddress">
                  <sql:Insert>
                    <EMAIL>
                      <PARTY_ID>
                        <xsl:value-of select="$partyID" />
                      </PARTY_ID>
                      <EMAIL_ADDR>
                        <xsl:value-of select="ns1:AddrLine" />
                      </EMAIL_ADDR>
                    </EMAIL>
                  </sql:Insert>
                </xsl:for-each>
              </sql:Iterate>
            </xsl:for-each>
            <xsl:variable name="holdingIdTxt" select="ns1:OLifE/ns1:Holding/@id" />
            <xsl:for-each select="ns1:OLifE/ns1:Relation">
              <sql:Execute>
                <sql:SQL>
                  <xsl:text>INSERT INTO RELATION (ORIGINATING_POLICY_ID, ORIGINATING_PARTY_ID, RELATED_POLICY_ID, RELATED_PARTY_ID, RELATION_ID_TXT, ORIG_OBJ_TC, REL_OBJ_TC, ROLECODE_TC, RELATION_ROLE, RELATION_DESCRIPTION)</xsl:text>
                  <xsl:text>VALUES (</xsl:text>
                  <!-- ORIGINATING_POLICY_ID -->
                  <xsl:text>(SELECT POLICY_ID FROM POLICY WHERE HOLDING_ID = ? AND TRANSACTION_ID = ? AND ROWNUM&lt;=1),</xsl:text>
                  <!-- ORIGINATING_PARTY_ID -->
                  <xsl:text>(SELECT PARTY_ID FROM PARTY WHERE ACORD_PARTY_ID = ? AND TRANSACTION_ID = ? AND ROWNUM&lt;=1),</xsl:text>
                  <!-- RELATED_POLICY_ID -->
                  <xsl:text>(SELECT POLICY_ID FROM POLICY WHERE HOLDING_ID = ? AND TRANSACTION_ID = ? AND ROWNUM&lt;=1),</xsl:text>
                  <!-- RELATED_PARTY_ID -->
                  <xsl:text>(SELECT PARTY_ID FROM PARTY WHERE ACORD_PARTY_ID = ? AND TRANSACTION_ID = ? AND ROWNUM&lt;=1),</xsl:text>
                  <!-- RELATION_ID_TXT -->
                  <xsl:text>?,</xsl:text>
                  <!-- ORIG_OBJ_TC -->
                  <xsl:text>?,</xsl:text>
                  <!-- REL_OBJ_TC -->
                  <xsl:text>?,</xsl:text>
                  <!-- ROLECODE_TC -->
                  <xsl:text>?,</xsl:text>
                  <!-- RELATION_ROLE -->
                  <xsl:text>?,</xsl:text>
                  <!-- RELATION_DESCRIPTION -->
                  <xsl:text>?)</xsl:text>
                </sql:SQL>
                <!-- START OF PARAMS -->
                <!-- ORIGINATING_POLICY_ID -->
                <sql:Params>
                  <xsl:value-of select="@OriginatingObjectID" />
                </sql:Params>
                <sql:Params>
                  <xsl:value-of select="$transactionID" />
                </sql:Params>
                <!-- ORIGINATING_PARTY_ID -->
                <sql:Params>
                  <xsl:value-of select="@OriginatingObjectID" />
                </sql:Params>
                <sql:Params>
                  <xsl:value-of select="$transactionID" />
                </sql:Params>
                <!-- RELATED_POLICY_ID -->
                <sql:Params>
                  <xsl:value-of select="@RelatedObjectID" />
                </sql:Params>
                <sql:Params>
                  <xsl:value-of select="$transactionID" />
                </sql:Params>
                <!-- RELATED_PARTY_ID -->
                <sql:Params>
                  <xsl:value-of select="@RelatedObjectID" />
                </sql:Params>
                <sql:Params>
                  <xsl:value-of select="$transactionID" />
                </sql:Params>
                <!-- RELATION_ID_TXT -->
                <sql:Params>
                  <xsl:value-of select="substring(@id,1,45)" />
                </sql:Params>
                <!-- ORIG_OBJ_TC -->
                <sql:Params>
                  <xsl:value-of select="ns1:OriginatingObjectType/@tc" />
                </sql:Params>
                <!-- REL_OBJ_TC -->
                <sql:Params>
                  <xsl:value-of select="ns1:RelatedObjectType/@tc" />
                </sql:Params>
                <!-- ROLECODE_TC -->
                <sql:Params>
                  <xsl:value-of select="ns1:RelationRoleCode/@tc" />
                </sql:Params>
                <!-- RELATION_ROLE -->
                <sql:Params>
                  <xsl:value-of select="ns1:RelationRoleCode" />
                </sql:Params>
                <!-- RELATION_DESCRIPTION -->
                <sql:Params>
                  <xsl:value-of select="ns1:RelationDescription" />
                </sql:Params>
              </sql:Execute>
            </xsl:for-each>
          </sql:Iterate>
          <!-- uncomment to commit each individual order in a batch -->
          <!--
				<sql:Execute>
					<sql:SQL>commit</sql:SQL>
				</sql:Execute>
				-->
        </sql:If>
      </xsl:for-each>
      <!-- process order cancellations -->
      <xsl:for-each select="ns1:TXLifeRequest[ns1:TransMode/@tc = 6]">
        <!-- update CRLTRANSACTION record to show that the order has been canceled -->
        <ns1:Execute>
          <xsl:choose>
            <xsl:when test="$sourceClient = 'METL'">
              <ns1:SQL>
                <xsl:text>UPDATE CRLTRANSACTION SET MODE_TC = 6, MODE_TXT = 'Cancel', LAST_MODIFIED_BY = 'pilotfish', LAST_MODIFIED_DATE = to_date(?, 'YYYY-MM-DD HH24:MI:SS')  WHERE TRANSACTION_ID in (SELECT p.TRANSACTION_ID FROM POLICY p INNER JOIN REQ_INFO r ON p.POLICY_ID=r.POLICY_ID WHERE r.CARRIER_ORDER_NUM = ?)</xsl:text>
              </ns1:SQL>
              <ns1:Params>
                <xsl:call-template name="currentDateTime" />
              </ns1:Params>
              <ns1:Params>
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:CarrierOrderNum" />
              </ns1:Params>
            </xsl:when>
            <xsl:when test="$sourceClient = 'PACT'">
              <ns1:SQL>
                <xsl:text>UPDATE CRLTRANSACTION SET MODE_TC = 6, MODE_TXT = 'Cancel', LAST_MODIFIED_BY = 'pilotfish', LAST_MODIFIED_DATE = to_date(?, 'YYYY-MM-DD HH24:MI:SS') WHERE TRANSACTION_ID in (SELECT p.TRANSACTION_ID FROM POLICY p WHERE p.TRACKING_ID = ?)</xsl:text>
              </ns1:SQL>
              <ns1:Params>
                <xsl:call-template name="currentDateTime" />
              </ns1:Params>
              <sql:Params>
                <xsl:choose>
                  <xsl:when test="string-length(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID) &gt; 0">
                    <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="'PF_NO_TRACKING_ID_IN_ACORD_FILE'" />
                  </xsl:otherwise>
                </xsl:choose>
              </sql:Params>
            </xsl:when>
            <xsl:when test="string-length(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber) = 0 and string-length(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID) &gt; 0">
              <ns1:SQL>
                <xsl:text>UPDATE CRLTRANSACTION SET MODE_TC = 6, MODE_TXT = 'Cancel', LAST_MODIFIED_BY = 'pilotfish', LAST_MODIFIED_DATE = to_date(?, 'YYYY-MM-DD HH24:MI:SS') WHERE TRANSACTION_ID in (SELECT p.TRANSACTION_ID FROM POLICY p WHERE p.TRACKING_ID = ?)</xsl:text>
              </ns1:SQL>
              <ns1:Params>
                <xsl:call-template name="currentDateTime" />
              </ns1:Params>
              <ns1:Params>
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID" />
              </ns1:Params>
            </xsl:when>
            <xsl:otherwise>
              <ns1:SQL>
                <xsl:text>UPDATE CRLTRANSACTION SET MODE_TC = 6, MODE_TXT = 'Cancel', LAST_MODIFIED_BY = 'pilotfish', LAST_MODIFIED_DATE = to_date(?, 'YYYY-MM-DD HH24:MI:SS') WHERE TRANSACTION_ID in (SELECT p.TRANSACTION_ID FROM POLICY p WHERE p.POLNUMBER = ?)</xsl:text>
              </ns1:SQL>
              <ns1:Params>
                <xsl:call-template name="currentDateTime" />
              </ns1:Params>
              <ns1:Params>
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber" />
              </ns1:Params>
            </xsl:otherwise>
          </xsl:choose>
        </ns1:Execute>
        <!-- Get the Transaction_ID -->
        <sql:Execute as="transrow" into="transaction">
          <xsl:choose>
            <xsl:when test="$sourceClient = 'METL'">
              <sql:SQL>SELECT MAX(p.TRANSACTION_ID) AS TRANSACTION_ID FROM POLICY p INNER JOIN REQ_INFO r ON p.POLICY_ID=r.POLICY_ID WHERE r.CARRIER_ORDER_NUM = ?</sql:SQL>
              <sql:Params>
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:CarrierOrderNum" />
              </sql:Params>
            </xsl:when>
            <xsl:when test="$sourceClient = 'PACT'">
              <sql:SQL>SELECT TRANSACTION_ID from CRLTRANSACTION WHERE TRANSACTION_ID in (SELECT MAX(TRANSACTION_ID) AS TRANSACTION_ID FROM POLICY WHERE TRACKING_ID = ?)</sql:SQL>
              <sql:Params>
                <xsl:choose>
                  <xsl:when test="string-length(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID) &gt; 0">
                    <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="'PF_NO_TRACKING_ID_IN_ACORD_FILE'" />
                  </xsl:otherwise>
                </xsl:choose>
              </sql:Params>
            </xsl:when>
            <xsl:when test="string-length(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber) = 0 and string-length(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID) &gt; 0">
              <sql:SQL>SELECT TRANSACTION_ID from CRLTRANSACTION WHERE TRANSACTION_ID in (SELECT MAX(TRANSACTION_ID) AS TRANSACTION_ID FROM POLICY WHERE TRACKING_ID = ?)</sql:SQL>
              <ns1:Params>
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID" />
              </ns1:Params>
            </xsl:when>
            <xsl:otherwise>
              <sql:SQL>SELECT TRANSACTION_ID from CRLTRANSACTION WHERE TRANSACTION_ID in (SELECT MAX(TRANSACTION_ID) AS TRANSACTION_ID FROM POLICY WHERE POLNUMBER = ?)</sql:SQL>
              <sql:Params>
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber" />
              </sql:Params>
            </xsl:otherwise>
          </xsl:choose>
        </sql:Execute>
        <sql:XMLOut var="transaction" />
        <!-- Add the cancellation 121 to the TRANSACTION_TEXT table -->
        <sql:Iterate as="transrow" over="transaction">
          <xsl:variable name="transactionID">ognl:#transrow.getFieldValue('TRANSACTION_ID')</xsl:variable>
          <sql:Insert>
            <TRANSACTION_TEXT>
              <TRANSACTION_ID>
                <xsl:value-of select="$transactionID" />
              </TRANSACTION_ID>
              <ORIGINAL_TXT literal="true">
                <xsl:value-of select="ta:getAttribute($attributes, 'com.pilotfish.crl.original.txt')" />
              </ORIGINAL_TXT>
              <ORIGINAL_TYPE>
                <xsl:choose>
                  <xsl:when test="ta:getAttribute($attributes, 'isNailba')='true'">
                    <xsl:value-of select="'NAILBA'" />
                  </xsl:when>
                  <xsl:when test="ta:getAttribute($attributes, 'acordDoctype')='103'">
                    <xsl:value-of select="'ACORD 103'" />
                  </xsl:when>
                  <xsl:when test="ta:getAttribute($attributes, 'acordDoctype')='121'">
                    <xsl:value-of select="'ACORD 121'" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="'OTHER'" />
                  </xsl:otherwise>
                </xsl:choose>
              </ORIGINAL_TYPE>
              <NORMALIZED_TXT>
                <!-- Save the normalized text, but only the the current TXLifeRequest element.-->
                <xsl:variable name="normalizedtxt">
                  <ns2:TXLife xmlns:ns2="http://ACORD.org/Standards/Life/2" Version="">
                    <xsl:apply-templates select="../@*" />
                    <xsl:apply-templates select="../ns2:UserAuthRequest" />
                    <xsl:apply-templates select="." />
                  </ns2:TXLife>
                </xsl:variable>
                <xsl:apply-templates mode="escape" select="exslt:node-set($normalizedtxt)" />
              </NORMALIZED_TXT>
            </TRANSACTION_TEXT>
          </sql:Insert>
        </sql:Iterate>
        <!-- handle the case where the cancellation doesn't match an existing order -->
        <sql:If test="#transaction.getRecords().length==0">
          <!-- log warning -->
          <sql:Assign exp="@com.pilotfish.eip.server.log.EIPLogManager@getModuleLogger().warn('Received cancellation for order that is not in the database.')" name="log" />
          <sql:Assign exp="#txData.getAttributes().setAttribute('orderNotFound','true')" name="log" />
          <sql:Insert>
            <CANCELLATION_NOT_FOUND>
              <PF_SOURCE_CLIENT>
                <xsl:value-of select="$sourceClient" />
              </PF_SOURCE_CLIENT>
              <CARRIER_CODE>
                <xsl:value-of select="substring(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:CarrierCode,1,50)" />
              </CARRIER_CODE>
              <POLNUMBER>
                <xsl:value-of select="substring(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber,1,100)" />
              </POLNUMBER>
              <TRACKING_ID>
                <xsl:value-of select="substring(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID,1,100)" />
              </TRACKING_ID>
              <REQ_INFO_UNIQUE_ID>
                <xsl:value-of select="substring(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:RequirementInfoUniqueID,1,100)" />
              </REQ_INFO_UNIQUE_ID>
              <CARRIER_ORDER_NUM>
                <xsl:value-of select="substring(ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:CarrierOrderNum,1,45)" />
              </CARRIER_ORDER_NUM>
              <TRANSACTION_DATE pattern="to_date(?, 'YYYY-MM-DD HH24:MI:SS')" type="VARCHAR">
                <xsl:choose>
                  <xsl:when test="string-length(ns1:TransExeDate) &gt; 0">
                    <xsl:call-template name="formatDateTime">
                      <xsl:with-param name="date" select="ns1:TransExeDate" />
                      <xsl:with-param name="time" select="ns1:TransExeTime" />
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="formatDateTime">
                      <xsl:with-param name="date" select="ns1:OLifE/ns1:SourceInfo/ns1:CreationDate" />
                      <xsl:with-param name="time" select="ns1:OLifE/ns1:SourceInfo/ns1:CreationTime" />
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </TRANSACTION_DATE>
              <RECEIVED_DATE pattern="to_date(?, 'YYYY-MM-DD HH24:MI:SS')" type="VARCHAR">
                <xsl:call-template name="currentDateTime" />
              </RECEIVED_DATE>
              <MESSAGE_BODY literal="true">
                <xsl:value-of select="ta:getAttribute($attributes, 'com.pilotfish.crl.original.txt')" />
              </MESSAGE_BODY>
            </CANCELLATION_NOT_FOUND>
          </sql:Insert>
        </sql:If>
        <!-- uncomment to commit each individual order in a batch -->
        <!--
				<sql:Execute>
					<sql:SQL>commit</sql:SQL>
				</sql:Execute>
				-->
      </xsl:for-each>
    </sql:SQLXML>
  </xsl:template>
  <!--
	<xsl:template name="formatDateTime">
		<xsl:param name="date" />
		<xsl:param name="time" />
		<xsl:choose>
			<xsl:when test="string-length($time) = 0">
				<xsl:call-template name="formatDate">
					<xsl:with-param name="date" select="$date" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>TO_DATE('</xsl:text>
				<xsl:value-of select="datetime:format-date($date,'MM/dd/YYYY')" />
				<xsl:value-of select="' '" />
				<!- - some times are of the format "16:04:53-05:00" - ->
				<xsl:choose>
					<xsl:when test="contains($time,'-')">
						<xsl:value-of select="substring-before($time,'-')" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$time" />
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text>', 'mm/dd/yyyy HH24:MI:SS')</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="formatDate">
		<xsl:param name="date" />
		<xsl:value-of select="datetime:format-date($date,'M/dd/YYYY')" />
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
	-->
  <xsl:template name="formatDateTime">
    <xsl:param name="date" />
    <xsl:param name="time" />
    <xsl:value-of select="java:com.pilotfish.eip.util.TimeZoneConverter.convertToLocalTZ(substring($date, 1, 10), substring($time, 1, 8), $timeZoneConversion)" />
  </xsl:template>
  <xsl:template name="formatDate">
    <xsl:param name="date" />
    <xsl:value-of select="datetime:format-date($date,'yyyy-MM-dd')" />
  </xsl:template>
  <xsl:template name="currentDateTime">
    <xsl:value-of select="datetime:year()" />
    <xsl:value-of select="'-'" />
    <xsl:value-of select="datetime:month-in-year()" />
    <xsl:value-of select="'-'" />
    <xsl:value-of select="datetime:day-in-month()" />
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
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*" mode="escape">
    <xsl:variable name="elementName" select="local-name()" />
    <!-- Begin opening tag -->
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()" />
    <!-- Namespaces -->
    <xsl:for-each select="namespace::*[$elementName='TXLife' and name() = 'ns2']">
      <xsl:value-of select="' xmlns'" />
      <xsl:if test="name() != ''">
        <xsl:text>:</xsl:text>
        <xsl:value-of select="name()" />
      </xsl:if>
      <xsl:text>='</xsl:text>
      <xsl:call-template name="escape-xml">
        <xsl:with-param name="text" select="." />
      </xsl:call-template>
      <xsl:text>'</xsl:text>
    </xsl:for-each>
    <!-- Attributes -->
    <xsl:for-each select="@*">
      <xsl:value-of select="' '" />
      <xsl:value-of select="name()" />
      <xsl:text>='</xsl:text>
      <xsl:call-template name="escape-xml">
        <xsl:with-param name="text" select="." />
      </xsl:call-template>
      <xsl:text>'</xsl:text>
    </xsl:for-each>
    <!-- End opening tag -->
    <xsl:text>&gt;</xsl:text>
    <!-- Content (child elements, text nodes, and PIs) -->
    <xsl:apply-templates mode="escape" select="node()" />
    <!-- Closing tag -->
    <xsl:text>&lt;/</xsl:text>
    <xsl:value-of select="name()" />
    <xsl:text>&gt;</xsl:text>
  </xsl:template>
  <xsl:template match="text()" mode="escape">
    <xsl:call-template name="escape-xml">
      <xsl:with-param name="text" select="." />
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="processing-instruction()" mode="escape">
    <xsl:text>&lt;?</xsl:text>
    <xsl:value-of select="name()" />
    <xsl:value-of select="' '" />
    <xsl:call-template name="escape-xml">
      <xsl:with-param name="text" select="." />
    </xsl:call-template>
    <xsl:text>?&gt;</xsl:text>
  </xsl:template>
  <xsl:template name="escape-xml">
    <xsl:param name="text" />
    <xsl:if test="$text != ''">
      <xsl:variable name="head" select="substring($text, 1, 1)" />
      <xsl:variable name="tail" select="substring($text, 2)" />
      <xsl:choose>
        <xsl:when test="$head = '&amp;'">&amp;amp;</xsl:when>
        <xsl:when test="$head = '&lt;'">&amp;lt;</xsl:when>
        <xsl:when test="$head = '&gt;'">&amp;gt;</xsl:when>
        <xsl:when test="$head = '&quot;'">&amp;quot;</xsl:when>
        <xsl:when test="$head = &quot;'&quot;">&amp;apos;</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$head" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="escape-xml">
        <xsl:with-param name="text" select="$tail" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>

