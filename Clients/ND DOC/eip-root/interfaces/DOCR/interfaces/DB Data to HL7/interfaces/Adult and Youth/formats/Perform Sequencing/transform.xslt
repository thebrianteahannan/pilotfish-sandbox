<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <Events>
      <Set>
        <SequenceNo>1</SequenceNo>
        <xsl:for-each select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '1']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '2']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '3']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '4']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '5']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '6']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '7']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '8']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
      </Set>
      <Set>
        <SequenceNo>2</SequenceNo>
        <xsl:for-each select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '1']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '2']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '3']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '4']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '5']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '6']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '7']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '8']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
      </Set>
      <Set>
        <SequenceNo>3</SequenceNo>
        <!--A22 BED SWAP - SORT IN DESCENDING ORDER-->
        <xsl:for-each select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '1']">
          <xsl:sort order="descending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '2']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '3']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '4']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '5']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '6']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '7']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '8']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
      </Set>
      <Set>
        <SequenceNo>4</SequenceNo>
        <xsl:for-each select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '1']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '2']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '3']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '4']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '5']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '6']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '7']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '8']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
      </Set>
      <Set>
        <SequenceNo>5</SequenceNo>
        <xsl:for-each select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '1']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '2']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '3']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '4']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '5']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '6']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '7']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
        <xsl:for-each select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '8']">
          <xsl:sort order="ascending" select="ELITECOMMITDTTM" />
          <xsl:copy-of select="." />
        </xsl:for-each>
      </Set>
    </Events>
  </xsl:template>
</xsl:stylesheet>

