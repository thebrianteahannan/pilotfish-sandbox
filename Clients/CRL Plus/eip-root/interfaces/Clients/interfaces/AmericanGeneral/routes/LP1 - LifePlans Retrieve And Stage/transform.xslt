<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exslt="http://exslt.org/common" exclude-result-prefixes="exslt" version="1.0">
  <!--When scanning the file list for matching pairs, I am assuming that the filename is not case sensitive-->
  <!--Weirdly though, even if the system storing the file isn't case sensitive, the retrieved filenames come across-->
  <!--with cases intact.  To simplify the testing, it is helpful to pull out the filenames and convert them to all-->
  <!--lowercase before looking for matching pairs.  Obviously, if the FTP server in question is changed to be case-->
  <!--sensitive, this will be a problem.  Also, I'm certain there's an easier way to do this.-->
  <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
  <xsl:variable name="fileList">
    <FileList>
      <xsl:for-each select="/JSCHFiles/File">
        <FileName>
          <xsl:copy-of select="translate(FileName, $uppercase, $lowercase)" />
        </FileName>
      </xsl:for-each>
    </FileList>
  </xsl:variable>
  <xsl:template match="/JSCHFiles">
    <Files>
      <xsl:for-each select="exslt:node-set($fileList)/FileList/FileName[contains(., '.idx')]">
        <xsl:variable name="fname" select="substring-before(.,'.idx')" />
        <xsl:if test="exslt:node-set($fileList)/FileList/FileName = concat($fname, '.tif')">
          <FileName>
            <xsl:value-of select="." />
          </FileName>
          <FileName>
            <xsl:value-of select="concat($fname, '.tif')" />
          </FileName>
        </xsl:if>
      </xsl:for-each>
    </Files>
  </xsl:template>
</xsl:stylesheet>

