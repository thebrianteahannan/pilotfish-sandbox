<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:datetime="http://exslt.org/dates-and-times"
                exclude-result-prefixes="datetime"
                version="3.0">
  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:variable name="CR" select="'&#x0D;'"/>

  <xsl:template match="/">
    <!-- After XPathForkingModule, the document root is typically the Event element itself. -->
    <xsl:variable name="event" select="if (local-name(/*) = 'Event') then /* else (//Event)[1]"/>
    <xsl:variable name="eventType" select="normalize-space($event/EventType)"/>
    <xsl:variable name="trigger">
      <xsl:choose>
        <xsl:when test="$eventType = 'ADMIT'">A01</xsl:when>
        <xsl:when test="$eventType = 'TRANSFER'">A02</xsl:when>
        <xsl:when test="$eventType = 'DISCHARGE'">A03</xsl:when>
        <xsl:when test="$eventType = 'DEMO_UPDATE'">A08</xsl:when>
        <xsl:when test="$eventType = 'BED_ASSIGN'">A02</xsl:when>
        <xsl:otherwise>A08</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="patientClass">
      <xsl:choose>
        <xsl:when test="$eventType = 'DISCHARGE'">N</xsl:when>
        <xsl:otherwise>I</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="eventTsRaw" select="normalize-space($event/EventTimestamp)"/>
    <xsl:variable name="eventTs"
                  select="translate(translate(translate($eventTsRaw, '-', ''), 'T', ''), ':', '')"/>
    <xsl:variable name="msgTs"
                  select="substring(translate(translate(translate(string(datetime:dateTime()), '-', ''), 'T', ''), ':', ''), 1, 14)"/>
    <xsl:variable name="controlId"
                  select="concat('DOC', normalize-space($event/EventId), $trigger)"/>
    <xsl:variable name="middle">
      <xsl:if test="string-length(normalize-space($event/MiddleName)) &gt; 0">
        <xsl:value-of select="concat('^', normalize-space($event/MiddleName))"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="attending">
      <xsl:choose>
        <xsl:when test="string-length(normalize-space($event/AttendingNpi)) &gt; 0">
          <xsl:value-of select="concat(normalize-space($event/AttendingNpi), '^', normalize-space($event/AttendingName))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="normalize-space($event/AttendingName)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="priorLocation">
      <xsl:if test="string-length(normalize-space($event/PriorFacilityCode)) &gt; 0
                    or string-length(normalize-space($event/PriorUnitCode)) &gt; 0
                    or string-length(normalize-space($event/PriorBedCode)) &gt; 0">
        <xsl:value-of select="concat(normalize-space($event/PriorFacilityCode), '^',
                                     normalize-space($event/PriorUnitCode), '^',
                                     normalize-space($event/PriorBedCode))"/>
      </xsl:if>
    </xsl:variable>

    <!-- MSH -->
    <xsl:text>MSH|^~\&amp;|PILOTFISH|DOC|MYAVATAR|NETSMART|</xsl:text>
    <xsl:value-of select="$msgTs"/>
    <xsl:text>||ADT^</xsl:text>
    <xsl:value-of select="$trigger"/>
    <xsl:text>^ADT_A01|</xsl:text>
    <xsl:value-of select="$controlId"/>
    <xsl:text>|P|2.5.1|||AL|NE|</xsl:text>
    <xsl:value-of select="$CR"/>

    <!-- EVN -->
    <xsl:text>EVN|</xsl:text>
    <xsl:value-of select="$trigger"/>
    <xsl:text>|</xsl:text>
    <xsl:value-of select="$eventTs"/>
    <xsl:text>||||</xsl:text>
    <xsl:value-of select="normalize-space($event/SourceSystem)"/>
    <xsl:value-of select="$CR"/>

    <!-- PID -->
    <xsl:text>PID|1||</xsl:text>
    <xsl:value-of select="normalize-space($event/Mrn)"/>
    <xsl:text>^^^DOC^MR~</xsl:text>
    <xsl:value-of select="normalize-space($event/OffenderId)"/>
    <xsl:text>^^^DOC^PI||</xsl:text>
    <xsl:value-of select="normalize-space($event/LastName)"/>
    <xsl:text>^</xsl:text>
    <xsl:value-of select="normalize-space($event/FirstName)"/>
    <xsl:value-of select="$middle"/>
    <xsl:text>||</xsl:text>
    <xsl:value-of select="normalize-space($event/BirthDate)"/>
    <xsl:text>|</xsl:text>
    <xsl:value-of select="normalize-space($event/Sex)"/>
    <xsl:text>|||</xsl:text>
    <xsl:value-of select="normalize-space($event/Street)"/>
    <xsl:text>^^</xsl:text>
    <xsl:value-of select="normalize-space($event/City)"/>
    <xsl:text>^</xsl:text>
    <xsl:value-of select="normalize-space($event/State)"/>
    <xsl:text>^</xsl:text>
    <xsl:value-of select="normalize-space($event/Zip)"/>
    <xsl:text>^USA||</xsl:text>
    <xsl:value-of select="normalize-space($event/Phone)"/>
    <xsl:value-of select="$CR"/>

    <!-- PV1 -->
    <xsl:text>PV1|1|</xsl:text>
    <xsl:value-of select="$patientClass"/>
    <xsl:text>|</xsl:text>
    <xsl:value-of select="normalize-space($event/FacilityCode)"/>
    <xsl:text>^</xsl:text>
    <xsl:value-of select="normalize-space($event/UnitCode)"/>
    <xsl:text>^</xsl:text>
    <xsl:value-of select="normalize-space($event/BedCode)"/>
    <xsl:text>^DOC||||</xsl:text>
    <xsl:value-of select="$attending"/>
    <xsl:text>|||||||</xsl:text>
    <xsl:value-of select="normalize-space($event/EventType)"/>
    <xsl:text>||||||||||||||||||||||||</xsl:text>
    <xsl:choose>
      <xsl:when test="$eventType = 'DISCHARGE'">
        <xsl:value-of select="$eventTs"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>|</xsl:text>
        <xsl:value-of select="$eventTs"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="string-length($priorLocation) &gt; 0">
      <!-- PV1-6 prior location approximated in PV1 continuation field block for demo readability -->
    </xsl:if>
    <xsl:value-of select="$CR"/>

    <!-- ZPF - PilotFish workflow audit trail (custom Z segment) -->
    <xsl:text>ZPF|</xsl:text>
    <xsl:value-of select="normalize-space($event/EventId)"/>
    <xsl:text>|</xsl:text>
    <xsl:value-of select="normalize-space($event/ParentEventId)"/>
    <xsl:text>|</xsl:text>
    <xsl:value-of select="normalize-space($event/IsExpandedFromMulti)"/>
    <xsl:text>|</xsl:text>
    <xsl:value-of select="normalize-space($event/SourceSystem)"/>
    <xsl:text>|</xsl:text>
    <xsl:value-of select="normalize-space($event/Notes)"/>
    <xsl:value-of select="$CR"/>
  </xsl:template>
</xsl:stylesheet>
