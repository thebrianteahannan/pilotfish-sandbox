<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:pf="pf" xmlns:saxon="http://saxon.sf.net/" xmlns:xip="com.pilotfish.xquery.library" version="3.1">
  <xsl:param name="edi-text" />
  <xsl:output encoding="utf-8" indent="yes" method="html" />
  <xsl:template match="/">
    <xsl:variable name="data" select="//*[local-name() = 'error']" />
    <html>
      <head>
        <title>EDI Validation  Report</title>
        <style>body {background-color: #F8F8FF;
		
				font-family:courier, serif;
				font-size: small;
				font-weight: bold;
				}
				.green {background-color: #87ED90;}
				.red {background-color: red;}
				.yellow {background-color: #fdfd96;}
				
				hr.solid { border-top 3px solid #bbb;}
				h1 { text-align:center;}
				
				span {	margin-left:200;color:red;font-weight:bolder;}
				.section {
				padding-left: 2em;
				padding-right: 2em;
				}
				.container {
				max-width: 1000px;
				margin-left:0;
				margin-right:auto;
				}
				.code{
				margin-right:auto;
				font-family:courier, serif;
				font-size: small;
				font-weight: bold;
				}
				pre { 	margin-left:100;	padding-left: 0em;
				padding-right: 0em;}
				p {padding-left: 0px;
				padding-right:0px;}</style>
        <hr class="solid" />
        <h1 class="center">EDI Validation Report</h1>
        <hr class="solid" />
        <section class="section">
          <div class="container">
            <xsl:for-each select="tokenize($edi-text, '~')">
              <xsl:variable name="edi-line-number" select="position()" />
              <xsl:variable name="error" select="$data//seg[@ln=$edi-line-number]/.." />
              <xsl:if test="not(exists($error))">
                <p>
                  <xsl:value-of select="$edi-line-number" />
                  <xsl:text>:</xsl:text>
                  <!--Only 500 characters for BIN Segment-->
                  <xsl:value-of select="if (starts-with(.,'BIN') or (substring(.,2,3) = 'BIN')) then substring(., 1, 500) else ." />
                </p>
              </xsl:if>
              <xsl:if test="exists($error)">
                <p class="yellow">
                  <xsl:value-of select="$edi-line-number" />
                  <xsl:text>:</xsl:text>
                  <xsl:value-of select="if (starts-with(.,'BIN') or (substring(.,2,3) = 'BIN')) then substring(., 1, 500) else ." />
                </p>
                <span>
                  <pre>
                    <xsl:for-each select="$data//seg[@ln=$edi-line-number]/..">
                      <code class="code">
                        <xsl:value-of select="'Level : '" />
                        <xsl:value-of select="./ValidationLevel" />
                        <br />
                        <xsl:value-of select="'RuleId : '" />
                        <xsl:value-of select="./RuleId" />
                        <br />
                        <xsl:value-of select="'Message : '" />
                        <xsl:value-of select="pf:getValidationValue(., 'Message')" />
                        <br />
                        <xsl:value-of select="'SegmentID : '" />
                        <xsl:value-of select="./SegmentID" />
                        <br />
                        <xsl:value-of select="'Type : '" />
                        <xsl:value-of select="./ViolationType" />
                        <br />
                        <xsl:value-of select="'Segment Position : '" />
                        <xsl:value-of select="pf:getValidationValue(., 'SegPosition')" />
                        <br />
                        <xsl:value-of select="'Loop : '" />
                        <xsl:value-of select="pf:getValidationValue(., 'LoopID')" />
                        <br />
                        <xsl:value-of select="'Element Position : '" />
                        <xsl:value-of select="pf:getValidationValue(., 'ElePosition')" />
                        <br />
                        <xsl:value-of select="'Element ID : '" />
                        <xsl:value-of select="pf:getValidationValue(., 'ElementID')" />
                        <br />
                        <xsl:value-of select="'Element Value : '" />
                        <xsl:value-of select="pf:getValidationValue(., 'EleCopy')" />
                        <br />
                        <xsl:value-of select="'Transaction Number: '" />
                        <xsl:value-of select="./Transaction" />
                        <br />
                        <xsl:value-of select="'Group Number : '" />
                        <xsl:value-of select="./Group" />
                        <br />
                        <xsl:value-of select="'Error Code : '" />
                        <xsl:value-of select="pf:getValidationValue(., 'ErrorCode')" />
                        <br />
                      </code>
                      <br />
                    </xsl:for-each>
                    <br />
                  </pre>
                </span>
              </xsl:if>
            </xsl:for-each>
          </div>
        </section>
      </head>
      <body />
    </html>
  </xsl:template>
  <xsl:function name="pf:getValidationValue">
    <xsl:param name="root" />
    <xsl:param name="nodeName" />
    <xsl:choose>
      <xsl:when test="$root/*[name()=$nodeName]">
        <xsl:value-of select="$root/*[name()=$nodeName]" />
      </xsl:when>
      <xsl:when test="$root/ContextInfo/Element[1]/child::*[name()=$nodeName]">
        <xsl:value-of select="$root/ContextInfo/Element[1]/child::*[name()=$nodeName]" />
      </xsl:when>
      <xsl:when test="$root/ContextInfo/Segment[1]/child::*[name()=$nodeName]">
        <xsl:value-of select="$root/ContextInfo/Segment[1]/child::*[name()=$nodeName]" />
      </xsl:when>
      <xsl:when test="$root/../item/parameterMap/*[name()=$nodeName]">
        <xsl:value-of select="$root/../item/parameterMap/*[name()=$nodeName]" />
      </xsl:when>
    </xsl:choose>
  </xsl:function>
</xsl:stylesheet>

