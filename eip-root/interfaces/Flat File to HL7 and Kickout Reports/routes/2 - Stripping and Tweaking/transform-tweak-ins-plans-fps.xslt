<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--REPLACE MEDICAID INSURANCE PLANS FOR FPS ONLY-->
  <xsl:template match="Insurance1/admInsName">
    <xsl:variable name="PatientType" select="../../PatientDemographics/admpatienttype" />
    <admInsName>
      <xsl:choose>
        <xsl:when test=". = ('AE104','AETNA BET','CHAR PEND','FLAT RATE','HEALTH','HEALTH MCD','INTNL UNINS','KAISER MCD','MA200','MAG CCC P','MCD FAM','MCD HMOOUT')">
          <xsl:value-of select="concat(., $PatientType)" />
        </xsl:when>
        <xsl:when test=". = ('MCD OUT','MCD PEND','MCD VA','MCD WVA','MCRMCDDUAL','MDVA','MDVADOC','MDVASC','MOL CCC P','OPTIMA MCD','PSY AET BE','PSY AETBEP','PSY ECO')">
          <xsl:value-of select="concat(., $PatientType)" />
        </xsl:when>
        <xsl:when test=". = ('PSY HEALTH','PSY MAG','PSY MAGCCP','PSY MAGMCD','PSY MOLCCP','PSY OPTCCP','PSY PREMCD','PSY TDO','PSY UHC','PSY UHCMD','PSY VA PRE')">
          <xsl:value-of select="concat(., $PatientType)" />
        </xsl:when>
        <xsl:when test=". = ('REH AETBEP','REH MAGCCP','REH MCD','UHCMCDSNP','UHCMDVA','UNIN INT','UNINSURED','UNITED CCP','VA HEALTH','VA PRE MCD','VI016','VI026')">
          <xsl:value-of select="concat(., $PatientType)" />
        </xsl:when>
        <xsl:when test=". = ('ZCHA 0-200','ZCHA 201-','ZMAG RECLS','ZMCD ED VA','ZMCD KS','ZMCD KY','ZMCD MO','ZMCD NC','ZMCD NH','ZMCD PE','ZMCD RECLA','ZMCD WVA')">
          <xsl:value-of select="concat(., $PatientType)" />
        </xsl:when>
        <xsl:when test=". = ('ZMCDOOSFOL','ZRCPS MCD','ZREHABMCD','ZZCHAR 100','ZZCHAR 200')">
          <xsl:value-of select="concat(., $PatientType)" />
        </xsl:when>
        <xsl:when test=". = ('PSY OPTI','PSY OPTMD')">
          <xsl:value-of select="concat(., $PatientType)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="." />
        </xsl:otherwise>
      </xsl:choose>
    </admInsName>
  </xsl:template>
  <xsl:template match="Insurance2/admInsName">
    <admInsName>
      <xsl:choose>
        <xsl:when test=". = ('UNINSUREDE','UNINSUREDS','UNINSUREDV','UNINSUREDO','UNINSUREDI','UNINSUREDC')">
          <xsl:value-of select="concat('S', .)" />
        </xsl:when>
        <xsl:when test=". = ('NISP','EY001','MDVAOUT','W.MISC1','UNINS.MN','UNINS.CL','UNINS.BM','UNINS.WU')">
          <xsl:value-of select="concat('S', .)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="." />
        </xsl:otherwise>
      </xsl:choose>
    </admInsName>
  </xsl:template>
  <xsl:template match="Insurance2/admInsName">
    <admInsName>
      <xsl:choose>
        <xsl:when test=". = ('UNINSUREDE','UNINSUREDS','UNINSUREDV','UNINSUREDO','UNINSUREDI','UNINSUREDC')">
          <xsl:value-of select="concat('S', .)" />
        </xsl:when>
        <xsl:when test=". = ('NISP','EY001','MDVAOUT','W.MISC1','UNINS.MN','UNINS.CL','UNINS.BM','UNINS.WU')">
          <xsl:value-of select="concat('S', .)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="." />
        </xsl:otherwise>
      </xsl:choose>
    </admInsName>
  </xsl:template>
</xsl:stylesheet>

