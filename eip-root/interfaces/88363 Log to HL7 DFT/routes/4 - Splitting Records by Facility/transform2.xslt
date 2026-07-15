<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" expand-text="yes" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--The goal is to take in an XML that has all the split info and split for the number of client codes in a list-->
  <!--The client codes will be coming from a database and will be dynamic so we have to loop over the number of client codes-->
  <!--We want to create a split by grouping all the Client nodes by client code so we can later do forking on the number of splits we generate here-->
  <xsl:output indent="yes" method="xml" />
  <xsl:param name="SplitInfoXML" />
  <xsl:template match="/XCSData">
    <xsl:variable name="CurrentNode" select="." />
    <xsl:variable name="SplitInfo" select="parse-xml($SplitInfoXML)" />
    <Import>
      <!--SPLIT CODES THAT ARE != COMPARATORS AKA DEFAULT SPLITS-->
      <xsl:for-each select="$CurrentNode/Client">
        <xsl:variable name="CurrentClientNode" select="." />
        <xsl:for-each select="$SplitInfo//Split[ClientCodes/@comparator = '!=']">
          <xsl:variable name="CurrentSplit" select="." />
          <xsl:for-each select="$CurrentSplit/ClientCodes/ClientCode">
            <xsl:variable name="CurrentSplitClientCode" select="." />
            <xsl:if test="not(starts-with($CurrentClientNode/@client_code, $CurrentSplitClientCode))">
              <xsl:copy select="$CurrentClientNode">
                <xsl:apply-templates select="@*|node()" />
                <IsDuplicate>yes</IsDuplicate>
                <SplitCode>
                  <xsl:value-of select="$CurrentSplit/@split_code" />
                </SplitCode>
                <FacilityCode>
                  <xsl:value-of select="$CurrentSplit/@facility_code" />
                </FacilityCode>
                <AccountNumAlpha>
                  <xsl:value-of select="$CurrentSplit/@account_num_alpha" />
                </AccountNumAlpha>
              </xsl:copy>
            </xsl:if>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
      <!--SPLIT CODES THAT ARE = COMPARATORS-->
      <xsl:for-each select="$SplitInfo//Split">
        <xsl:variable name="CurrentSplit" select="." />
        <xsl:variable name="SplitCodes" select="./ClientCodes/ClientCode" />
        <xsl:variable name="CurrentComparator" select="./ClientCodes/@comparator" />
        <xsl:for-each select="$CurrentNode/Client">
          <xsl:variable name="CurrentClientNode" select="." />
          <xsl:variable name="CurrentClientCodeAttr" select="./@client_code" />
          <xsl:for-each select="$SplitCodes">
            <xsl:variable name="CurrentSplitCode" select="." />
            <xsl:choose>
              <xsl:when test="starts-with($CurrentClientCodeAttr,.)">
                <xsl:if test="$CurrentComparator = '='">
                  <xsl:copy select="$CurrentClientNode">
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
                  </xsl:copy>
                </xsl:if>
              </xsl:when>
            </xsl:choose>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </Import>
  </xsl:template>
</xsl:stylesheet>

