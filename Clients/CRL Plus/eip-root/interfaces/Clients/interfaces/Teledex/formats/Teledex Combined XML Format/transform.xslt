<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="ns1 ta td datetime" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="sourceClient" select="ta:getAttribute($attributes, 'sourceClient')" />
  <xsl:template match="/XCSData">
    <XCSData>
      <Columns count="173">
        <Column index="0" length="4" type="character">BRANCH</Column>
        <Column index="1" length="6" type="numeric">ORDERNO</Column>
        <Column index="2" length="8" type="character">ORDER_DATE</Column>
        <Column index="3" length="10" type="character">ORDER_TYPE</Column>
        <Column index="4" length="10" type="character">RUSH</Column>
        <Column index="5" length="1" type="character">ORIGIN</Column>
        <Column index="6" length="25" type="character">AGENT</Column>
        <Column index="7" length="10" type="character">AGENT_CD</Column>
        <Column index="8" length="25" type="character">AGENCY</Column>
        <Column index="9" length="15" type="character">AGENCY_CDE</Column>
        <Column index="10" length="10" type="character">AGENCY_PH</Column>
        <Column index="11" length="10" type="character">AGENCY_FAX</Column>
        <Column index="12" length="30" type="character">P_CLIENT</Column>
        <Column index="13" length="9" type="character">P_ACCOUNT</Column>
        <Column index="14" length="30" type="character">A_CLIENT</Column>
        <Column index="15" length="9" type="character">A_ACCOUNT</Column>
        <Column index="16" length="30" type="character">I_CLIENT</Column>
        <Column index="17" length="9" type="character">I_ACCOUNT</Column>
        <Column index="18" length="2" type="numeric">PRO_INS_NO</Column>
        <Column index="19" length="12" type="character">INSUR_CODE</Column>
        <Column index="20" length="9" type="numeric">POL_AMT</Column>
        <Column index="21" length="2" type="character">USAGE_CDE</Column>
        <Column index="22" length="8" type="character">APL_SI_DT</Column>
        <Column index="23" length="1" type="character">POL_TYPE</Column>
        <Column index="24" length="5" type="character">SUB_PTYPE</Column>
        <Column index="25" length="60" type="character">POLICY</Column>
        <Column index="26" length="20" type="character">APP_ORD_ID</Column>
        <Column index="27" length="5" type="character">APP_PREFIX</Column>
        <Column index="28" length="15" type="character">APP_FNAME</Column>
        <Column index="29" length="15" type="character">APP_MNAME</Column>
        <Column index="30" length="25" type="character">APP_LNAME</Column>
        <Column index="31" length="5" type="character">APP_SUFFIX</Column>
        <Column index="32" length="15" type="character">APP_FALIAS</Column>
        <Column index="33" length="15" type="character">APP_MALIAS</Column>
        <Column index="34" length="25" type="character">APP_LALIAS</Column>
        <Column index="35" length="1" type="character">APP_GENDER</Column>
        <Column index="36" length="1" type="character">APP_SMOKER</Column>
        <Column index="37" length="1" type="character">APP_MAR_ST</Column>
        <Column index="38" length="9" type="character">APP_SOC</Column>
        <Column index="39" length="8" type="character">APP_DOB</Column>
        <Column index="40" length="3" type="numeric">APP_AGE</Column>
        <Column index="41" length="6" type="character">PLAC_BIRTH</Column>
        <Column index="42" length="6" type="character">CTRY_CITZN</Column>
        <Column index="43" length="1" type="character">EXAM_PLAC</Column>
        <Column index="44" length="4" type="character">CONT_HME_B</Column>
        <Column index="45" length="4" type="character">CONT_HME_E</Column>
        <Column index="46" length="30" type="character">ADR1_NAME</Column>
        <Column index="47" length="40" type="character">ADR1_ADR1</Column>
        <Column index="48" length="40" type="character">ADR1_ADR2</Column>
        <Column index="49" length="20" type="character">ADR1_CITY</Column>
        <Column index="50" length="6" type="character">ADR1_ST</Column>
        <Column index="51" length="5" type="character">ADR1_ZIP1</Column>
        <Column index="52" length="4" type="character">ADR1_ZIP2</Column>
        <Column index="53" length="6" type="character">ADR1_CTRY</Column>
        <Column index="54" length="10" type="character">ADR1_PH</Column>
        <Column index="55" length="4" type="character">ADR1_EXT</Column>
        <Column index="56" length="8" type="character">RES_BDATE</Column>
        <Column index="57" length="8" type="character">RES_EDATE</Column>
        <Column index="58" length="1" type="character">ADR2_PLAC</Column>
        <Column index="59" length="30" type="character">ADR2_NAME</Column>
        <Column index="60" length="30" type="character">ADR2_ADR1</Column>
        <Column index="61" length="30" type="character">ADR2_ADR2</Column>
        <Column index="62" length="20" type="character">ADR2_CITY</Column>
        <Column index="63" length="6" type="character">ADR2_ST</Column>
        <Column index="64" length="5" type="character">ADR2_ZIP1</Column>
        <Column index="65" length="4" type="character">ADR2_ZIP2</Column>
        <Column index="66" length="6" type="character">ADR2_CTRY</Column>
        <Column index="67" length="10" type="character">ADR2_PH</Column>
        <Column index="68" length="4" type="character">ADR2_EXT</Column>
        <Column index="69" length="80" type="character">REMARKS1</Column>
        <Column index="70" length="80" type="character">REMARKS2</Column>
        <Column index="71" length="80" type="character">REMARKS3</Column>
        <Column index="72" length="80" type="character">REMARKS4</Column>
        <Column index="73" length="4" type="character">PRC_LST</Column>
        <Column index="74" length="2" type="character">BILL_ST</Column>
        <Column index="75" length="3" type="character">BILL_CD1</Column>
        <Column index="76" length="3" type="character">BILL_CD2</Column>
        <Column index="77" length="3" type="character">BILL_CD3</Column>
        <Column index="78" length="3" type="character">BILL_CD4</Column>
        <Column index="79" length="3" type="character">BILL_CD5</Column>
        <Column index="80" length="3" type="character">BILL_CD6</Column>
        <Column index="81" length="3" type="character">BILL_CD7</Column>
        <Column index="82" length="3" type="character">BILL_CD8</Column>
        <Column index="83" length="3" type="character">BILL_CD9</Column>
        <Column index="84" length="10" type="character">LAB</Column>
        <Column index="85" length="40" type="character">EXAMINER</Column>
        <Column index="86" length="11" type="character">EXM_SOC</Column>
        <Column index="87" length="6" type="character">EXAMNR_CDE</Column>
        <Column index="88" length="8" type="character">APPT_DATE</Column>
        <Column index="89" length="4" type="numeric">APPT_TIME</Column>
        <Column index="90" length="1" type="character">APPT_PM</Column>
        <Column index="91" length="8" type="character">TO_EXAMNER</Column>
        <Column index="92" length="8" type="character">SCHD_DATE</Column>
        <Column index="93" length="1" type="character">STATUS</Column>
        <Column index="94" length="4" type="character">TRANTONO</Column>
        <Column index="95" length="8" type="character">SPARE_DATE</Column>
        <Column index="96" length="20" type="character">SPARE_FLD</Column>
        <Column index="97" length="8" type="character">FOLLOW_DTE</Column>
        <Column index="98" length="20" type="character">FOLLOW_FLD</Column>
        <Column index="99" length="3" type="character">AIM</Column>
        <Column index="100" length="15" type="character">PHY_FNAME</Column>
        <Column index="101" length="15" type="character">PHY_MNAME</Column>
        <Column index="102" length="40" type="character">PHY_LNAME</Column>
        <Column index="103" length="40" type="character">PHY_ADR1</Column>
        <Column index="104" length="40" type="character">PHY_ADR2</Column>
        <Column index="105" length="20" type="character">PHY_CITY</Column>
        <Column index="106" length="6" type="character">PHY_ST</Column>
        <Column index="107" length="5" type="character">PHY_ZIP1</Column>
        <Column index="108" length="4" type="character">PHY_ZIP2</Column>
        <Column index="109" length="6" type="character">PHY_CTRY</Column>
        <Column index="110" length="10" type="character">PHY_PHONE</Column>
        <Column index="111" length="10" type="character">PHY_FAX</Column>
        <Column index="112" length="8" type="character">APS_DATE</Column>
        <Column index="113" length="5" type="character">BEN_PREFIX</Column>
        <Column index="114" length="15" type="character">BEN_FNAME</Column>
        <Column index="115" length="15" type="character">BEN_MNAME</Column>
        <Column index="116" length="45" type="character">BEN_LNAME</Column>
        <Column index="117" length="5" type="character">BEN_SUFFIX</Column>
        <Column index="118" length="40" type="character">BEN_COMP</Column>
        <Column index="119" length="3" type="numeric">BEN_AGE</Column>
        <Column index="120" length="1" type="character">BEN_TYPE</Column>
        <Column index="121" length="20" type="character">BEN_RELAT</Column>
        <Column index="122" length="40" type="character">EMPLOYER</Column>
        <Column index="123" length="40" type="character">EMPL_ADR1</Column>
        <Column index="124" length="40" type="character">EMPL_ADR2</Column>
        <Column index="125" length="20" type="character">EMPL_CITY</Column>
        <Column index="126" length="6" type="character">EMPL_ST</Column>
        <Column index="127" length="5" type="character">EMPL_ZIP1</Column>
        <Column index="128" length="4" type="character">EMPL_ZIP2</Column>
        <Column index="129" length="6" type="character">EMPL_CTRY</Column>
        <Column index="130" length="10" type="character">EMPL_PH</Column>
        <Column index="131" length="4" type="character">EMPL_EXT</Column>
        <Column index="132" length="30" type="character">OCCUPATION</Column>
        <Column index="133" length="4" type="character">CONT_EMP_B</Column>
        <Column index="134" length="4" type="character">CONT_EMP_H</Column>
        <Column index="135" length="8" type="character">EMPL_BDTE</Column>
        <Column index="136" length="8" type="character">EMPL_EDTE</Column>
        <Column index="137" length="8" type="character">INF_DATE</Column>
        <Column index="138" length="25" type="character">DRV_LIC</Column>
        <Column index="139" length="6" type="character">ISSUE_ST</Column>
        <Column index="140" length="8" type="character">MVR_DATE</Column>
        <Column index="141" length="4" type="character">ORIG_BR</Column>
        <Column index="142" length="6" type="character">ORIG_ORDNO</Column>
        <Column index="143" length="4" type="character">REMOTE_ID</Column>
        <Column index="144" length="6" type="character">REMOTE_NO</Column>
        <Column index="145" length="4" type="character">PEP_FIELD</Column>
        <Column index="146" length="8" type="character">DONE_DATE</Column>
        <Column index="147" length="1" type="character">APP_HTFT</Column>
        <Column index="148" length="2" type="character">APP_HTIN</Column>
        <Column index="149" length="3" type="character">APP_WT</Column>
        <Column index="150" length="80" type="character">ATTACHMENT</Column>
        <Column index="151" length="4" type="character">EFORM_ID</Column>
        <Column index="152" length="20" type="character">FILE_NAME</Column>
        <Column index="153" length="1" type="character">CONT_PREF</Column>
        <Column index="154" length="20" type="character">CONT_NEEDS</Column>
        <Column index="155" length="20" type="character">CONT_INST</Column>
        <Column index="156" length="5" type="character">CONT_EXT</Column>
        <Column index="157" length="8" type="character">CTRL_POL</Column>
        <Column index="158" length="2" type="character">DELIV_ST</Column>
        <Column index="159" length="4" type="character">PRU_TRANS</Column>
        <Column index="160" length="3" type="character">PBX_IND</Column>
        <Column index="161" length="3" type="character">PLC_IND</Column>
        <Column index="162" length="1" type="character">ALT_POL</Column>
        <Column index="163" length="1" type="character">RELAT_APP</Column>
        <Column index="164" length="40" type="character">JUV_NAME</Column>
        <Column index="165" length="1" type="character">JUV_FLAG</Column>
        <Column index="166" length="1" type="character">AGT_W_CLI</Column>
        <Column index="167" length="1" type="character">EA_IND</Column>
        <Column index="168" length="10" type="character">ALT_PH</Column>
        <Column index="169" length="50" type="character">APP_EMAIL</Column>
        <Column index="170" length="14" type="character">APP_MOBILE</Column>
        <Column index="171" length="10" type="character">AGT_PH</Column>
        <Column index="172" length="50" type="character">AGT_EMAIL</Column>
      </Columns>
      <xsl:for-each select="//XCSRecord">
        <XCSRecord row="{position()}">
          <xsl:copy-of select="*" />
        </XCSRecord>
      </xsl:for-each>
    </XCSData>
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

