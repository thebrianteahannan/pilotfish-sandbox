<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <!--
    SQLXML emits uppercase elements under EIPData/RECORDS/EVENT.
    Expand MULTI operational events into discrete healthcare transactions.
  -->
  <xsl:template match="/">
    <Events>
      <xsl:for-each select="//EVENT | //Event">
        <xsl:variable name="src" select="."/>
        <xsl:variable name="eventType" select="normalize-space(($src/EVENTTYPE | $src/EventType)[1])"/>
        <xsl:variable name="childTypes" select="normalize-space(($src/CHILDEVENTTYPES | $src/ChildEventTypes)[1])"/>
        <xsl:variable name="parentId" select="normalize-space(($src/EVENTID | $src/EventId)[1])"/>

        <xsl:choose>
          <xsl:when test="$eventType = 'MULTI' and string-length($childTypes) &gt; 0">
            <xsl:for-each select="tokenize($childTypes, ',')">
              <xsl:variable name="childType" select="normalize-space(.)"/>
              <xsl:if test="string-length($childType) &gt; 0">
                <xsl:call-template name="emit-event">
                  <xsl:with-param name="src" select="$src"/>
                  <xsl:with-param name="eventId" select="concat($parentId, '-', position())"/>
                  <xsl:with-param name="parentEventId" select="$parentId"/>
                  <xsl:with-param name="sequence" select="position()"/>
                  <xsl:with-param name="eventType" select="$childType"/>
                  <xsl:with-param name="expanded" select="'true'"/>
                  <xsl:with-param name="notesSuffix" select="' [expanded from MULTI]'"/>
                </xsl:call-template>
              </xsl:if>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="emit-event">
              <xsl:with-param name="src" select="$src"/>
              <xsl:with-param name="eventId" select="$parentId"/>
              <xsl:with-param name="parentEventId" select="$parentId"/>
              <xsl:with-param name="sequence" select="1"/>
              <xsl:with-param name="eventType" select="$eventType"/>
              <xsl:with-param name="expanded" select="'false'"/>
              <xsl:with-param name="notesSuffix" select="''"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </Events>
  </xsl:template>

  <xsl:template name="emit-event">
    <xsl:param name="src"/>
    <xsl:param name="eventId"/>
    <xsl:param name="parentEventId"/>
    <xsl:param name="sequence"/>
    <xsl:param name="eventType"/>
    <xsl:param name="expanded"/>
    <xsl:param name="notesSuffix"/>

    <Event>
      <EventId><xsl:value-of select="$eventId"/></EventId>
      <ParentEventId><xsl:value-of select="$parentEventId"/></ParentEventId>
      <Sequence><xsl:value-of select="$sequence"/></Sequence>
      <SourceSystem><xsl:value-of select="normalize-space(($src/SOURCESYSTEM | $src/SourceSystem)[1])"/></SourceSystem>
      <EventType><xsl:value-of select="$eventType"/></EventType>
      <ChildEventTypes/>
      <IsExpandedFromMulti><xsl:value-of select="$expanded"/></IsExpandedFromMulti>
      <OffenderId><xsl:value-of select="normalize-space(($src/OFFENDERID | $src/OffenderId)[1])"/></OffenderId>
      <Mrn><xsl:value-of select="normalize-space(($src/MRN | $src/Mrn)[1])"/></Mrn>
      <LastName><xsl:value-of select="normalize-space(($src/LASTNAME | $src/LastName)[1])"/></LastName>
      <FirstName><xsl:value-of select="normalize-space(($src/FIRSTNAME | $src/FirstName)[1])"/></FirstName>
      <MiddleName><xsl:value-of select="normalize-space(($src/MIDDLENAME | $src/MiddleName)[1])"/></MiddleName>
      <BirthDate><xsl:value-of select="normalize-space(($src/BIRTHDATE | $src/BirthDate)[1])"/></BirthDate>
      <Sex><xsl:value-of select="normalize-space(($src/SEX | $src/Sex)[1])"/></Sex>
      <Street><xsl:value-of select="normalize-space(($src/STREET | $src/Street)[1])"/></Street>
      <City><xsl:value-of select="normalize-space(($src/CITY | $src/City)[1])"/></City>
      <State><xsl:value-of select="normalize-space(($src/STATE | $src/State)[1])"/></State>
      <Zip><xsl:value-of select="normalize-space(($src/ZIP | $src/Zip)[1])"/></Zip>
      <Phone><xsl:value-of select="normalize-space(($src/PHONE | $src/Phone)[1])"/></Phone>
      <FacilityCode><xsl:value-of select="normalize-space(($src/FACILITYCODE | $src/FacilityCode)[1])"/></FacilityCode>
      <UnitCode><xsl:value-of select="normalize-space(($src/UNITCODE | $src/UnitCode)[1])"/></UnitCode>
      <BedCode><xsl:value-of select="normalize-space(($src/BEDCODE | $src/BedCode)[1])"/></BedCode>
      <PriorFacilityCode><xsl:value-of select="normalize-space(($src/PRIORFACILITYCODE | $src/PriorFacilityCode)[1])"/></PriorFacilityCode>
      <PriorUnitCode><xsl:value-of select="normalize-space(($src/PRIORUNITCODE | $src/PriorUnitCode)[1])"/></PriorUnitCode>
      <PriorBedCode><xsl:value-of select="normalize-space(($src/PRIORBEDCODE | $src/PriorBedCode)[1])"/></PriorBedCode>
      <AttendingNpi><xsl:value-of select="normalize-space(($src/ATTENDINGNPI | $src/AttendingNpi)[1])"/></AttendingNpi>
      <AttendingName><xsl:value-of select="normalize-space(($src/ATTENDINGNAME | $src/AttendingName)[1])"/></AttendingName>
      <EventTimestamp><xsl:value-of select="normalize-space(($src/EVENTTIMESTAMP | $src/EventTimestamp)[1])"/></EventTimestamp>
      <Status><xsl:value-of select="normalize-space(($src/STATUS | $src/Status)[1])"/></Status>
      <Notes>
        <xsl:value-of select="concat(normalize-space(($src/NOTES | $src/Notes)[1]), $notesSuffix)"/>
      </Notes>
    </Event>
  </xsl:template>
</xsl:stylesheet>
