<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rs="http://www.pilotfishtechnology.com/eipr/RouteSpec" version="3.1">
  <xsl:param name="Partition" />
  <xsl:param name="Client" />
  <xsl:param name="FacilityNameShouldBe" />
  <!--IDENTITY TEMPLATE BECAUSE WE WANT TO KEEP THE ENTIRE REST OF THE ROUTE XML BUT WE JUST WANT TO ADD A NEW LISTENER-->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//rs:Route/rs:Source[@name = 'Pickup ZIP Files']">
    <!--COPY THE PICKUP ZIP FILES SOURCE BECAUSE WE STILL WANT THAT-->
    <xsl:copy-of select="." />
    <!--NOW ADD THE NEW FACILITY LISTENER-->
    <Source icon="DocFlatFile2_Orange_1.png">
      <xsl:attribute name="name">
        <xsl:value-of select="concat('Pickup Flat Files - ',$Partition,' - ',$Client)" />
      </xsl:attribute>
      <FormatProfile name="Relay (System Format)" />
      <SourceMetadata />
      <Listener class="com.pilotfish.eip.modules.file.DirectoryListener" enabled="true">
        <xsl:attribute name="name">
          <xsl:value-of select="concat('1 - Incoming Raw File - Dir Listener - ', $Partition, ' - ', $Client)" />
        </xsl:attribute>
        <ModuleConfig>
          <IS_TRIGGERABLE_LISTENER>false</IS_TRIGGERABLE_LISTENER>
          <CLIAllowed>false</CLIAllowed>
          <RESTART_ON_ERROR_TAG>false</RESTART_ON_ERROR_TAG>
          <StopWhenPollingFailure>true</StopWhenPollingFailure>
          <FIFOQueueName />
          <FIFOQueueDelay>500</FIFOQueueDelay>
          <TransactionLoggingAllowed>false</TransactionLoggingAllowed>
          <TransactionLoggingStoreData>false</TransactionLoggingStoreData>
          <TransactionLoggingStoreDataBase64>false</TransactionLoggingStoreDataBase64>
          <TransactionLoggingStoreAttributes>false</TransactionLoggingStoreAttributes>
          <TransactionLoggingLogAllAttributes>false</TransactionLoggingLogAllAttributes>
          <TransactionLoggingAllowedLoggedAttributes>[eip_pair:Transaction Resubmit Attribute:eip_name:com.pilotfish.Dashboard.ResubmissionOriginalTxID:eip_value]</TransactionLoggingAllowedLoggedAttributes>
          <CheckInactivity>false</CheckInactivity>
          <InactivityTransactionCount>1</InactivityTransactionCount>
          <InactivityPolling>500</InactivityPolling>
          <MonitoringTime>16:21-16:21</MonitoringTime>
          <InactivityExcludedDays />
          <InactivityIncludeErrors>false</InactivityIncludeErrors>
          <ThrottlingMode>None</ThrottlingMode>
          <ThrottlingMechanism>Blocking</ThrottlingMechanism>
          <ThrottlingConcurrentMessages>1</ThrottlingConcurrentMessages>
          <ThrottlingTimedInterval>1</ThrottlingTimedInterval>
          <ThrottlingSynchronousTimeout>60</ThrottlingSynchronousTimeout>
          <PollingInterval>5</PollingInterval>
          <PollingDirectory>$$FLAT_FILE_INPUT_DIRECTORY</PollingDirectory>
          <FileNameRestriction>
            <xsl:value-of select="concat(lower-case($Partition),lower-case($Client),'.*')" />
          </FileNameRestriction>
          <FileExtensionRestriction>txt</FileExtensionRestriction>
          <UseFullFilePath>Disabled</UseFullFilePath>
          <FullPathToFile />
          <PostProcessOperation>Move</PostProcessOperation>
          <TargetDirectory>$$FLAT_FILE_ARCHIVE_DIRECTORY</TargetDirectory>
          <CompatModeMoved>false</CompatModeMoved>
          <Tokenizers />
          <SerializedTransactionsTag>250</SerializedTransactionsTag>
          <SubFolderIterationTag>false</SubFolderIterationTag>
          <FullFolderPathRestrictionsTag />
          <HiddenFilesTag>false</HiddenFilesTag>
          <SchedulerStartTag />
          <SchedulerEndTag />
          <ExcludeDaysTag />
          <ExcludeDatesTag />
          <TimeZone>System Default</TimeZone>
          <MinSecondsSinceFileModified>10</MinSecondsSinceFileModified>
          <MinDaysSinceFileModified>-1</MinDaysSinceFileModified>
          <MaxDaysSinceFileModified>-1</MaxDaysSinceFileModified>
          <CombineFiles>true</CombineFiles>
          <HeaderLines>0</HeaderLines>
          <SynchResponse>false</SynchResponse>
          <Timeout>60</Timeout>
          <FileSortingMethod>System Default</FileSortingMethod>
          <FileSortingDirection>Ascending</FileSortingDirection>
        </ModuleConfig>
      </Listener>
      <Processors>
        <Processor class="com.pilotfish.eip.modules.internal.TransactionAttributePopulationProcessor">
          <xsl:attribute name="name">
            <xsl:value-of select="concat('Set Facility Name - ',$Client)" />
          </xsl:attribute>
          <ModuleConfig>
            <ExecuteProcessor>true</ExecuteProcessor>
            <AttributePairs>
              <xsl:value-of select="concat('[eip_pair:FacilityNameShouldBe:eip_name:',$FacilityNameShouldBe,':eip_value]')" />
            </AttributePairs>
            <AttributeScope>Transaction</AttributeScope>
            <GlobalAttributes>BUCKET</GlobalAttributes>
          </ModuleConfig>
        </Processor>
      </Processors>
    </Source>
  </xsl:template>
</xsl:stylesheet>

