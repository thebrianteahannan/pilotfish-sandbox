<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:java="java" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="ta td java datetime dtFormatter" version="1.0">
  <xsl:output method="html" omit-xml-declaration="yes" />
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attr" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="styleTable" select="'border-collapse: collapse; border-spacing: 0; empty-cells: show; border: 1px solid #cbcbcb;'" />
  <xsl:variable name="styleTD" select="'border-left: 1px solid #cbcbcb; border-width: 0 0 0 1px; font-size: inherit; margin: 0; overflow: visible; padding: 0.5em 1em;'" />
  <xsl:variable name="styleTDodd" select="'background-color: #f2f2f2; border-left: 1px solid #cbcbcb; border-width: 0 0 0 1px; font-size: inherit; margin: 0; overflow: visible; padding: 0.5em 1em;'" />
  <xsl:variable name="styleTHEAD" select="'background-color: #e0e0e0; color: #000; text-align: left; vertical-align: bottom;'" />
  <xsl:variable name="styleCaption" select="'color: #fff; font: bold arial, sans-serif; padding: 1em 0; text-align: center; background-color: #000; vertical-align: bottom;'" />
  <xsl:variable name="styleTfoot" select="'background-color: #e0e0e0; font-size: 0.9em;'" />
  <xsl:variable name="styleEmpty" select="'text-align: left; font-style: italic; padding: 0.5em 5em;'" />
  <xsl:template match="/EIPData/RESULTS | /RESULTS ">
    <html>
      <head>
        <title>
          <xsl:value-of select="ta:getAttribute($attr, 'crl.environment')" />
          <xsl:value-of select="' PilotFish Problem Report'" />
        </title>
        <style>tbody tr:hover td { 
 background:#99BCBF !important;
 color:#000000;
}</style>
      </head>
      <body>
        <h1 style="font-size: 1.5em; margin: 0.67em 0; color: #404040; text-align: center;">
          <xsl:value-of select="ta:getAttribute($attr, 'crl.environment')" />
          <xsl:value-of select="' PilotFish Order Problem Report'" />
        </h1>
        <xsl:choose>
          <xsl:when test="count(//RECORD) &gt; 0">
            <h2 style="font-size: 1.3em; padding-left: 20; text-align: center; color: red;">
              <xsl:value-of select="'ISSUES FOUND: '" />
              <xsl:value-of select="count(//RECORD)" />
            </h2>
          </xsl:when>
          <xsl:otherwise>
            <h2 style="font-size: 1.3em; padding-left: 20; text-align: center; color: #008000;">
              <xsl:text>NO ISSUES FOUND</xsl:text>
            </h2>
          </xsl:otherwise>
        </xsl:choose>
        <table id="noordernum" style="{$styleTable}">
          <caption style="{$styleCaption}">No Flownet Order Number (received &gt; 1 hr ago)</caption>
          <thead style="{$styleTHEAD}">
            <tr>
              <th style="{$styleTD}">Client</th>
              <th style="{$styleTD}">Received</th>
              <th style="{$styleTD}">Transaction_ID</th>
              <th style="{$styleTD}">Policy Number</th>
              <th style="{$styleTD}">Req Acct Num</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="TRANSACTION/TRANSACTIONNOORDERNUM/RECORD">
              <xsl:variable name="currentStyle">
                <xsl:choose>
                  <xsl:when test="(position() mod 2) != 1">
                    <xsl:value-of select="$styleTDodd" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$styleTD" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <tr>
                <td style="{$currentStyle}">
                  <xsl:value-of select="PFSOURCECLIENT" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="dtFormatter:format(CREATEDDATE,'yyyy-MM-dd HH:mm:ss.S','yyyy-MM-dd HH:mm:ss')" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="TRANSACTIONID" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="POLNUMBER" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="REQACCTNUM" />
                </td>
              </tr>
            </xsl:for-each>
            <xsl:if test="count(TRANSACTION/TRANSACTIONNOORDERNUM/RECORD) = 0">
              <tr>
                <td colspan="5" style="{$styleEmpty}">--Empty--</td>
              </tr>
            </xsl:if>
          </tbody>
          <tfoot>
            <tr>
              <td colspan="5" style="{$styleTfoot}">The above orders are likely in the FlowNet error queue.  Check FlowNet for details.  If the order is found to be invalid and will not be corrected, the FlowNet_Order_Number field should be set to "INVALID" in the PilotFish database.</td>
            </tr>
          </tfoot>
        </table>
        <p />
        <hr />
        <p />
        <table id="noactivities" style="{$styleTable}">
          <caption style="{$styleCaption}">No Activities (received &gt; 24 hrs ago)</caption>
          <thead style="{$styleTHEAD}">
            <tr>
              <th style="{$styleTD}">Client</th>
              <th style="{$styleTD}">Received</th>
              <th style="{$styleTD}">Order Number</th>
              <th style="{$styleTD}">Transaction_ID</th>
              <th style="{$styleTD}">Policy Number</th>
              <th style="{$styleTD}">Req Acct Num</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="TRANSACTION/TRANSACTIONNOACTIVITIES/RECORD">
              <xsl:variable name="currentStyle">
                <xsl:choose>
                  <xsl:when test="(position() mod 2) != 1">
                    <xsl:value-of select="$styleTDodd" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$styleTD" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <tr>
                <td style="{$currentStyle}">
                  <xsl:value-of select="PFSOURCECLIENT" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="dtFormatter:format(CREATEDDATE,'yyyy-MM-dd HH:mm:ss.S','yyyy-MM-dd HH:mm:ss')" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="FLOWNETORDERNUM" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="TRANSACTIONID" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="POLNUMBER" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="REQACCTNUM" />
                </td>
              </tr>
            </xsl:for-each>
            <xsl:if test="count(TRANSACTION/TRANSACTIONNOACTIVITIES/RECORD) = 0">
              <tr>
                <td colspan="6" style="{$styleEmpty}">--Empty--</td>
              </tr>
            </xsl:if>
          </tbody>
          <tfoot>
            <tr>
              <td colspan="6" style="{$styleTfoot}">FlowNet should create initial activities for new orders.  The above orders have an order line without any activities indicating a potential issue.</td>
            </tr>
          </tfoot>
        </table>
        <p />
        <hr />
        <p />
        <table id="attachments" style="{$styleTable}">
          <caption style="{$styleCaption}">Awaiting Attachments (received &gt; 24 hrs ago)</caption>
          <thead style="{$styleTHEAD}">
            <tr>
              <th style="{$styleTD}">Client</th>
              <th style="{$styleTD}">Completed</th>
              <th style="{$styleTD}">Order Number</th>
              <th style="{$styleTD}">Attachments</th>
              <th style="{$styleTD}">Policy Number</th>
              <th style="{$styleTD}">Expect Filenames</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="TRANSACTION/TRANSACTIONAWAITINGATTACHMENT/RECORD">
              <xsl:variable name="currentStyle">
                <xsl:choose>
                  <xsl:when test="(position() mod 2) != 1">
                    <xsl:value-of select="$styleTDodd" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$styleTD" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <tr>
                <td style="{$currentStyle}">
                  <xsl:value-of select="PFSOURCECLIENT" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:choose>
                    <xsl:when test="string-length(ORDERCOMPLETEDATE) &gt; 0">
                      <xsl:value-of select="dtFormatter:format(ORDERCOMPLETEDATE,'yyyy-MM-dd HH:mm:ss.S','yyyy-MM-dd HH:mm:ss')" />
                    </xsl:when>
                    <xsl:otherwise>NULL</xsl:otherwise>
                  </xsl:choose>
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="FLOWNETORDERNUM" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:choose>
                    <xsl:when test="AVAILABLE &gt; 0">
                      <xsl:value-of select="AVAILABLE" />
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                  <xsl:text>/</xsl:text>
                  <xsl:choose>
                    <xsl:when test="EXPECTED &gt; AVAILABLE">
                      <xsl:value-of select="EXPECTED" />
                    </xsl:when>
                    <xsl:when test="EXPECTED &gt; 0">
                      <xsl:value-of select="EXPECTED" />
                      <xsl:text>?</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>?</xsl:otherwise>
                  </xsl:choose>
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="POLNUMBER" />
                </td>
                <td style="{$currentStyle} font-size: 0.9em;">
                  <xsl:call-template name="replace-string">
                    <xsl:with-param name="text" select="EXPECTEDFILENAMES" />
                    <xsl:with-param name="replace" select="','" />
                    <xsl:with-param name="with" select="'&lt;br /&gt;'" />
                  </xsl:call-template>
                </td>
              </tr>
            </xsl:for-each>
            <xsl:if test="count(TRANSACTION/TRANSACTIONAWAITINGATTACHMENT/RECORD) = 0">
              <tr>
                <td colspan="6" style="{$styleEmpty}">--Empty--</td>
              </tr>
            </xsl:if>
          </tbody>
          <tfoot>
            <tr>
              <td colspan="6" style="{$styleTfoot}">The above orders are flagged as awaiting manual attachments.  The "Attachments" column contains two numbers.  The first number indicates the number of attachments currently available for the order.  The second number indicates the number of expected attachments.  The missing attachments should be uploaded to the SFTP server.</td>
            </tr>
          </tfoot>
        </table>
        <p />
        <hr />
        <p />
        <table id="procerr" style="{$styleTable}">
          <caption style="{$styleCaption}">Error Processing/Delivering Order</caption>
          <thead style="{$styleTHEAD}">
            <tr>
              <th style="{$styleTD}">Client</th>
              <th style="{$styleTD}">Order Number</th>
              <th style="{$styleTD}">Policy Number</th>
              <th style="{$styleTD}">Last Attempt</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="TRANSACTION/TRANSACTIONERRORPROCESSING/RECORD">
              <xsl:variable name="currentStyle">
                <xsl:choose>
                  <xsl:when test="(position() mod 2) != 1">
                    <xsl:value-of select="$styleTDodd" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$styleTD" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <tr>
                <td style="{$currentStyle}">
                  <xsl:value-of select="PFSOURCECLIENT" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="FLOWNETORDERNUM" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="POLNUMBER" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="dtFormatter:format(PFPROCESSINGKEY,'yyyy-MM-dd-HH-mm-ss','yyyy-MM-dd HH:mm:ss')" />
                </td>
              </tr>
            </xsl:for-each>
            <xsl:if test="count(TRANSACTION/TRANSACTIONERRORPROCESSING/RECORD) = 0">
              <tr>
                <td colspan="4" style="{$styleEmpty}">--Empty--</td>
              </tr>
            </xsl:if>
          </tbody>
          <tfoot>
            <tr>
              <td colspan="4" style="{$styleTfoot}">For the above orders, a problem was encountered in the outbound interface.  The problem could be with retrieving the attachments from IAS, with creating the 1122, or with delivering it to the client and getting a successful response.  The outbound interface will automatically reattempt delivery every 24 hours from the last attempt time.  PilotFish Support will monitor and resolve these issues.</td>
            </tr>
          </tfoot>
        </table>
        <p />
        <hr />
        <p />
        <table id="undelivered" style="{$styleTable}">
          <caption style="{$styleCaption}">Undelivered Statuses (&gt; 24 hours old)</caption>
          <thead style="{$styleTHEAD}">
            <tr>
              <th style="{$styleTD}">Client</th>
              <th style="{$styleTD}">Order Number</th>
              <th style="{$styleTD}">Policy Number</th>
              <th style="{$styleTD}">Req Status</th>
              <th style="{$styleTD}">Activity Date</th>
              <th style="{$styleTD}">Provider Event Codes</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="TRANSACTION/TRANSACTIONUNDELIVEREDSTATUS/RECORD">
              <xsl:variable name="currentStyle">
                <xsl:choose>
                  <xsl:when test="(position() mod 2) != 1">
                    <xsl:value-of select="$styleTDodd" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$styleTD" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <tr>
                <td style="{$currentStyle}">
                  <xsl:value-of select="PFSOURCECLIENT" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="FLOWNETORDERNUM" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="POLNUMBER" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="REQSTATUS" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="dtFormatter:format(ACTIVITYDATE,'yyyy-MM-dd HH:mm:ss.S','yyyy-MM-dd HH:mm:ss')" />
                </td>
                <td style="{$currentStyle}">
                  <xsl:value-of select="PROVIDEREVENTCODES" />
                </td>
              </tr>
            </xsl:for-each>
            <xsl:if test="count(TRANSACTION/TRANSACTIONUNDELIVEREDSTATUS/RECORD) = 0">
              <tr>
                <td colspan="6" style="{$styleEmpty}">--Empty--</td>
              </tr>
            </xsl:if>
          </tbody>
          <tfoot>
            <tr>
              <td colspan="6" style="{$styleTfoot}">Statuses for the above orders have not been delivered to the client.  PilotFish Support will monitor and resolve these issues.</td>
            </tr>
          </tfoot>
        </table>
        <p />
        <hr />
        <p>
          <xsl:value-of select="'Report run on: '" />
          <xsl:variable name="localHost" select="java:net.InetAddress.getLocalHost()" />
          <xsl:value-of select="java:getHostName($localHost)" />
          <br />
          <xsl:value-of select="'Report run date: '" />
          <xsl:value-of select="datetime:format-date(datetime:date-time(),'yyyy-MM-dd HH:mm:ss')" />
        </p>
      </body>
    </html>
  </xsl:template>
  <xsl:template name="replace-string">
    <xsl:param name="text" />
    <xsl:param name="replace" />
    <xsl:param name="with" />
    <xsl:choose>
      <xsl:when test="contains($text,$replace)">
        <xsl:value-of select="substring-before($text,$replace)" />
        <xsl:value-of disable-output-escaping="yes" select="$with" />
        <xsl:call-template name="replace-string">
          <xsl:with-param name="text" select="substring-after($text,$replace)" />
          <xsl:with-param name="replace" select="$replace" />
          <xsl:with-param name="with" select="$with" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

