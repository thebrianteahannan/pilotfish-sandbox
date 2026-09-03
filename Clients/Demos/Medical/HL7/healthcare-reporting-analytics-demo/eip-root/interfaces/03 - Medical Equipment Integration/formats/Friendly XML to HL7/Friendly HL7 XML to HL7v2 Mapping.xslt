<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="/XCSData">
    <XCSData>
      <ORU_R01_Unsolicited_transmission_of_an_observation_message>
        <MSH_Message_Header>
          <MSH.1_Field_Separator>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.1_Field_Separator" />
          </MSH.1_Field_Separator>
          <MSH.2_Encoding_Characters>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.2_Encoding_Characters" />
          </MSH.2_Encoding_Characters>
          <MSH.3_Sending_Application>
            <HD.1_Namespace_ID>
              <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.3_Sending_Application/HD.1_Namespace_ID" />
            </HD.1_Namespace_ID>
            <HD.2_Universal_ID>
              <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.3_Sending_Application/HD.2_Universal_ID" />
            </HD.2_Universal_ID>
            <HD.3_Universal_ID_Type>
              <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.3_Sending_Application/HD.3_Universal_ID_Type" />
            </HD.3_Universal_ID_Type>
          </MSH.3_Sending_Application>
          <MSH.4_Sending_Facility>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.4_Sending_Facility" />
          </MSH.4_Sending_Facility>
          <MSH.5_Receiving_Application>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.5_Receiving_Application" />
          </MSH.5_Receiving_Application>
          <MSH.6_Receiving_Facility>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.6_Receiving_Facility" />
          </MSH.6_Receiving_Facility>
          <MSH.7_Date_Time_Of_Message>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.7_Date_Time_Of_Message" />
          </MSH.7_Date_Time_Of_Message>
          <MSH.8_Security>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.8_Security" />
          </MSH.8_Security>
          <MSH.9_Message_Type>
            <MSG.1_Message_Code>
              <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.9_Message_Type/MSG.1_Message_Code" />
            </MSG.1_Message_Code>
            <MSG.2_Trigger_Event>
              <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.9_Message_Type/MSG.2_Trigger_Event" />
            </MSG.2_Trigger_Event>
            <MSG.3_Message_Structure>
              <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.9_Message_Type/MSG.3_Message_Structure" />
            </MSG.3_Message_Structure>
          </MSH.9_Message_Type>
          <MSH.10_Message_Control_ID>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.10_Message_Control_ID" />
          </MSH.10_Message_Control_ID>
          <MSH.11_Processing_ID>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.11_Processing_ID" />
          </MSH.11_Processing_ID>
          <MSH.12_Version_ID>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.12_Version_ID" />
          </MSH.12_Version_ID>
          <MSH.13_Sequence_Number>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.13_Sequence_Number" />
          </MSH.13_Sequence_Number>
          <MSH.14_Continuation_Pointer>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.14_Continuation_Pointer" />
          </MSH.14_Continuation_Pointer>
          <MSH.15_Accept_Acknowledgment_Type>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.15_Accept_Acknowledgment_Type" />
          </MSH.15_Accept_Acknowledgment_Type>
          <MSH.16_Application_Acknowledgment_Type>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.16_Application_Acknowledgment_Type" />
          </MSH.16_Application_Acknowledgment_Type>
          <MSH.17_Country_Code>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.17_Country_Code" />
          </MSH.17_Country_Code>
          <MSH.18_Character_Set>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.18_Character_Set" />
          </MSH.18_Character_Set>
          <MSH.19_Principal_Language_Of_Message>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.19_Principal_Language_Of_Message" />
          </MSH.19_Principal_Language_Of_Message>
          <MSH.20_Alternate_Character_Set_Handling_Scheme>
            <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.20_Alternate_Character_Set_Handling_Scheme" />
          </MSH.20_Alternate_Character_Set_Handling_Scheme>
          <MSH.21_Message_Profile_Identifier>
            <EI.1_Entity_Identifier>
              <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.21_Message_Profile_Identifier/EI.1_Entity_Identifier" />
            </EI.1_Entity_Identifier>
            <EI.2_Namespace_ID>
              <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.21_Message_Profile_Identifier/EI.2_Namespace_ID" />
            </EI.2_Namespace_ID>
            <EI.3_Universal_ID>
              <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.21_Message_Profile_Identifier/EI.3_Universal_ID" />
            </EI.3_Universal_ID>
            <EI.4_Universal_ID_Type>
              <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/MSH_Message_Header/MSH.21_Message_Profile_Identifier/EI.4_Universal_ID_Type" />
            </EI.4_Universal_ID_Type>
          </MSH.21_Message_Profile_Identifier>
        </MSH_Message_Header>
        <ORU_R01.PATIENT_RESULT>
          <ORU_R01.PATIENT>
            <PID_Patient_Identification>
              <PID.1_Set_ID_-_PID>
                <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.1_Set_ID_-_PID" />
              </PID.1_Set_ID_-_PID>
              <PID.2_Patient_ID>
                <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.2_Patient_ID" />
              </PID.2_Patient_ID>
              <PID.3_Patient_Identifier_List>
                <CX.1_ID_Number>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.3_Patient_Identifier_List/CX.1_ID_Number" />
                </CX.1_ID_Number>
                <CX.2_Identifier_Check_Digit>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.3_Patient_Identifier_List/CX.2_Identifier_Check_Digit" />
                </CX.2_Identifier_Check_Digit>
                <CX.3_Check_Digit_Scheme>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.3_Patient_Identifier_List/CX.3_Check_Digit_Scheme" />
                </CX.3_Check_Digit_Scheme>
                <CX.4_Assigning_Authority>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.3_Patient_Identifier_List/CX.4_Assigning_Authority" />
                </CX.4_Assigning_Authority>
                <CX.5_Identifier_Type_Code>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.3_Patient_Identifier_List/CX.5_Identifier_Type_Code" />
                </CX.5_Identifier_Type_Code>
              </PID.3_Patient_Identifier_List>
              <PID.4_Alternate_Patient_ID_-_PID>
                <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.4_Alternate_Patient_ID_-_PID" />
              </PID.4_Alternate_Patient_ID_-_PID>
              <PID.5_Patient_Name>
                <XPN.1_Family_Name>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.5_Patient_Name/XPN.1_Family_Name" />
                </XPN.1_Family_Name>
                <XPN.2_Given_Name>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.5_Patient_Name/XPN.2_Given_Name" />
                </XPN.2_Given_Name>
                <XPN.3_Second_and_Further_Given_Names_or_Initials_Thereof>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.5_Patient_Name/XPN.3_Second_and_Further_Given_Names_or_Initials_Thereof" />
                </XPN.3_Second_and_Further_Given_Names_or_Initials_Thereof>
                <XPN.4_Suffix_e.g._JR_or_III_>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.5_Patient_Name/XPN.4_Suffix_e.g._JR_or_III_" />
                </XPN.4_Suffix_e.g._JR_or_III_>
                <XPN.5_Prefix_e.g._DR_>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.5_Patient_Name/XPN.5_Prefix_e.g._DR_" />
                </XPN.5_Prefix_e.g._DR_>
                <XPN.6_Degree_e.g._MD_>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.5_Patient_Name/XPN.6_Degree_e.g._MD_" />
                </XPN.6_Degree_e.g._MD_>
                <XPN.7_Name_Type_Code>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/PID_Patient_Identification/PID.5_Patient_Name/XPN.7_Name_Type_Code" />
                </XPN.7_Name_Type_Code>
              </PID.5_Patient_Name>
            </PID_Patient_Identification>
            <ORU_R01.VISIT>
              <PV1_Patient_Visit>
                <PV1.1_Set_ID_-_PV1>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/ORU_R01.VISIT/PV1_Patient_Visit/PV1.1_Set_ID_-_PV1" />
                </PV1.1_Set_ID_-_PV1>
                <PV1.2_Patient_Class>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/ORU_R01.VISIT/PV1_Patient_Visit/PV1.2_Patient_Class" />
                </PV1.2_Patient_Class>
                <PV1.3_Assigned_Patient_Location>
                  <PL.1_Point_of_Care>
                    <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/ORU_R01.VISIT/PV1_Patient_Visit/PV1.3_Assigned_Patient_Location/PL.1_Point_of_Care" />
                  </PL.1_Point_of_Care>
                  <PL.2_Room>
                    <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/ORU_R01.VISIT/PV1_Patient_Visit/PV1.3_Assigned_Patient_Location/PL.2_Room" />
                  </PL.2_Room>
                  <PL.3_Bed>
                    <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.PATIENT/ORU_R01.VISIT/PV1_Patient_Visit/PV1.3_Assigned_Patient_Location/PL.3_Bed" />
                  </PL.3_Bed>
                </PV1.3_Assigned_Patient_Location>
              </PV1_Patient_Visit>
            </ORU_R01.VISIT>
          </ORU_R01.PATIENT>
          <ORU_R01.ORDER_OBSERVATION>
            <OBR_Observation_Request>
              <OBR.1_Set_ID_-_OBR>
                <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.1_Set_ID_-_OBR" />
              </OBR.1_Set_ID_-_OBR>
              <OBR.2_Placer_Order_Number>
                <EI.1_Entity_Identifier>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.2_Placer_Order_Number/EI.1_Entity_Identifier" />
                </EI.1_Entity_Identifier>
                <EI.2_Namespace_ID>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.2_Placer_Order_Number/EI.2_Namespace_ID" />
                </EI.2_Namespace_ID>
                <EI.3_Universal_ID>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.2_Placer_Order_Number/EI.3_Universal_ID" />
                </EI.3_Universal_ID>
                <EI.4_Universal_ID_Type>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.2_Placer_Order_Number/EI.4_Universal_ID_Type" />
                </EI.4_Universal_ID_Type>
              </OBR.2_Placer_Order_Number>
              <OBR.3_Filler_Order_Number>
                <EI.1_Entity_Identifier>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.3_Filler_Order_Number/EI.1_Entity_Identifier" />
                </EI.1_Entity_Identifier>
                <EI.2_Namespace_ID>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.3_Filler_Order_Number/EI.2_Namespace_ID" />
                </EI.2_Namespace_ID>
                <EI.3_Universal_ID>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.3_Filler_Order_Number/EI.3_Universal_ID" />
                </EI.3_Universal_ID>
                <EI.4_Universal_ID_Type>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.3_Filler_Order_Number/EI.4_Universal_ID_Type" />
                </EI.4_Universal_ID_Type>
              </OBR.3_Filler_Order_Number>
              <OBR.4_Universal_Service_ID>
                <CWE.1_Identifier>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.4_Universal_Service_ID/CWE.1_Identifier" />
                </CWE.1_Identifier>
                <CWE.2_Text>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.4_Universal_Service_ID/CWE.2_Text" />
                </CWE.2_Text>
                <CWE.3_Name_of_Coding_System>
                  <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.4_Universal_Service_ID/CWE.3_Name_of_Coding_System" />
                </CWE.3_Name_of_Coding_System>
              </OBR.4_Universal_Service_ID>
              <OBR.5_Priority-OBR>
                <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.5_Priority-OBR" />
              </OBR.5_Priority-OBR>
              <OBR.6_Requested_Date_time>
                <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.6_Requested_Date_time" />
              </OBR.6_Requested_Date_time>
              <OBR.7_Observation_Date_Time_>
                <xsl:value-of select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/OBR_Observation_Request/OBR.7_Observation_Date_Time_" />
              </OBR.7_Observation_Date_Time_>
            </OBR_Observation_Request>
            <xsl:for-each select="ORU_R01_Unsolicited_transmission_of_an_observation_message/ORU_R01.PATIENT_RESULT/ORU_R01.ORDER_OBSERVATION/ORU_R01.OBSERVATION/OBX_Observation_Result">
              <ORU_R01.OBSERVATION>
                <OBX_Observation_Result>
                  <OBX.1_Set_ID_-_OBX>
                    <xsl:value-of select="OBX.1_Set_ID_-_OBX" />
                  </OBX.1_Set_ID_-_OBX>
                  <OBX.2_Value_Type>
                    <xsl:value-of select="OBX.2_Value_Type" />
                  </OBX.2_Value_Type>
                  <OBX.3_Observation_Identifier>
                    <CWE.1_Identifier>
                      <xsl:value-of select="OBX.3_Observation_Identifier/CWE.1_Identifier" />
                    </CWE.1_Identifier>
                    <CWE.2_Text>
                      <xsl:value-of select="OBX.3_Observation_Identifier/CWE.2_Text" />
                    </CWE.2_Text>
                    <CWE.3_Name_of_Coding_System>
                      <xsl:value-of select="OBX.3_Observation_Identifier/CWE.3_Name_of_Coding_System" />
                    </CWE.3_Name_of_Coding_System>
                  </OBX.3_Observation_Identifier>
                  <OBX.4_Observation_Sub-ID>
                    <xsl:value-of select="OBX.4_Observation_Sub-ID" />
                  </OBX.4_Observation_Sub-ID>
                  <OBX.5_Observation_Value>
                    <xsl:value-of select="OBX.5_Observation_Value" />
                  </OBX.5_Observation_Value>
                  <OBX.6_Units>
                    <CWE.1_Identifier>
                      <xsl:value-of select="OBX.6_Units/CWE.1_Identifier" />
                    </CWE.1_Identifier>
                    <CWE.2_Text>
                      <xsl:value-of select="OBX.6_Units/CWE.2_Text" />
                    </CWE.2_Text>
                    <CWE.3_Name_of_Coding_System>
                      <xsl:value-of select="OBX.6_Units/CWE.3_Name_of_Coding_System" />
                    </CWE.3_Name_of_Coding_System>
                  </OBX.6_Units>
                  <OBX.7_References_Range>
                    <xsl:value-of select="OBX.7_References_Range" />
                  </OBX.7_References_Range>
                  <OBX.8_Abnormal_Flags>
                    <xsl:value-of select="OBX.8_Abnormal_Flags" />
                  </OBX.8_Abnormal_Flags>
                  <OBX.9_Probability>
                    <xsl:value-of select="OBX.9_Probability" />
                  </OBX.9_Probability>
                  <OBX.10_Nature_of_Abnormal_Test>
                    <xsl:value-of select="OBX.10_Nature_of_Abnormal_Test" />
                  </OBX.10_Nature_of_Abnormal_Test>
                  <OBX.11_Observation_Result_Status>
                    <xsl:value-of select="OBX.11_Observation_Result_Status" />
                  </OBX.11_Observation_Result_Status>
                  <OBX.12_Date_Last_Obs_Normal_Values>
                    <xsl:value-of select="OBX.12_Date_Last_Obs_Normal_Values" />
                  </OBX.12_Date_Last_Obs_Normal_Values>
                  <OBX.13_User_Defined_Access_Checks>
                    <xsl:value-of select="OBX.13_User_Defined_Access_Checks" />
                  </OBX.13_User_Defined_Access_Checks>
                  <OBX.14_Date_Time_of_the_Observation>
                    <xsl:value-of select="OBX.14_Date_Time_of_the_Observation" />
                  </OBX.14_Date_Time_of_the_Observation>
                  <OBX.15_Producer_s_ID>
                    <xsl:value-of select="OBX.15_Producer_s_ID" />
                  </OBX.15_Producer_s_ID>
                  <OBX.16_Responsible_Observer>
                    <xsl:value-of select="OBX.16_Responsible_Observer" />
                  </OBX.16_Responsible_Observer>
                  <OBX.17_Observation_Method>
                    <xsl:value-of select="OBX.17_Observation_Method" />
                  </OBX.17_Observation_Method>
                  <OBX.18_Equipment_Instance_Identifier>
                    <xsl:value-of select="OBX.18_Equipment_Instance_Identifier" />
                  </OBX.18_Equipment_Instance_Identifier>
                  <OBX.19_Date_Time_of_the_Analysis>
                    <xsl:value-of select="OBX.19_Date_Time_of_the_Analysis" />
                  </OBX.19_Date_Time_of_the_Analysis>
                  <OBX.20_Reserved_for_harmonization_with_V2.6>
                    <xsl:value-of select="OBX.20_Reserved_for_harmonization_with_V2.6" />
                  </OBX.20_Reserved_for_harmonization_with_V2.6>
                </OBX_Observation_Result>
              </ORU_R01.OBSERVATION>
            </xsl:for-each>
          </ORU_R01.ORDER_OBSERVATION>
        </ORU_R01.PATIENT_RESULT>
      </ORU_R01_Unsolicited_transmission_of_an_observation_message>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

