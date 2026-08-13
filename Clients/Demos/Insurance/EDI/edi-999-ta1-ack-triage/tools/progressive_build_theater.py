#!/usr/bin/env python3
"""Progressive theater build for edi-999-ta1-ack-triage — publish after each module stage."""

from __future__ import annotations

import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
DEMO = Path(__file__).resolve().parents[1]
IFACE = DEMO / "eip-root" / "interfaces" / "EDI 999 TA1 Ack Triage"
ROUTES = IFACE / "routes"
DEMO_ROUTES = DEMO / "pilotfish" / "demo-eip-root" / "routes"
PAUSE = float(sys.argv[1]) if len(sys.argv) > 1 else 4.0


def run(cmd: list[str]) -> None:
    print("+", " ".join(cmd), flush=True)
    subprocess.check_call(cmd, cwd=str(ROOT))


def publish(route: str, message: str) -> None:
    run(
        [
            "python3",
            "tools/publish_route_progress.py",
            "--root",
            str(DEMO),
            "--route",
            route,
            "--message",
            message,
        ]
    )
    time.sleep(PAUSE)


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


LISTENER = """    <Listener class="com.pilotfish.eip.modules.file.DirectoryListener" enabled="true" name="Poll Inbound 999 TA1 Files">
      <ModuleConfig>
        <IS_TRIGGERABLE_LISTENER>false</IS_TRIGGERABLE_LISTENER>
        <CLIAllowed>false</CLIAllowed>
        <RESTART_ON_ERROR_TAG>false</RESTART_ON_ERROR_TAG>
        <StopWhenPollingFailure>true</StopWhenPollingFailure>
        <FIFOQueueName />
        <FIFOQueueDelay>500</FIFOQueueDelay>
        <TransactionLoggingAllowed>false</TransactionLoggingAllowed>
        <TransactionLoggingStoreAttributes>false</TransactionLoggingStoreAttributes>
        <TransactionLoggingStoreData>false</TransactionLoggingStoreData>
        <TransactionLoggingStoreDataBase64>false</TransactionLoggingStoreDataBase64>
        <PollingInterval>5</PollingInterval>
        <PollingDirectory>$$EDI_INBOUND_DIRECTORY</PollingDirectory>
        <FileNameRestriction />
        <FileExtensionRestriction>edi,999,ta1,txt</FileExtensionRestriction>
        <UseFullFilePath>Disabled</UseFullFilePath>
        <FullPathToFile />
        <PostProcessOperation>Move</PostProcessOperation>
        <TargetDirectory>$$EDI_ARCHIVE_DIRECTORY</TargetDirectory>
        <CompatModeMoved>false</CompatModeMoved>
        <Tokenizers />
        <SerializedTransactionsTag>1</SerializedTransactionsTag>
        <SubFolderIterationTag>false</SubFolderIterationTag>
        <FullFolderPathRestrictionsTag />
        <HiddenFilesTag>false</HiddenFilesTag>
        <SchedulerStartTag />
        <SchedulerEndTag />
        <ExcludeDaysTag />
        <ExcludeDatesTag />
        <TimeZone>System Default</TimeZone>
        <MinSecondsSinceFileModified>1</MinSecondsSinceFileModified>
        <MinDaysSinceFileModified>-1</MinDaysSinceFileModified>
        <MaxDaysSinceFileModified>-1</MaxDaysSinceFileModified>
        <CombineFiles>false</CombineFiles>
        <HeaderLines>0</HeaderLines>
      </ModuleConfig>
    </Listener>"""

TRANSPORT_STAGE = """    <Transport class="com.pilotfish.eip.modules.file.DirectoryTransport" name="Stage Ack Decision" retries="1">
      <ModuleConfig>
        <TargetDirectory>$$STAGED_DECISION_DIRECTORY</TargetDirectory>
        <FileName>{ognl:(getAttribute('AckType') != null ? getAttribute('AckType') : 'ack') + '_' + (getAttribute('StControlNumber') != null ? getAttribute('StControlNumber') : 'st') + '_decision'}</FileName>
        <FileExtension>xml</FileExtension>
        <UseFullFilePath>Disabled</UseFullFilePath>
        <FullPathToFile />
        <AppendToFile>Overwrite</AppendToFile>
        <MAXIMUM_MEMORY_SIZE>-1</MAXIMUM_MEMORY_SIZE>
        <FileNameConflictPattern />
        <BatchSensitive>false</BatchSensitive>
        <Command />
        <Shell>/bin/bash</Shell>
      </ModuleConfig>
    </Transport>"""

