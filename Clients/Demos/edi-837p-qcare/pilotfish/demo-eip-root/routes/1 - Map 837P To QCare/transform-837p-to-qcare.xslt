<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:qf="urn:qcare-837p"
  exclude-result-prefixes="xs qf">
  <!-- Golden-path: 837P EDI XML → QCare 2100-byte OT/B837 record (position overlays). -->
  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:function name="qf:padR" as="xs:string">
    <xsl:param name="v"/>
    <xsl:param name="len" as="xs:integer"/>
    <xsl:variable name="s" select="substring(string($v),1,$len)"/>
    <xsl:sequence select="concat($s, string-join(for $i in 1 to ($len - string-length($s)) return ' ', ''))"/>
  </xsl:function>
  <xsl:function name="qf:padL" as="xs:string">
    <xsl:param name="v"/>
    <xsl:param name="len" as="xs:integer"/>
    <xsl:param name="ch" as="xs:string"/>
    <xsl:variable name="raw" select="replace(string($v),'[^0-9A-Za-z]','')"/>
    <xsl:variable name="s" select="if (string-length($raw) &gt; $len) then substring($raw, string-length($raw)-$len+1) else $raw"/>
    <xsl:sequence select="concat(string-join(for $i in 1 to ($len - string-length($s)) return $ch, ''), $s)"/>
  </xsl:function>
  <xsl:function name="qf:put" as="xs:string">
    <xsl:param name="buf" as="xs:string"/>
    <xsl:param name="pos" as="xs:integer"/>
    <xsl:param name="val"/>
    <xsl:variable name="v" select="string($val)"/>
    <xsl:sequence select="concat(substring($buf,1,$pos - 1), $v, substring($buf, $pos + string-length($v)))"/>
  </xsl:function>
  <xsl:function name="qf:amt" as="xs:string">
    <xsl:param name="raw"/>
    <xsl:param name="len" as="xs:integer"/>
    <xsl:variable name="n" select="normalize-space(string($raw))"/>
    <xsl:variable name="d" select="if ($n='') then '0' else if (contains($n,'.')) then substring-before($n,'.') else $n"/>
    <xsl:sequence select="qf:padL(replace($d,'[^0-9]',''), $len, '0')"/>
  </xsl:function>
  <xsl:function name="qf:el" as="xs:string">
    <xsl:param name="seg"/>
    <xsl:param name="idx" as="xs:integer"/>
    <xsl:sequence select="normalize-space(string(($seg/*[local-name()=concat(local-name($seg), format-number($idx,'00'))] | $seg/*[local-name()='Element'][$idx + 1])[1]))"/>
  </xsl:function>
  <xsl:function name="qf:nm1">
    <xsl:param name="ctx"/>
    <xsl:param name="qual" as="xs:string"/>
    <xsl:sequence select="($ctx//*[local-name()='NM1'][(*[local-name()='NM101'], *[local-name()='Element'][2])[1]=$qual])[1]"/>
  </xsl:function>
  <xsl:function name="qf:seg">
    <xsl:param name="ctx"/>
    <xsl:param name="id" as="xs:string"/>
    <xsl:sequence select="($ctx//*[local-name()=$id] | $ctx//*[local-name()='Segment'][*[local-name()='Element'][1]=$id])[1]"/>
  </xsl:function>
  <xsl:function name="qf:ref">
    <xsl:param name="ctx"/>
    <xsl:param name="qual" as="xs:string"/>
    <xsl:sequence select="($ctx//*[local-name()='REF'][(*[local-name()='REF01'], *[local-name()='Element'][2])[1]=$qual] | $ctx//*[local-name()='Segment'][*[local-name()='Element'][1]='REF' and *[local-name()='Element'][2]=$qual])[1]"/>
  </xsl:function>
  <xsl:function name="qf:dtp">
    <xsl:param name="ctx"/>
    <xsl:param name="qual" as="xs:string"/>
    <xsl:sequence select="($ctx//*[local-name()='DTP'][(*[local-name()='DTP01'], *[local-name()='Element'][2])[1]=$qual] | $ctx//*[local-name()='Segment'][*[local-name()='Element'][1]='DTP' and *[local-name()='Element'][2]=$qual])[1]"/>
  </xsl:function>
  <xsl:function name="qf:n3">
    <xsl:param name="nm"/>
    <xsl:sequence select="($nm/following-sibling::*[local-name()='N3'][1] | $nm/../*[local-name()='N3'][1])[1]"/>
  </xsl:function>
  <xsl:function name="qf:n4">
    <xsl:param name="nm"/>
    <xsl:sequence select="($nm/following-sibling::*[local-name()='N4'][1] | $nm/../*[local-name()='N4'][1])[1]"/>
  </xsl:function>
  <xsl:function name="qf:zip5" as="xs:string"><xsl:param name="z"/><xsl:sequence select="qf:padR(substring(replace(string($z),'[^0-9]',''),1,5),5)"/></xsl:function>
  <xsl:function name="qf:zip4" as="xs:string"><xsl:param name="z"/><xsl:sequence select="qf:padR(substring(replace(string($z),'[^0-9]',''),6,4),4)"/></xsl:function>

  <xsl:template match="/">
    <xsl:variable name="txn" select="(//*[local-name()='Transaction'] | /*)[1]"/>
    <xsl:variable name="nm85" select="qf:nm1($txn,'85')"/>
    <xsl:variable name="nm82" select="qf:nm1($txn,'82')"/>
    <xsl:variable name="nm87" select="qf:nm1($txn,'87')"/>
    <xsl:variable name="nmIL" select="qf:nm1($txn,'IL')"/>
    <xsl:variable name="nmDN" select="qf:nm1($txn,'DN')"/>
    <xsl:variable name="nm77" select="qf:nm1($txn,'77')"/>
    <xsl:variable name="nmPR" select="qf:nm1($txn,'PR')"/>
    <xsl:variable name="nm41" select="qf:nm1($txn,'41')"/>
    <xsl:variable name="clm" select="qf:seg($txn,'CLM')"/>
    <xsl:variable name="dmg" select="qf:seg($txn,'DMG')"/>
    <xsl:variable name="sv1" select="qf:seg($txn,'SV1')"/>
    <xsl:variable name="lx" select="qf:seg($txn,'LX')"/>
    <xsl:variable name="bht" select="qf:seg($txn,'BHT')"/>
    <xsl:variable name="sbr" select="qf:seg($txn,'SBR')"/>
    <xsl:variable name="hi" select="qf:seg($txn,'HI')"/>
    <xsl:variable name="prvPE" select="($txn//*[local-name()='PRV'][(*[local-name()='PRV01'], *[local-name()='Element'][2])[1]='PE'])[1]"/>
    <xsl:variable name="prvBI" select="($txn//*[local-name()='PRV'][(*[local-name()='PRV01'], *[local-name()='Element'][2])[1]='BI'])[1]"/>

    <xsl:variable name="renderId" select="normalize-space((qf:el($nm82,9), qf:el($nm85,9))[normalize-space(.)!=''][1])"/>
    <xsl:variable name="billNpi" select="normalize-space(qf:el($nm85,9))"/>
    <xsl:variable name="affil" select="normalize-space(qf:el(qf:ref($txn,'EI'),2))"/>
    <xsl:variable name="mbrId" select="upper-case(normalize-space(qf:el($nmIL,9)))"/>
    <xsl:variable name="mbrSuff" select="if (starts-with($mbrId,'U')) then '01' else substring(concat($mbrId,'   '),10,3)"/>
    <xsl:variable name="procCode" select="normalize-space(string(($sv1/*[local-name()='SV101']/*[local-name()='SV101_02'] | $sv1/*[local-name()='SV101_2'] | $sv1/*[local-name()='Element'][2])[1]))"/>
    <xsl:variable name="procMod1" select="normalize-space(string(($sv1/*[local-name()='SV101']/*[local-name()='SV101_03'] | $sv1/*[local-name()='SV101_3'])[1]))"/>
    <xsl:variable name="pos" select="normalize-space(string(($clm/*[local-name()='CLM05']/*[local-name()='CLM05_01'] | $clm/*[local-name()='CLM05_1'] | $sv1/*[local-name()='SV105'])[1]))"/>
    <xsl:variable name="dosRaw" select="normalize-space(qf:el(qf:dtp($txn,'472'),3))"/>
    <xsl:variable name="dosBeg" select="if (contains($dosRaw,'-')) then substring-before($dosRaw,'-') else if (string-length($dosRaw)=16) then substring($dosRaw,1,8) else $dosRaw"/>
    <xsl:variable name="dosEnd" select="if (contains($dosRaw,'-')) then substring-after($dosRaw,'-') else if (string-length($dosRaw)=16) then substring($dosRaw,9,8) else $dosRaw"/>
    <xsl:variable name="taxonomy" select="normalize-space((qf:el($prvPE,3), qf:el($prvBI,3))[normalize-space(.)!=''][1])"/>
    <xsl:variable name="billZip" select="normalize-space(qf:el(qf:n4($nm85),3))"/>
    <xsl:variable name="svcZip" select="normalize-space(qf:el(qf:n4($nm77),3))"/>
    <xsl:variable name="pay2Zip" select="normalize-space(qf:el(qf:n4($nm87),3))"/>
    <xsl:variable name="subZip" select="normalize-space(qf:el(qf:n4($nmIL),3))"/>
    <xsl:variable name="lxNo" select="normalize-space(qf:el($lx,1))"/>

    <xsl:variable name="dxList" as="xs:string*">
      <xsl:for-each select="$hi/*[starts-with(local-name(),'HI') and not(contains(local-name(),'_'))]">
        <xsl:variable name="qual" select="upper-case(normalize-space(string(*[substring(local-name(), string-length(local-name())-2) = '_01'][1])))"/>
        <xsl:variable name="code" select="upper-case(translate(normalize-space(string(*[substring(local-name(), string-length(local-name())-2) = '_02'][1])), '.', ''))"/>
        <xsl:if test="($qual = 'ABK' or $qual = 'ABF' or $qual = 'BK' or $qual = 'BF') and $code != ''">
          <xsl:sequence select="concat(if ($qual='ABK' or $qual='ABF') then '10' else '09', '|', qf:padR($code,7))"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="blank" select="string-join(for $i in 1 to 2100 return ' ', '')"/>
    <xsl:variable name="r0" select="qf:put($blank,1,'OT')"/>
    <xsl:variable name="r1" select="qf:put($r0,3,'B837')"/>
    <!-- Demo-stable claim header (not REPOSHDR-identical) -->
    <xsl:variable name="r2" select="qf:put($r1,7, concat('*097','00','00','000','0','0001*', qf:padL(if ($lxNo='') then '1' else $lxNo,2,'0'),'00'))"/>
    <xsl:variable name="r3" select="qf:put($r2,28, qf:padR(substring($renderId,1,12),12))"/>
    <xsl:variable name="r4" select="qf:put($r3,40, qf:padR(substring($renderId,13,3),3))"/>
    <xsl:variable name="r5" select="qf:put($r4,43, qf:padR(substring($affil,1,12),12))"/>
    <xsl:variable name="r6" select="qf:put($r5,55, qf:padR(substring($affil,13,3),3))"/>
    <xsl:variable name="r7" select="qf:put($r6,58, qf:padR(substring($mbrId,1,1),1))"/>
    <xsl:variable name="r8" select="qf:put($r7,59, qf:padR(substring($mbrId,2,2),2))"/>
    <xsl:variable name="r9" select="qf:put($r8,61, qf:padR(substring($mbrId,4,2),2))"/>
    <xsl:variable name="r10" select="qf:put($r9,63, qf:padR(substring($mbrId,6,4),4))"/>
    <xsl:variable name="r11" select="qf:put($r10,67, qf:padR($mbrSuff,3))"/>
    <xsl:variable name="r12" select="qf:put($r11,72, qf:padR(upper-case(qf:el($nmIL,3)),15))"/>
    <xsl:variable name="r13" select="qf:put($r12,87, qf:padR(upper-case(qf:el($nmIL,4)),15))"/>
    <xsl:variable name="r14" select="qf:put($r13,102, qf:padR(upper-case(substring(qf:el($nmIL,5),1,1)),1))"/>
    <xsl:variable name="r15" select="qf:put($r14,103, qf:padR(upper-case(qf:el($nmDN,3)),15))"/>
    <xsl:variable name="r16" select="qf:put($r15,118, qf:padR(upper-case(qf:el($nmDN,4)),15))"/>
    <xsl:variable name="r17" select="qf:put($r16,133, qf:padR(upper-case(substring(qf:el($nmDN,5),1,1)),1))"/>

    <!-- apply up to 18 diagnoses + pointers via chained puts -->
    <xsl:variable name="d0" select="$r17"/>
    <xsl:variable name="d1" select="if (exists($dxList[1])) then qf:put(qf:put($d0,134,substring-before($dxList[1],'|')),136,substring-after($dxList[1],'|')) else $d0"/>
    <xsl:variable name="d2" select="if (exists($dxList[2])) then qf:put(qf:put($d1,143,substring-before($dxList[2],'|')),145,substring-after($dxList[2],'|')) else $d1"/>
    <xsl:variable name="d3" select="if (exists($dxList[3])) then qf:put(qf:put($d2,152,substring-before($dxList[3],'|')),154,substring-after($dxList[3],'|')) else $d2"/>
    <xsl:variable name="d4" select="if (exists($dxList[4])) then qf:put(qf:put($d3,161,substring-before($dxList[4],'|')),163,substring-after($dxList[4],'|')) else $d3"/>
    <xsl:variable name="d5" select="if (exists($dxList[5])) then qf:put(qf:put($d4,170,substring-before($dxList[5],'|')),172,substring-after($dxList[5],'|')) else $d4"/>
    <xsl:variable name="d6" select="if (exists($dxList[6])) then qf:put(qf:put($d5,179,substring-before($dxList[6],'|')),181,substring-after($dxList[6],'|')) else $d5"/>
    <xsl:variable name="d7" select="if (exists($dxList[7])) then qf:put(qf:put($d6,188,substring-before($dxList[7],'|')),190,substring-after($dxList[7],'|')) else $d6"/>
    <xsl:variable name="d8" select="if (exists($dxList[8])) then qf:put(qf:put($d7,197,substring-before($dxList[8],'|')),199,substring-after($dxList[8],'|')) else $d7"/>
    <xsl:variable name="p1" select="if (exists($dxList[1])) then qf:put($d8,296,'01') else $d8"/>
    <xsl:variable name="p2" select="if (exists($dxList[2])) then qf:put($p1,298,'02') else $p1"/>
    <xsl:variable name="p3" select="if (exists($dxList[3])) then qf:put($p2,300,'03') else $p2"/>
    <xsl:variable name="p4" select="if (exists($dxList[4])) then qf:put($p3,302,'04') else $p3"/>

    <xsl:variable name="a1" select="qf:put($p4,306, qf:padR(qf:el($dmg,2),8))"/>
    <xsl:variable name="a2" select="qf:put($a1,314, qf:padR(qf:el($dmg,3),1))"/>
    <xsl:variable name="a3" select="qf:put($a2,332, qf:padR(substring(qf:el($clm,6),1,1),1))"/>
    <xsl:variable name="a4" select="qf:put($a3,333, 'N')"/>
    <xsl:variable name="a5" select="qf:put($a4,355, '00000000')"/>
    <xsl:variable name="a6" select="qf:put($a5,403, qf:padR(qf:el($nmDN,9),12))"/>
    <xsl:variable name="a7" select="qf:put($a6,460, qf:padR($dosBeg,8))"/>
    <xsl:variable name="a8" select="qf:put($a7,468, qf:padR($dosEnd,8))"/>
    <xsl:variable name="a9" select="qf:put($a8,476, qf:padR($pos,2))"/>
    <xsl:variable name="a10" select="qf:put($a9,478, concat(qf:padR($procCode,5), qf:padR($procMod1,2), '  '))"/>
    <xsl:variable name="a11" select="qf:put($a10,499, 'R')"/>
    <xsl:variable name="a12" select="qf:put($a11,511, qf:amt(qf:el($sv1,2),7))"/>
    <xsl:variable name="a13" select="qf:put($a12,520, qf:padL(if (qf:el($sv1,4)='') then '1' else qf:el($sv1,4),3,'0'))"/>
    <xsl:variable name="a14" select="qf:put($a13,525, qf:padR(qf:el($clm,1),20))"/>
    <xsl:variable name="a15" select="qf:put($a14,605, '0000000')"/>
    <xsl:variable name="a16" select="qf:put($a15,632, qf:amt(qf:el($clm,2),7))"/>
    <xsl:variable name="a17" select="qf:put($a16,641, qf:padR(if (qf:el($clm,6)='') then 'Y' else qf:el($clm,6),1))"/>
    <xsl:variable name="a18" select="qf:put($a17,642, qf:padR(if (qf:el($clm,7)='') then 'A' else qf:el($clm,7),1))"/>
    <xsl:variable name="a19" select="qf:put($a18,651, qf:padR(qf:el($nm41,9),15))"/>
    <xsl:variable name="a20" select="qf:put($a19,728, qf:padR(if (qf:el(qf:ref($txn,'9B'),2)='') then '//1' else qf:el(qf:ref($txn,'9B'),2),15))"/>
    <xsl:variable name="a21" select="qf:put($a20,795, 'F')"/>
    <xsl:variable name="a22" select="qf:put($a21,851, 'P')"/>
    <xsl:variable name="a23" select="qf:put($a22,911, qf:padR(qf:el(qf:dtp($txn,'050'),3),8))"/>
    <xsl:variable name="a24" select="qf:put($a23,1445, qf:padR(qf:el($sbr,1),1))"/>
    <xsl:variable name="a25" select="qf:put($a24,1535, '00000000')"/>
    <xsl:variable name="a26" select="qf:put($a25,1543, qf:padR(qf:el(qf:n3($nm87),1),25))"/>
    <xsl:variable name="a27" select="qf:put($a26,1568, qf:padR(qf:el(qf:n4($nm87),1),18))"/>
    <xsl:variable name="a28" select="qf:put($a27,1586, qf:padR(qf:el(qf:n4($nm87),2),2))"/>
    <xsl:variable name="a29" select="qf:put($a28,1588, qf:zip5($pay2Zip))"/>
    <xsl:variable name="a30" select="qf:put($a29,1593, qf:zip4($pay2Zip))"/>
    <xsl:variable name="a31" select="qf:put($a30,1597, qf:padR($renderId,10))"/>
    <xsl:variable name="a32" select="qf:put($a31,1607, qf:padR($billNpi,10))"/>
    <xsl:variable name="a33" select="qf:put($a32,1617, qf:padR(qf:el(qf:ref($txn,'F8'),2),30))"/>
    <xsl:variable name="a34" select="qf:put($a33,1656, qf:padR(qf:el($nmPR,9),15))"/>
    <xsl:variable name="a35" select="qf:put($a34,1671, qf:padR(if (qf:el($bht,6)='') then 'CH' else qf:el($bht,6),2))"/>
    <xsl:variable name="a36" select="qf:put($a35,1673, qf:padR(if (exists($prvBI)) then $taxonomy else '',10))"/>
    <xsl:variable name="a37" select="qf:put($a36,1683, qf:padR(if (exists($prvBI)) then substring($taxonomy,1,4) else '',4))"/>
    <xsl:variable name="a38" select="qf:put($a37,1687, qf:padR(if (exists($prvPE)) then $taxonomy else (if (not(exists($prvBI))) then $taxonomy else ''),10))"/>
    <xsl:variable name="a39" select="qf:put($a38,1697, qf:padR(if (exists($prvPE) or not(exists($prvBI))) then substring($taxonomy,1,4) else '',4))"/>
    <xsl:variable name="a40" select="qf:put($a39,1701, '00000000000')"/>
    <xsl:variable name="a41" select="qf:put($a40,1714, qf:zip5($svcZip))"/>
    <xsl:variable name="a42" select="qf:put($a41,1719, qf:zip5($billZip))"/>
    <xsl:variable name="a43" select="qf:put($a42,1724, qf:zip5($subZip))"/>
    <xsl:variable name="a44" select="qf:put($a43,1754, qf:padR(qf:el(qf:n3($nm85),1),25))"/>
    <xsl:variable name="a45" select="qf:put($a44,1804, qf:padR(qf:el(qf:n4($nm85),1),18))"/>
    <xsl:variable name="a46" select="qf:put($a45,1822, qf:padR(qf:el(qf:n4($nm85),2),2))"/>
    <xsl:variable name="a47" select="qf:put($a46,1824, qf:zip5($billZip))"/>
    <xsl:variable name="a48" select="qf:put($a47,1829, qf:zip4($billZip))"/>
    <xsl:variable name="a49" select="qf:put($a48,1833, qf:padR(qf:el(qf:n3($nm77),1),25))"/>
    <xsl:variable name="a50" select="qf:put($a49,1883, qf:padR(qf:el(qf:n4($nm77),1),18))"/>
    <xsl:variable name="a51" select="qf:put($a50,1901, qf:padR(qf:el(qf:n4($nm77),2),2))"/>
    <xsl:variable name="a52" select="qf:put($a51,1903, if (normalize-space($svcZip)='') then '00000' else qf:zip5($svcZip))"/>
    <xsl:variable name="a53" select="qf:put($a52,1908, if (normalize-space($svcZip)='') then '0000' else qf:zip4($svcZip))"/>

    <xsl:value-of select="substring($a53,1,2100)"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
</xsl:stylesheet>
