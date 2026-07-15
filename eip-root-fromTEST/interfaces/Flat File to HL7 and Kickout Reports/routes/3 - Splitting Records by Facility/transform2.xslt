<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <!--The goal is to take in an XML that has all the split info and split for the number of client codes in a list-->
  <!--The client codes will be coming from a database and will be dynamic so we have to loop over the number of client codes-->
  <!--We want to create a split by grouping all the Client nodes by client code so we can later do forking on the number of splits we generate here-->
  <xsl:output indent="yes" method="xml" />
  <xsl:param name="SplitInfoXML" />
  <xsl:template match="/XCSData/Import">
    <xsl:variable name="CurrentNode" select="." />
    <xsl:variable name="SplitInfo" select="parse-xml($SplitInfoXML)" />
    <Import>
      <xsl:for-each select="$SplitInfo//Split">
        <xsl:variable name="CurrentSplit" select="." />
        <xsl:variable name="SplitCodes" select="./ClientCodes/ClientCode" />
        <xsl:variable name="CurrentComparator" select="./ClientCodes/@comparator" />
        <xsl:for-each select="$CurrentNode/Client">
          <xsl:copy-of select="." />
          <xsl:variable name="CurrentClientNode" select="." />
          <xsl:variable name="CurrentClientCodeAttr" select="./@client_code" />
          <xsl:for-each select="$SplitCodes">
            <xsl:variable name="CurrentSplitCode" select="." />
            <xsl:if test="contains($CurrentClientCodeAttr,.)">
              <xsl:copy select="$CurrentClientNode">
                <xsl:if test="$CurrentComparator = '='">
                  <xsl:apply-templates select="@*|node()" />
                  <SplitCode>
                    <xsl:value-of select="$CurrentSplit/@split_code" />
                  </SplitCode>
                  <FacilityCode>
                    <xsl:value-of select="$CurrentSplit/@facility_code" />
                  </FacilityCode>
                  <AccountNumAlpha>
                    <xsl:value-of select="$CurrentSplit/@account_num_alpha" />
                  </AccountNumAlpha>
                </xsl:if>
              </xsl:copy>
            </xsl:if>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </Import>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