PROC_XPATH = """      <Processor class="com.pilotfish.eip.modules.other.XPathEvaluatorProcessor" name="Extract Ack Codes">
        <ModuleConfig>
          <ExecuteProcessor>true</ExecuteProcessor>
          <AttributeScope>Transaction</AttributeScope>
          <XPathExpressions>[eip_pair:AckType:eip_name:normalize-space(string((//ST/ST01 | //*[local-name()='ST']/*[local-name()='ST01'] | //TA1)[1])):eip_value][eip_pair:StControlNumber:eip_name:normalize-space(string((//ST/ST02 | //*[local-name()='ST']/*[local-name()='ST02'] | //TA1/TA101 | //*[local-name()='TA1']/*[local-name()='TA101'])[1])):eip_value][eip_pair:Ak9Code:eip_name:normalize-space(string((//AK9/AK901 | //*[local-name()='AK9']/*[local-name()='AK901'])[1])):eip_value][eip_pair:Ta1Code:eip_name:normalize-space(string((//TA1/TA104 | //*[local-name()='TA1']/*[local-name()='TA104'])[1])):eip_value][eip_pair:RejectCount:eip_name:string(count(//IK5[IK501='R'] | //*[local-name()='IK5'][*[local-name()='IK501']='R'])):eip_value]</XPathExpressions>
          <GlobalAttributeExpressions />
          <Namespaces>null</Namespaces>
          <Namespace />
          <XPath1Compatibility>false</XPath1Compatibility>
        </ModuleConfig>
      </Processor>"""

PROC_DEBUG_TXN = """      <Processor class="com.pilotfish.eip.modules.file.FileWriteProcessor" name="Debug Write Ack XML">
        <ModuleConfig>
          <ExecuteProcessor>true</ExecuteProcessor>
          <TargetDirectory>$$DEBUG_OUTPUT_DIRECTORY</TargetDirectory>
          <TargetFileName>{ognl:(getAttribute('StControlNumber') != null ? getAttribute('StControlNumber') : 'ack') + '_txn.xml'}</TargetFileName>
        </ModuleConfig>
      </Processor>"""

PROC_XSLT = """      <Processor class="com.pilotfish.eip.modules.transform.XSLTProcessor" name="Build Ack Decision XML">
        <ModuleConfig>
          <ExecuteProcessor>true</ExecuteProcessor>
          <XSLTPath>build-ack-decision.xslt</XSLTPath>
          <CacheXSLTToXML>false</CacheXSLTToXML>
          <XSLTEngine>Saxon</XSLTEngine>
          <XSLTParameters>[eip_pair:AckType:eip_name:{ognl:getAttribute('AckType')}:eip_value][eip_pair:StControlNumber:eip_name:{ognl:getAttribute('StControlNumber')}:eip_value][eip_pair:Ak9Code:eip_name:{ognl:getAttribute('Ak9Code')}:eip_value][eip_pair:Ta1Code:eip_name:{ognl:getAttribute('Ta1Code')}:eip_value][eip_pair:RejectCount:eip_name:{ognl:getAttribute('RejectCount')}:eip_value][eip_pair:SourceFile:eip_name:{ognl:getAttribute('com.pilotfish.FileName')}:eip_value]</XSLTParameters>
          <SaxonConverterHandling>Throw Exception</SaxonConverterHandling>
          <SaxonConverterEncoding>UTF-8</SaxonConverterEncoding>
        </ModuleConfig>
      </Processor>"""

