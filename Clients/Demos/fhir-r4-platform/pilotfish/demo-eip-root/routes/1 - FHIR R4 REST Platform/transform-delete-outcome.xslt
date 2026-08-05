<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:template match="/">
    <xsl:text>{"resourceType":"OperationOutcome","issue":[{"severity":"information","code":"informational","diagnostics":"Resource soft-deleted."}]}</xsl:text>
  </xsl:template>
</xsl:stylesheet>
