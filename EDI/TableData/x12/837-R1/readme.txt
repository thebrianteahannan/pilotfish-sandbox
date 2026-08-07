  TO: Implementation Guide Table Data Users
FROM: Washington Publishing Company
DATE: November 2010
  RE: 005010X298A1 Table Data
==============================================================================

COPYRIGHT
=========
Copyright 2010 Washington Publishing Company (WPC) and Data Interchange
Standards Association (DISA).

INTRODUCTION
============
Enclosed please find the eleven (11) data files which represent the variable
length format of Version 005 Release 010 Industry Implementation X298A1.
These data files are inert raw data intended to be imported into existing
applications. This data does not contain application programs and is not
intended to replace the X12 technical reports.

FOR ALL QUESTIONS
=================
For questions concerning the format, please contact Steve Bass with
Washington Publishing Company:

(425) 562-2245
steve@wpc-edi.com

LICENSE
=======
You may not use, copy or modify the information in this ZIP other than as
provided in this paragraph. The table data contained herein may be used by
you, the licensee, for import into and use by a program or application
such as an EDI translator or syntax analyzer which, when used in conjunction
with the data, provides a value-added product over and above replication of
the copyrighted documentation. You may redistribute this data only as
incorporated in such a value-added product as described. This does not imply
any right to redistribute in any other manner the files contained on this
disk, nor to use these files to republish the copyrighted implementation
guides. DISA holds the copyright on the content of the guides and WPC holds
the copyright on the format.

DISCLAIMER
==========
As to this WPC/DISA Table Data and its documentation, all warranties of
merchantability or fitness of use for a particular purpose, express or
implied, except for those contained in this agreement, have been waived by
WPC, DISA and Licensee.  The Table Data that is licensed shall be considered
an "as is" Work. WPC and DISA do not guarantee that the Table Data will
meet "all requirements" of Licensee's business and shall not be responsible
for any damages, consequential or otherwise, that may be suffered by Licensee
or its employees or agents in the use of the Table Data.

INCLUDED FILES
==============
The following twelve (11) files comprise this variable length representation:

  1. SETHEAD.TXT
  2. SETDETL.TXT
  3. SEGHEAD.TXT
  4. SEGDETL.TXT
  5. COMHEAD.TXT
  6. COMDETL.TXT
  7. ELEHEAD.TXT
  8. ELEDETL.TXT
  9. CONDETL.TXT
 10. CONTEXT.TXT
 11. FREEFORM.TXT

The core syntactical data is represented in data files 1-8. Files 9 and 10
represent the implementation. All free-form textual data is represented in
data file 11.

FILE STRUCTURE FOR CORE SYNTACTICAL DATA
========================================
An explanation of the file layouts for the core syntactical data follows. 
Note that the core syntactical data is quote-comma delimited. Lengths 
expressed are current maximum and may change as the standards require.

  SETHEAD.TXT
  -----------
   Fields: Transaction Set ID, Transaction Set Name, Functional Group ID
  Lengths: 6, 80, 2
  Example: "810-A1","Invoice","HC"

  SETDETL.TXT
  -----------
   Fields: Transaction Set ID, Area, Sequence, Segment ID, Requirement, 
           Maximum Use, Loop Level, Loop Repeat, Loop Identifier
  Lengths: 6, 1, 4, 3, 1, 6, 1, 6, 6
  Example: "810-A1","2","010","IT1","O","1","1","200000","IT1"

  SEGHEAD.TXT
  -----------
   Fields: Segment ID, Segment Name
  Lengths: 3, 80
  Example: "A1","Rejection"

  SEGDETL.TXT
  -----------
   Fields: Segment ID, Sequence, Data Element Number, Requirement, Repeat
  Lengths: 3, 2, 4, 1, 4
  Example: "A1","01","131","M","1"

  COMHEAD.TXT
  -----------
   Fields: Composite Data Element Number, Composite Name
  Lengths: 4, 80
  Example: "C002","Document/message name"

  COMDETL.TXT
  -----------
   Fields: Composite Data Element Number, Sequence, Data Element
           Number, Requirement
  Lengths: 4, 2, 4, 1
  Example: "C002","01","1001","C"

  ELEHEAD.TXT
  -----------
   Fields: Data Element Number, Data Element Name
  Lengths: 4, 80
  Example: "1","Route Code"

  ELEDETL.TXT
  -----------
   Fields: Data Element Number, Data Element Type, Minimum Length, 
           Maximum Length
  Lenghts: 4, 2, 6, 6
  Example: "1","AN","1","13"