PROC_DEBUG_DEC = """      <Processor class="com.pilotfish.eip.modules.file.FileWriteProcessor" name="Debug Write Ack Decision">
        <ModuleConfig>
          <ExecuteProcessor>true</ExecuteProcessor>
          <TargetDirectory>$$DEBUG_OUTPUT_DIRECTORY</TargetDirectory>
          <TargetFileName>{ognl:(getAttribute('StControlNumber') != null ? getAttribute('StControlNumber') : 'ack') + '_decision.xml'}</TargetFileName>
        </ModuleConfig>
      </Processor>"""


def route1(processors: str) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<Route xmlns="http://www.pilotfishtechnology.com/eipr/RouteSpec" CreatedBy="cursor-agent" RouteSpecificPooling="true" debugTraceCurrentSecondsToKeepFiles="-1" debugTraceMaxFiles="-1" debuggingTrace="true" debuggingTraceExpression="" debuggingTracePath="" transactionTimeToLive="300000">
  <RouteMetadata />
  <RoutingModule class="com.pilotfish.eip.modules.internal.NullRoutingModule">
    <ModuleConfig />
  </RoutingModule>
  <TransactionMonitors />
  <Source icon="" name="Inbound 999 TA1 Acknowledgments">
    <FormatProfile name="Split 999 Transactions" />
{LISTENER}
  </Source>
  <Target icon="" name="Classify And Stage Ack Decision">
    <FormatProfile name="Relay (System Format)" />
{TRANSPORT_STAGE}
    <Processors>
{processors}
    </Processors>
  </Target>
