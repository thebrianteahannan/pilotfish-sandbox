<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <!--
    Expand MULTI operational events into discrete healthcare transactions.
    Example: MULTI with ChildEventTypes=ADMIT,BED_ASSIGN,DEMO_UPDATE
    becomes three single Event nodes that are later forked one-by-one.
  -->
  <xsl:template match="/">
    <Events>
      <xsl:for-each select="//Event">
        <xsl:choose>
          <xsl:when test="normalize-space(EventType) = 'MULTI'
                          and string-length(normalize-space(ChildEventTypes)) &gt; 0">
            <xsl:variable name="parent" select="."/>
            <xsl:variable name="parentId" select="normalize-space(EventId)"/>
            <xsl:for-each select="tokenize(normalize-space(ChildEventTypes), ',')">
              <xsl:variable name="childType" select="normalize-space(.)"/>
              <xsl:if test="string-length($childType) &gt; 0">
                <Event>
                  <EventId>
                    <xsl:value-of select="concat($parentId, '-', position())"/>
                  </EventId>
                  <ParentEventId>
                    <xsl:value-of select="$parentId"/>
                  </ParentEventId>
                  <Sequence>
                    <xsl:value-of select="position()"/>
                  </Sequence>
                  <SourceSystem>
                    <xsl:value-of select="$parent/SourceSystem"/>
                  </SourceSystem>
                  <EventType>
                    <xsl:value-of select="$childType"/>
                  </EventType>
                  <ChildEventTypes/>
                  <IsExpandedFromMulti>true</IsExpandedFromMulti>
                  <OffenderId>
                    <xsl:value-of select="$parent/OffenderId"/>
                  </OffenderId>
                  <Mrn>
                    <xsl:value-of select="$parent/Mrn"/>
                  </Mrn>
                  <LastName>
                    <xsl:value-of select="$parent/LastName"/>
                  </LastName>
                  <FirstName>
                    <xsl:value-of select="$parent/FirstName"/>
                  </FirstName>
                  <MiddleName>
                    <xsl:value-of select="$parent/MiddleName"/>
                  </MiddleName>
                  <BirthDate>
                    <xsl:value-of select="$parent/BirthDate"/>
                  </BirthDate>
                  <Sex>
                    <xsl:value-of select="$parent/Sex"/>
                  </Sex>
                  <Street>
                    <xsl:value-of select="$parent/Street"/>
                  </Street>
                  <City>
                    <xsl:value-of select="$parent/City"/>
                  </City>
                  <State>
                    <xsl:value-of select="$parent/State"/>
                  </State>
                  <Zip>
                    <xsl:value-of select="$parent/Zip"/>
                  </Zip>
                  <Phone>
                    <xsl:value-of select="$parent/Phone"/>
                  </Phone>
                  <FacilityCode>
                    <xsl:value-of select="$parent/FacilityCode"/>
                  </FacilityCode>
                  <UnitCode>
                    <xsl:value-of select="$parent/UnitCode"/>
                  </UnitCode>
                  <BedCode>
                    <xsl:value-of select="$parent/BedCode"/>
                  </BedCode>
                  <PriorFacilityCode>
                    <xsl:value-of select="$parent/PriorFacilityCode"/>
                  </PriorFacilityCode>
                  <PriorUnitCode>
                    <xsl:value-of select="$parent/PriorUnitCode"/>
                  </PriorUnitCode>
                  <PriorBedCode>
                    <xsl:value-of select="$parent/PriorBedCode"/>
                  </PriorBedCode>
                  <AttendingNpi>
                    <xsl:value-of select="$parent/AttendingNpi"/>
                  </AttendingNpi>
                  <AttendingName>
                    <xsl:value-of select="$parent/AttendingName"/>
                  </AttendingName>
                  <EventTimestamp>
                    <xsl:value-of select="$parent/EventTimestamp"/>
                  </EventTimestamp>
                  <Status>
                    <xsl:value-of select="$parent/Status"/>
                  </Status>
                  <Notes>
                    <xsl:value-of select="concat($parent/Notes, ' [expanded from MULTI]')"/>
                  </Notes>
                </Event>
              </xsl:if>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <Event>
              <EventId>
                <xsl:value-of select="EventId"/>
              </EventId>
              <ParentEventId>
                <xsl:value-of select="EventId"/>
              </ParentEventId>
              <Sequence>1</Sequence>
              <SourceSystem>
                <xsl:value-of select="SourceSystem"/>
              </SourceSystem>
              <EventType>
                <xsl:value-of select="EventType"/>
              </EventType>
              <ChildEventTypes>
                <xsl:value-of select="ChildEventTypes"/>
              </ChildEventTypes>
              <IsExpandedFromMulti>false</IsExpandedFromMulti>
              <OffenderId>
                <xsl:value-of select="OffenderId"/>
              </OffenderId>
              <Mrn>
                <xsl:value-of select="Mrn"/>
              </Mrn>
              <LastName>
                <xsl:value-of select="LastName"/>
              </LastName>
              <FirstName>
                <xsl:value-of select="FirstName"/>
              </FirstName>
              <MiddleName>
                <xsl:value-of select="MiddleName"/>
              </MiddleName>
              <BirthDate>
                <xsl:value-of select="BirthDate"/>
              </BirthDate>
              <Sex>
                <xsl:value-of select="Sex"/>
              </Sex>
              <Street>
                <xsl:value-of select="Street"/>
              </Street>
              <City>
                <xsl:value-of select="City"/>
              </City>
              <State>
                <xsl:value-of select="State"/>
              </State>
              <Zip>
                <xsl:value-of select="Zip"/>
              </Zip>
              <Phone>
                <xsl:value-of select="Phone"/>
              </Phone>
              <FacilityCode>
                <xsl:value-of select="FacilityCode"/>
              </FacilityCode>
              <UnitCode>
                <xsl:value-of select="UnitCode"/>
              </UnitCode>
              <BedCode>
                <xsl:value-of select="BedCode"/>
              </BedCode>
              <PriorFacilityCode>
                <xsl:value-of select="PriorFacilityCode"/>
              </PriorFacilityCode>
              <PriorUnitCode>
                <xsl:value-of select="PriorUnitCode"/>
              </PriorUnitCode>
              <PriorBedCode>
                <xsl:value-of select="PriorBedCode"/>
              </PriorBedCode>
              <AttendingNpi>
                <xsl:value-of select="AttendingNpi"/>
              </AttendingNpi>
              <AttendingName>
                <xsl:value-of select="AttendingName"/>
              </AttendingName>
              <EventTimestamp>
                <xsl:value-of select="EventTimestamp"/>
              </EventTimestamp>
              <Status>
                <xsl:value-of select="Status"/>
              </Status>
              <Notes>
                <xsl:value-of select="Notes"/>
              </Notes>
            </Event>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </Events>
  </xsl:template>
</xsl:stylesheet>