FILE STRUCTURE FOR IMPLEMENTATION DATA
============================================
An explanation of the file layouts for the implementation data follows. 
Note that the implementation data is quote-comma delimited. Lengths 
expressed are current maximum and may change as the standards require.

  CONDETL.TXT
  -----------
   Fields: Record Type, Transaction Set ID, Area, Sequence, Segment ID,
           Reference Designator, Composite ID, Composite Sequence,
           Data Element Number, Code, Table, Position, Usage
  Lengths: 1, 6, 1, 4, 3, 2, 4, 2, 4, 6, 1, 3, 1
  Example: "E","857-U1","4","310","MAN","01","","","88","GM","","","2"
    Notes: Field 1 - Record Type:
           There are five (5) record types:
           "A" = Records that pertain to the transaction set
           "B" = Records that pertain to the segments
           "C" = Records that pertain to elements (simple and composite)
           "D" = Records that pertain to component elements
           "E" = Records that pertain to code values

           Field 2 - Transaction Set ID:
           If the Transaction Set ID is greater than three bytes long,
           the transaction has been modified from the original ASC X12
           structure to include additional iterations of certain loops.
           This is done to convey different implementations of those
           loops.

           Field 3 - Area:
           Often this is identical to the ASC X12 table number. When HL
           loops and individual segments are repeated, this number may be
           incremented. See Field 11 note.

           Field 4 - Sequence:
           Often this is identical to the ASC X12 position number. When HL
           loops and individual elements are repeated, this number may be
           altered. See Field 12 note.

           Fields 5-10:
           This data, in conjunction with fields 1-4, indicate what
           standards entity for which a usage is being stated in Field 13.

           Field 11 - Table
           When loops are iterated to convey different uses of a generalized
           loop, this number states the ASC X12 table number.

           Field 12 - Position
           When loops are iterated to convey different uses of a generalized
           loop, this number states the ASC X12 position number.

           Field 13 - Usage
           This field can take on eight (8) different values. The preceding
           fields indicate what standards entity the usage is for:
           "1" = Mandatory
           "2" = Optional
           "3" = Conditional
           "4" = Floating
           "5" = Required
           "6" = Recommended
           "7" = Not Recommended
           "8" = Not Used

  CONTEXT.TXT
  -----------
   Fields: Record Type, Transaction Set ID, Area, Sequence, Segment ID,
           Reference Designator, Composite ID, Composite Sequence,
           Data Element Number, Code, Table, Position, Note Number,
           Note Type, Note
  Lengths: 1, 6, 1, 4, 3, 2, 4, 2, 4, 6, 1, 3, 9, 1, 4096
  Example: "E","830","2","410","FST","02","","","680","Q","","","5384","",
           "This code is only used when the receiver is performing 
           replenishment based on forecast information."
    Notes: Fields 1-12 are the same as CONDETL.TXT

           Field 13 - Note Number:
           Each note is numbered. There is no logic to the numbering.
           Some users may wish to import the notes into a separate table.
           This number can be used as a key to that table.

           Field 14 - Note Type:
           Each note can be given additional qualification:
           "A" = Industry Segment Name
           "B" = Data Element Name Aliases
                 These are not the ASC X12N Health Care Data Element
                 Dictionary Names. See "F" below.
                 Those names do not appear in this data.
           "C" = UB-92 reference
           "D" = NSF reference
           "E" = Example
           "F" = ASC X12N Health Care Data Element Dictionary Name 

           Field 15 - Note:
           Free form text containing context specific instruction. There
           may be typesetting mark-up language codes in these notes.
           Possible codes:
           <T>  = Tab Stop
           <R>  = Carriage Return
           <B>  = Bold type font
           <D>  = Default type font
           <I>  = Italic type font
           <BI> = Bold Italic type font

           If a quote mark (") appears in the body of the note, a double
           quote mark is used in field 14. For example:
           "This is a note with some ""quoted"" material."


FILE STRUCTURE FOR FREE-FORM TEXTUAL DATA
=========================================
An explanation of the file layouts for the free-form textual data 
(FREEFORM.TXT) follows. Note that the free-form textual data is 
represented in a simple custom format. The rules for this format 
are described below.

  FREEFORM.TXT RULES
  ------------------
  - This file contains all of the free form text within the standard.

  - Lines of data are terminated with a carriage return/line feed.

  - Lines of data in which the first character is an asterisk (*),
    indicate the beginning of a new piece of free form data. A six
    character tag indicates the type of free form data that follows.

  - There are currently 8 different types of data (described below)
    in this file.

  - The line with the asterisk (the tagged line) indicates the type of
    free form data. The line immediately following the tagged line (the
    key line) specifies to what standards entity the free form data
    belongs. The key line may have one or more entries separated by
    commas.

  - Lines of data may end with a space character followed by a carriage
    return/line feed. This indicates that the next line is the
    continuation of the preceding line.

  - If a line of data ends simply with a carriage return, this may
    indicate that a carriage return is required within this piece of free
    form data, or that this piece of data ends on this line. The first
    character of the next line indicates which of these two choices is
    applicable. If the next line of data does not begin with an asterisk,
    the preceding line is a continuation of the data. If the next line
    begins with an asterisk, a new piece of free form data is beginning.

  INCLUDED FREE-FORM TEXT
  -----------------------

  1. Transaction Set Purpose/Scope
  --------------------------------
  Tag Line: *SETPUR
  Key Line: Transaction Set ID
   Lengths: 6
   Example: *SETPUR
            810
            This standard provides the format and establishes the data 
            contents of an invoice transaction set. The invoice 
            transaction set provides for customary and established 
            business and industry practice relative to the billing for 
            goods and services provided.

  2. Segment Purpose
  ------------------
  Tag Line: *SEGPUR
  Key Line: Segment ID
   Lengths: 3
   Example: *SEGPUR
            A1
            To identify elements not meeting the EDI edit criteria.

  3. Segment Notes/Comments
  -------------------------
  Tag Line: *SEGNTE
  Key Line: Segment ID, Sequence, Note Type, Paragraph Number
   Lengths: 3, 2, 1, 1
     Notes: 1) "Note Type" has three possible values, N = Syntax Note, S = 
            Semantic Note, and C = Comment. 2) "Paragraph Number" is used 
            when there is more than one note of the same sequence and type. 
            It is a sequential number starting at one and incrementing by 
            one. 3) Beginning with Version 003011, the segment syntax notes 
            are codified according to rules prescribed in DSTU X12.6-1989. 
            This codification allows for automatic syntax checking of 
            syntax notes. The textual equivalent of the codified note 
            no longer appears on the diskette because it is no longer 
            supported by ASC X12 and is easily generated. 4) Beginning with 
            Version 003020, segment semantic notes are included according to 
            rules prescribed in DSTU X12.6-1989. Many notes which were 
            "Comments" in past releases have now been changed to "Semantic 
            Notes".
   Example: *SEGNTE
            A1,01,C,1
            The rejected-set identifier contains up to the first 19 
            characters of the first segment in the transaction set with all 
            asterisks converted to spaces and excluding the new line 
            character.
            *SEGNTE
            A3,06,N,1
            P0607

  4. Composite Purpose
  --------------------
  Tag Line: *COMPUR
  Key Line: Composite ID
   Lengths: 4
   Example: *COMPUR
            C001
            To identify a composite unit of measure

  5. Composite Notes/Comments
  -------------------------
  Tag Line: *COMNTE
  Key Line: Composite ID, Sequence, Note Type, Paragraph Number
   Lengths: 4, 2, 1, 1
     Notes: 1) "Note Type" has three possible values, N = Syntax Note, S = 
            Semantic Note, and C = Comment. 2) "Paragraph Number" is used 
            when there is more than one note of the same sequence and type. 
            It is a sequential number starting at one and incrementing by 
            one.
   Example: *COMNTE
            C001,02,C,1
            If C001-02 is not used, its value is to be interpreted as 1.

  6. Simple Data Element Definitions
  ----------------------------------
  Tag Line: *ELEDEF
  Key Line: Data Element Number
   Lengths: 4
   Example: *ELEDEF
            1
            Mutually defined route code.

  7. Simple Data Element Code Definitions
  ---------------------------------------
  Tag Line: *ELECOD
  Key Line: Data Element Number, Partition Number, Code Value, 
            Paragraph Number
   Lengths: 4, 1, 6, 1
     Notes: 1) "Partition Number" is used for multi-part codes. For 
            instance, data element 103 (Packaging Code) is a minimum 5, 
            maximum 5 data element. The first 3 characters specify a 
            packaging form, like box. The last 2 characters specify a 
            packaging material, such as wood. The values for packaging 
            form are all 3 characters and belong to partition number 1. 
            The values for packaging material are all 2 characters and 
            belong to partition number 2. For the most part, partition 
            number is the space character. 2) "Paragraph Number" is used 
            when there is more than one definition for any one code value. 
            This used to occur on data element 479, but does not in this 
            workbook. Therefore, paragraph number is always "1".
   Example: *ELECOD
            8, ,E,1
            Payee
            *ELECOD
            103,1,BAG,1
            Bag
            *ELECOD
            103,2,94,1
            Wood
            *ELECOD
            479, ,CO,1
            Automated Manifest Removal (354)

  8. Simple Data Element Code Explanations
  ----------------------------------------
  Tag Line: *ELENTE
  Key Line: Data Element Number, Partition Number, Code Value, 
            Paragraph Number
   Lengths: 4, 1, 6, 1
     Notes: 1) "Partition Number" is used for multi-part codes. See above.
            2) "Paragraph Number" is used when there is more than one 
            definition for any one code value. See above. 3) In this 
            workbook data element code definitions and data element code 
            explanations have a one-to-one correspondence. In future 
            workbooks, there may be multiple code explanations for a single 
            code definition.
   Example: *ELENTE
            336, ,18,1
            Sales terms specifying a past due date, and a late payment 
            percentage penalty applies to unpaid balances past this due date
            *ELENTE
            346, ,LT,1
            Used by a shipper to inform carrier that a particular load is 
            available or becoming available for movement; also signifies an 
            advance pick-up notification
            *ELENTE
            355, ,16,1
            A cylindrical container whose contents weigh 115 kilograms when 
            full

<end of readme.txt>