</Route>
"""


ROUTE2_FULL = """<?xml version="1.0" encoding="UTF-8"?>
<Route xmlns="http://www.pilotfishtechnology.com/eipr/RouteSpec" CreatedBy="cursor-agent" RouteSpecificPooling="true" debugTraceCurrentSecondsToKeepFiles="-1" debugTraceMaxFiles="-1" debuggingTrace="true" debuggingTraceExpression="" debuggingTracePath="" transactionTimeToLive="300000">
  <RouteMetadata />
  <RoutingModule class="com.pilotfish.eip.modules.routing.XPathRoutingModule">
    <ModuleConfig>
      <RuleSet accumulate="true">
        <Rule>
          <Targets>
            <TransportTarget name="Write Accepted" />
          </Targets>
          <Condition>
            <Expression>
              //DecisionBucket = 'accepted'
              <Namespaces />
            </Expression>
          </Condition>
        </Rule>
        <Rule>
          <Targets>
            <TransportTarget name="Write Rejected" />
          </Targets>
          <Condition>
            <Expression>
              //DecisionBucket = 'rejected'
              <Namespaces />
            </Expression>
          </Condition>
        </Rule>
        <Rule>
          <Targets>
            <TransportTarget name="Write Error" />
          </Targets>
          <Condition>
            <Expression>
              //DecisionBucket = 'error'
              <Namespaces />
            </Expression>
          </Condition>
        </Rule>
        <Rule>
          <Targets>
            <TransportTarget name="Write Ops Report" />
          </Targets>
          <Condition>
            <Expression>
              boolean(//DecisionBucket)
              <Namespaces />
            </Expression>
          </Condition>
        </Rule>
      </RuleSet>
    </ModuleConfig>
  </RoutingModule>
  <TransactionMonitors />
  <Source icon="" name="Staged Ack Decisions">
    <FormatProfile name="Relay (System Format)" />
    <Listener class="com.pilotfish.eip.modules.file.DirectoryListener" enabled="true" name="Poll Staged Ack Decisions">
      <ModuleConfig>
        <IS_TRIGGERABLE_LISTENER>false</IS_TRIGGERABLE_LISTENER>
        <CLIAllowed>false</CLIAllowed>
        <RESTART_ON_ERROR_TAG>false</RESTART_ON_ERROR_TAG>
        <StopWhenPollingFailure>true</StopWhenPollingFailure>
        <FIFOQueueName />
        <FIFOQueueDelay>500</FIFOQueueDelay>
        <TransactionLoggingAllowed>false</TransactionLoggingAllowed>
        <TransactionLoggingStoreAttributes>false</TransactionLoggingStoreAttributes>
        <TransactionLoggingStoreData>false</TransactionLoggingStoreData>
        <TransactionLoggingStoreDataBase64>false</TransactionLoggingStoreDataBase64>
        <PollingInterval>3</PollingInterval>
        <PollingDirectory>$$STAGED_DECISION_DIRECTORY</PollingDirectory>
        <FileNameRestriction />
        <FileExtensionRestriction>xml</FileExtensionRestriction>
        <UseFullFilePath>Disabled</UseFullFilePath>
        <FullPathToFile />
        <PostProcessOperation>Delete</PostProcessOperation>
        <TargetDirectory />
        <Tokenizers />
        <SerializedTransactionsTag>1</SerializedTransactionsTag>
        <SubFolderIterationTag>false</SubFolderIterationTag>
        <FullFolderPathRestrictionsTag />
        <HiddenFilesTag>false</HiddenFilesTag>
        <SchedulerStartTag />
        <SchedulerEndTag />
        <ExcludeDaysTag />
        <ExcludeDatesTag />
        <TimeZone>System Default</TimeZone>
        <MinSecondsSinceFileModified>1</MinSecondsSinceFileModified>
        <MinDaysSinceFileModified>-1</MinDaysSinceFileModified>
        <MaxDaysSinceFileModified>-1</MaxDaysSinceFileModified>
        <CombineFiles>false</CombineFiles>
        <HeaderLines>0</HeaderLines>
      </ModuleConfig>
    </Listener>
  </Source>
  <Target icon="" name="Accepted Bucket">
    <FormatProfile name="Relay (System Format)" />
    <Transport class="com.pilotfish.eip.modules.file.DirectoryTransport" name="Write Accepted" retries="1">
      <ModuleConfig>
        <TargetDirectory>$$ACCEPTED_DIRECTORY</TargetDirectory>
        <FileName>{ognl:(getAttribute('com.pilotfish.FileName') != null ? getAttribute('com.pilotfish.FileName') : 'ack') + '_accepted'}</FileName>
        <FileExtension>xml</FileExtension>
        <UseFullFilePath>Disabled</UseFullFilePath>
        <FullPathToFile />
        <AppendToFile>Overwrite</AppendToFile>
        <MAXIMUM_MEMORY_SIZE>-1</MAXIMUM_MEMORY_SIZE>
        <FileNameConflictPattern />
        <BatchSensitive>false</BatchSensitive>
        <Command />
        <Shell>/bin/bash</Shell>
      </ModuleConfig>
    </Transport>
    <Processors>
      <Processor class="com.pilotfish.eip.modules.other.XPathEvaluatorProcessor" name="Tag Accepted">
        <ModuleConfig>
          <ExecuteProcessor>true</ExecuteProcessor>
          <AttributeScope>Transaction</AttributeScope>
          <XPathExpressions>[eip_pair:Bucket:eip_name:string('accepted'):eip_value]</XPathExpressions>
          <GlobalAttributeExpressions />
          <Namespaces>null</Namespaces>
          <Namespace />
          <XPath1Compatibility>false</XPath1Compatibility>
        </ModuleConfig>
      </Processor>
    </Processors>
  </Target>
  <Target icon="" name="Rejected Bucket">
    <FormatProfile name="Relay (System Format)" />
    <Transport class="com.pilotfish.eip.modules.file.DirectoryTransport" name="Write Rejected" retries="1">
      <ModuleConfig>
        <TargetDirectory>$$REJECTED_DIRECTORY</TargetDirectory>
        <FileName>{ognl:(getAttribute('com.pilotfish.FileName') != null ? getAttribute('com.pilotfish.FileName') : 'ack') + '_rejected'}</FileName>
        <FileExtension>xml</FileExtension>
        <UseFullFilePath>Disabled</UseFullFilePath>
        <FullPathToFile />
        <AppendToFile>Overwrite</AppendToFile>
        <MAXIMUM_MEMORY_SIZE>-1</MAXIMUM_MEMORY_SIZE>
        <FileNameConflictPattern />
        <BatchSensitive>false</BatchSensitive>
        <Command />
        <Shell>/bin/bash</Shell>
      </ModuleConfig>
    </Transport>
  </Target>
  <Target icon="" name="Error Bucket">
    <FormatProfile name="Relay (System Format)" />
    <Transport class="com.pilotfish.eip.modules.file.DirectoryTransport" name="Write Error" retries="1">
      <ModuleConfig>
        <TargetDirectory>$$ERROR_DIRECTORY</TargetDirectory>
        <FileName>{ognl:(getAttribute('com.pilotfish.FileName') != null ? getAttribute('com.pilotfish.FileName') : 'ack') + '_error'}</FileName>
        <FileExtension>xml</FileExtension>
        <UseFullFilePath>Disabled</UseFullFilePath>
        <FullPathToFile />
        <AppendToFile>Overwrite</AppendToFile>
        <MAXIMUM_MEMORY_SIZE>-1</MAXIMUM_MEMORY_SIZE>
        <FileNameConflictPattern />
        <BatchSensitive>false</BatchSensitive>
        <Command />
        <Shell>/bin/bash</Shell>
      </ModuleConfig>
    </Transport>
  </Target>
  <Target icon="" name="Ops Report">
    <FormatProfile name="Relay (System Format)" />
    <Transport class="com.pilotfish.eip.modules.file.DirectoryTransport" name="Write Ops Report" retries="1">
      <ModuleConfig>
        <TargetDirectory>$$REPORTS_DIRECTORY</TargetDirectory>
        <FileName>{ognl:(getAttribute('com.pilotfish.FileName') != null ? getAttribute('com.pilotfish.FileName') : 'ack') + '_report'}</FileName>
        <FileExtension>xml</FileExtension>
        <UseFullFilePath>Disabled</UseFullFilePath>
        <FullPathToFile />
        <AppendToFile>Overwrite</AppendToFile>
        <MAXIMUM_MEMORY_SIZE>-1</MAXIMUM_MEMORY_SIZE>
        <FileNameConflictPattern />
        <BatchSensitive>false</BatchSensitive>
        <Command />
        <Shell>/bin/bash</Shell>
      </ModuleConfig>
    </Transport>
    <Processors>
      <Processor class="com.pilotfish.eip.modules.transform.XSLTProcessor" name="Build Ops Report Summary">
        <ModuleConfig>
          <ExecuteProcessor>true</ExecuteProcessor>
          <XSLTPath>build-ops-report.xslt</XSLTPath>
          <CacheXSLTToXML>false</CacheXSLTToXML>
          <XSLTEngine>Saxon</XSLTEngine>
          <XSLTParameters />
          <SaxonConverterHandling>Throw Exception</SaxonConverterHandling>
          <SaxonConverterEncoding>UTF-8</SaxonConverterEncoding>
        </ModuleConfig>
      </Processor>
    </Processors>
  </Target>
</Route>
"""

XSLT_DECISION = """<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:param name="AckType"/>
  <xsl:param name="StControlNumber"/>
  <xsl:param name="Ak9Code"/>
  <xsl:param name="Ta1Code"/>
  <xsl:param name="RejectCount"/>
  <xsl:param name="SourceFile"/>
  <xsl:template match="/">
    <xsl:variable name="rejects" select="number(concat('0', translate(string($RejectCount), translate(string($RejectCount), '0123456789', ''), '')))"/>
    <xsl:variable name="bucket">
      <xsl:choose>
        <xsl:when test="normalize-space($Ta1Code) = 'A'">accepted</xsl:when>
        <xsl:when test="normalize-space($Ta1Code) != '' and normalize-space($Ta1Code) != 'A'">rejected</xsl:when>
        <xsl:when test="normalize-space($Ak9Code) = 'A' and $rejects = 0">accepted</xsl:when>
        <xsl:when test="contains('REP', normalize-space($Ak9Code)) or $rejects &gt; 0">rejected</xsl:when>
        <xsl:otherwise>error</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <AckDecision>
      <AckType><xsl:value-of select="$AckType"/></AckType>
      <StControlNumber><xsl:value-of select="$StControlNumber"/></StControlNumber>
      <Ak9Code><xsl:value-of select="$Ak9Code"/></Ak9Code>
      <Ta1Code><xsl:value-of select="$Ta1Code"/></Ta1Code>
      <RejectCount><xsl:value-of select="$RejectCount"/></RejectCount>
      <SourceFile><xsl:value-of select="$SourceFile"/></SourceFile>
      <DecisionBucket><xsl:value-of select="$bucket"/></DecisionBucket>
    </AckDecision>
  </xsl:template>
</xsl:stylesheet>
"""

XSLT_REPORT = """<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/">
    <OpsReport>
      <Title>999/TA1 Acknowledgment Triage</Title>
      <xsl:copy-of select="/*"/>
      <Guidance>
        <xsl:choose>
          <xsl:when test="//DecisionBucket = 'accepted'">No action — functional group accepted.</xsl:when>
          <xsl:when test="//DecisionBucket = 'rejected'">Review IK3/IK4/IK5 or TA1 codes; fix and resubmit.</xsl:when>
          <xsl:otherwise>Unable to classify acknowledgment — inspect raw EDI.</xsl:otherwise>
        </xsl:choose>
      </Guidance>
    </OpsReport>
  </xsl:template>
</xsl:stylesheet>
"""

ENV = """# EDI 999 / TA1 Ack Triage — environment settings
EDI_INBOUND_DIRECTORY=input
EDI_ARCHIVE_DIRECTORY=output/archive
STAGED_DECISION_DIRECTORY=output/staged
DEBUG_OUTPUT_DIRECTORY=output/debug
ACCEPTED_DIRECTORY=output/accepted
REJECTED_DIRECTORY=output/rejected
ERROR_DIRECTORY=output/error
REPORTS_DIRECTORY=output/reports
"""


def sync_formats() -> None:
    src = IFACE / "formats"
    dst = DEMO / "pilotfish" / "demo-eip-root" / "formats"
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)


def sync_route_assets(route_name: str) -> None:
    src = ROUTES / route_name
    dst = DEMO_ROUTES / route_name
    dst.mkdir(parents=True, exist_ok=True)
    for f in src.iterdir():
        if f.is_file() and f.name != "route.v2.xml":
            shutil.copy2(f, dst / f.name)


def main() -> None:
    sync_formats()
    write(DEMO / "pilotfish" / "demo-eip-root" / "environment-settings.conf", ENV)
    write(IFACE / "environment-settings.conf", ENV)

    run(
        [
            "python3",
            "tools/publish_route_progress.py",
            "--root",
            str(DEMO),
            "--clear-replay",
        ]
    )

    # samples
    sample_src = ROOT / "EDI/TableData/x12/999-A1/examples/X231-response-to-functional-group-containing-3-837s.edi"
    samples = DEMO / "samples"
    samples.mkdir(parents=True, exist_ok=True)
    shutil.copy2(sample_src, samples / "999-partial-accept.edi")
    write(
        samples / "999-all-accept.edi",
        "ISA*00*          *00*          *ZZ*SENDER         *ZZ*RECEIVER       *260812*1430*^*00501*000000001*0*T*:~\n"
        "GS*FA*SENDER*RECEIVER*20260812*1430*1*X*005010X231A1~\n"
        "ST*999*0001*005010X231A1~\n"
        "AK1*HC*1*005010X222A1~\n"
        "AK2*837*0001~\n"
        "IK5*A~\n"
        "AK9*A*1*1*1~\n"
        "SE*6*0001~\n"
        "GE*1*1~\n"
        "IEA*1*000000001~\n",
    )
    write(
        samples / "ta1-accept.edi",
        "ISA*00*          *00*          *ZZ*SENDER         *ZZ*RECEIVER       *260812*1430*^*00501*000000002*0*T*:~\n"
        "TA1*000000001*260812*1430*A*000~\n"
        "IEA*0*000000002~\n",
    )

    r1 = "1 - Intake And Classify"
    r1_dir = ROUTES / r1
    r1_dir.mkdir(parents=True, exist_ok=True)
    write(r1_dir / "build-ack-decision.xslt", XSLT_DECISION)
    write(r1_dir / "diagram-groups.json", '{"groups":[{"id":"intake","title":"Intake & Classify","description":"Listen, EDI→XML, extract codes, stage AckDecision.","labels":["Poll Inbound 999 TA1 Files","Fork - XPath","Extract Ack Codes","Debug Write Ack XML","Build Ack Decision XML","Debug Write Ack Decision","Stage Ack Decision"]}]}')

    run(
        [
            "python3",
            "tools/update_build_status.py",
            "--root",
            str(DEMO),
            "--phase",
            "routes",
            "--message",
            "Watch Routes tab — building Route 1 live…",
            "--route",
            "1-intake-and-classify",
            "--active",
        ]
    )

    # Stage 0: listener + transport only
    write(r1_dir / "route.xml", route1(""))
    sync_route_assets(r1)
    publish(r1, "Route 1: listener + stage transport scaffold")

    write(r1_dir / "route.xml", route1(PROC_XPATH))
    sync_route_assets(r1)
    publish(r1, 'Route 1: adding “Extract Ack Codes”')

    write(r1_dir / "route.xml", route1(PROC_XPATH + "\n" + PROC_DEBUG_TXN))
    sync_route_assets(r1)
    publish(r1, 'Route 1: adding “Debug Write Ack XML”')

    write(r1_dir / "route.xml", route1(PROC_XPATH + "\n" + PROC_DEBUG_TXN + "\n" + PROC_XSLT))
    sync_route_assets(r1)
    publish(r1, 'Route 1: adding “Build Ack Decision XML”')

    write(r1_dir / "route.xml", route1(PROC_XPATH + "\n" + PROC_DEBUG_TXN + "\n" + PROC_XSLT + "\n" + PROC_DEBUG_DEC))
    sync_route_assets(r1)
    publish(r1, "Route 1: complete — intake + classify visible")

    # Route 2 progressive: start with listener+one transport, then expand via replay is hard;
    # publish scaffold then full in two beats, then use replay-stages for processors.
    r2 = "2 - Bucket And Report"
    r2_dir = ROUTES / r2
    r2_dir.mkdir(parents=True, exist_ok=True)
    write(r2_dir / "build-ops-report.xslt", XSLT_REPORT)
    write(
        r2_dir / "diagram-groups.json",
        '{"groups":[{"id":"bucket","title":"Bucket & Report","description":"Route AckDecision to accepted/rejected/error + ops report.","labels":["Poll Staged Ack Decisions","Conditional Router","Tag Accepted","Write Accepted","Write Rejected","Write Error","Build Ops Report Summary","Write Ops Report"]}]}',
    )
    write(r2_dir / "route.xml", ROUTE2_FULL)
    sync_route_assets(r2)

    run(
        [
            "python3",
            "tools/update_build_status.py",
            "--root",
            str(DEMO),
            "--phase",
            "routes",
            "--message",
            "Starting Route 2 — bucket + ops report (watch it grow)…",
            "--route",
            "2-bucket-and-report",
            "--active",
        ]
    )
    # Use publish_route_progress --replay-stages for module-by-module on route 2
    run(
        [
            "python3",
            "tools/publish_route_progress.py",
            "--root",
            str(DEMO),
            "--route",
            r2,
            "--replay-stages",
            "--pause",
            str(PAUSE),
        ]
    )

    run(
        [
            "python3",
            "tools/update_build_status.py",
            "--root",
            str(DEMO),
            "--phase",
            "routes",
            "--message",
            "Both routes live — 999/TA1 ack triage theater ready",
            "--route",
            "2-bucket-and-report",
            "--add-route",
            "1-intake-and-classify",
            "--add-route",
            "2-bucket-and-report",
            "--active",
        ]
    )
    run([
        "python3",
        "tools/update_build_status.py",
        "--root",
        str(DEMO),
        "--complete",
        "--message",
        "Build complete — demo UI ready",
    ])
    print("DONE — open http://localhost:8129/ (demo mode)", flush=True)


if __name__ == "__main__":
    main()
