<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:str="http://exslt.org/strings" exclude-result-prefixes="str" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="Summary">
    <!--REMOVE-->
  </xsl:template>
  <xsl:template match="XCSRecord[string-length(PatientName) = 0]">
    <!--REMOVE-->
  </xsl:template>
  <xsl:template match="NewProcedure">
    <NewProcedureCPT>
      <xsl:value-of select="." />
    </NewProcedureCPT>
  </xsl:template>
  <xsl:template match="NewProcDocDate">
    <NewProcDocDateDOS>
      <xsl:value-of select="." />
    </NewProcDocDateDOS>
  </xsl:template>
  <xsl:template match="Units">
    <Units>
      <xsl:value-of select="substring(.,1,1)" />
    </Units>
    <OrigSOUTDoc>
      <xsl:value-of select="normalize-space(substring(.,2,string-length(.)))" />
    </OrigSOUTDoc>
  </xsl:template>
  <xsl:template match="AddtlSignersTypeAndDate">
    <xsl:variable name="SplitSigners" select="tokenize(.,';')" />
    <AddtlSigners>
      <xsl:for-each select="$SplitSigners">
        <Signer>
          <xsl:variable name="SignerNameAndType" select="normalize-space(substring-before(.,','))" />
          <Name>
            <xsl:value-of select="substring-before($SignerNameAndType,'(')" />
          </Name>
          <Type>
            <xsl:value-of select="substring-before(substring-after($SignerNameAndType,'('),')')" />
          </Type>
          <Date>
            <xsl:value-of select="normalize-space(substring-after(.,','))" />
          </Date>
        </Signer>
      </xsl:for-each>
    </AddtlSigners>
  </xsl:template>
</xsl:stylesheet>

