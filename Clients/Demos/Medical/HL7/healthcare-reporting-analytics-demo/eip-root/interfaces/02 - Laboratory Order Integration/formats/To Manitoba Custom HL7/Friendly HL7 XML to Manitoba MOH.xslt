<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSData>
      <!--test-->
      <ORM_O01_Order_message>
        <MSH_Message_header_segment>
          <MSH.1_Field_Separator>
            <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.1_Field_Separator" />
          </MSH.1_Field_Separator>
          <MSH.2_Encoding_Characters>
            <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.2_Encoding_Characters" />
          </MSH.2_Encoding_Characters>
          <MSH.3_Sending_Application>
            <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.3_Sending_Application" />
          </MSH.3_Sending_Application>
          <MSH.4_Sending_Facility>
            <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.4_Sending_Facility" />
          </MSH.4_Sending_Facility>
          <MSH.5_Receiving_Application>
            <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.5_Receiving_Application" />
          </MSH.5_Receiving_Application>
          <MSH.6_Receiving_Facility>
            <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.6_Receiving_Facility" />
          </MSH.6_Receiving_Facility>
          <MSH.7_Date_Time_Of_Message>
            <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.7_Date_Time_Of_Message" />
          </MSH.7_Date_Time_Of_Message>
          <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.8_Security" />
          <MSH.8_Security />
          <MSH.9_Message_Type>
            <CM_MSG.1_message_type>
              <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.9_Message_Type/CM_MSG.1_message_type" />
            </CM_MSG.1_message_type>
            <CM_MSG.2_trigger_event>
              <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.9_Message_Type/CM_MSG.2_trigger_event" />
            </CM_MSG.2_trigger_event>
          </MSH.9_Message_Type>
          <MSH.10_Message_Control_ID>
            <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.10_Message_Control_ID" />
          </MSH.10_Message_Control_ID>
          <MSH.11_Processing_ID>
            <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.11_Processing_ID" />
          </MSH.11_Processing_ID>
          <MSH.12_Version_ID>
            <xsl:value-of select="ORM_O01_Order_message/MSH_Message_header_segment/MSH.12_Version_ID" />
          </MSH.12_Version_ID>
        </MSH_Message_header_segment>
        <ORM_O01.PATIENT>
          <PID_Patient_identification_segment>
            <PID.1_Set_ID_-_PID>
              <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.1_Set_ID_-_PID" />
            </PID.1_Set_ID_-_PID>
            <PID.2_Patient_ID>
              <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.2_Patient_ID" />
            </PID.2_Patient_ID>
            <PID.3_Patient_Identifier_List>
              <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.3_Patient_Identifier_List" />
            </PID.3_Patient_Identifier_List>
            <PID.4_Alternate_Patient_ID_-_PID>
              <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.4_Alternate_Patient_ID_-_PID" />
            </PID.4_Alternate_Patient_ID_-_PID>
            <PID.5_Patient_Name>
              <XPN.1_family_name>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.5_Patient_Name/XPN.1_family_name" />
              </XPN.1_family_name>
              <XPN.2_given_name>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.5_Patient_Name/XPN.2_given_name" />
              </XPN.2_given_name>
              <XPN.3_middle_initial_or_name>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.5_Patient_Name/XPN.3_middle_initial_or_name" />
              </XPN.3_middle_initial_or_name>
              <XPN.4_suffix_e.g._JR_or_III_>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.5_Patient_Name/XPN.4_suffix_e.g._JR_or_III_" />
              </XPN.4_suffix_e.g._JR_or_III_>
              <XPN.5_prefix_e.g._DR_>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.5_Patient_Name/XPN.5_prefix_e.g._DR_" />
              </XPN.5_prefix_e.g._DR_>
            </PID.5_Patient_Name>
            <PID.6_Mother_s_Maiden_Name>
              <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.6_Mother_s_Maiden_Name" />
            </PID.6_Mother_s_Maiden_Name>
            <PID.7_Date_Time_of_Birth>
              <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.7_Date_Time_of_Birth" />
            </PID.7_Date_Time_of_Birth>
            <PID.8_Sex>
              <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.8_Sex" />
            </PID.8_Sex>
            <PID.9_Patient_Alias>
              <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.9_Patient_Alias" />
            </PID.9_Patient_Alias>
            <PID.10_Race>
              <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.10_Race" />
            </PID.10_Race>
            <PID.11_Patient_Address>
              <XAD.1_street_address>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.11_Patient_Address/XAD.1_street_address" />
              </XAD.1_street_address>
              <XAD.2_other_designation>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.11_Patient_Address/XAD.2_other_designation" />
              </XAD.2_other_designation>
              <XAD.3_city>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.11_Patient_Address/XAD.3_city" />
              </XAD.3_city>
              <XAD.4_state_or_province>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.11_Patient_Address/XAD.4_state_or_province" />
              </XAD.4_state_or_province>
              <XAD.5_zip_or_postal_code>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.11_Patient_Address/XAD.5_zip_or_postal_code" />
              </XAD.5_zip_or_postal_code>
              <XAD.6_country>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/PID_Patient_identification_segment/PID.11_Patient_Address/XAD.6_country" />
              </XAD.6_country>
            </PID.11_Patient_Address>
          </PID_Patient_identification_segment>
          <ORM_O01.PATIENT_VISIT>
            <PV1_Patient_visit_segment>
              <PV1.1_Set_ID_-_PV1>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.1_Set_ID_-_PV1" />
              </PV1.1_Set_ID_-_PV1>
              <PV1.2_Patient_Class>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.2_Patient_Class" />
              </PV1.2_Patient_Class>
              <PV1.3_Assigned_Patient_Location>
                <PL.1_point_of_care_ID_>
                  <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.3_Assigned_Patient_Location/PL.1_point_of_care_ID_" />
                </PL.1_point_of_care_ID_>
                <PL.2_room>
                  <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.3_Assigned_Patient_Location/PL.2_room" />
                </PL.2_room>
              </PV1.3_Assigned_Patient_Location>
              <PV1.4_Admission_Type>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.4_Admission_Type" />
              </PV1.4_Admission_Type>
              <PV1.5_Preadmit_Number>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.5_Preadmit_Number" />
              </PV1.5_Preadmit_Number>
              <PV1.6_Prior_Patient_Location>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.6_Prior_Patient_Location" />
              </PV1.6_Prior_Patient_Location>
              <PV1.7_Attending_Doctor>
                <XCN.1_ID_number_ST_>
                  <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.7_Attending_Doctor/XCN.1_ID_number_ST_" />
                </XCN.1_ID_number_ST_>
                <XCN.2_family_name>
                  <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.7_Attending_Doctor/XCN.2_family_name" />
                </XCN.2_family_name>
                <XCN.3_given_name>
                  <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.7_Attending_Doctor/XCN.3_given_name" />
                </XCN.3_given_name>
              </PV1.7_Attending_Doctor>
              <PV1.8_Referring_Doctor>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.8_Referring_Doctor" />
              </PV1.8_Referring_Doctor>
              <PV1.9_Consulting_Doctor>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.9_Consulting_Doctor" />
              </PV1.9_Consulting_Doctor>
              <PV1.10_Hospital_Service>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.10_Hospital_Service" />
              </PV1.10_Hospital_Service>
              <PV1.11_Temporary_Location>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.11_Temporary_Location" />
              </PV1.11_Temporary_Location>
              <PV1.12_Preadmit_Test_Indicator>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.12_Preadmit_Test_Indicator" />
              </PV1.12_Preadmit_Test_Indicator>
              <PV1.13_Re-admission_Indicator>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.13_Re-admission_Indicator" />
              </PV1.13_Re-admission_Indicator>
              <PV1.14_Admit_Source>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.14_Admit_Source" />
              </PV1.14_Admit_Source>
              <PV1.15_Ambulatory_Status>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.15_Ambulatory_Status" />
              </PV1.15_Ambulatory_Status>
              <PV1.16_VIP_Indicator>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.16_VIP_Indicator" />
              </PV1.16_VIP_Indicator>
              <PV1.17_Admitting_Doctor>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.17_Admitting_Doctor" />
              </PV1.17_Admitting_Doctor>
              <PV1.18_Patient_Type>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.18_Patient_Type" />
              </PV1.18_Patient_Type>
              <PV1.19_Visit_Number>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.19_Visit_Number" />
              </PV1.19_Visit_Number>
              <PV1.20_Financial_Class>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.20_Financial_Class" />
              </PV1.20_Financial_Class>
              <PV1.21_Charge_Price_Indicator>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.21_Charge_Price_Indicator" />
              </PV1.21_Charge_Price_Indicator>
              <PV1.22_Courtesy_Code>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.22_Courtesy_Code" />
              </PV1.22_Courtesy_Code>
              <PV1.23_Credit_Rating>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.23_Credit_Rating" />
              </PV1.23_Credit_Rating>
              <PV1.24_Contract_Code>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.24_Contract_Code" />
              </PV1.24_Contract_Code>
              <PV1.25_Contract_Effective_Date>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.25_Contract_Effective_Date" />
              </PV1.25_Contract_Effective_Date>
              <PV1.26_Contract_Amount>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.26_Contract_Amount" />
              </PV1.26_Contract_Amount>
              <PV1.27_Contract_Period>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.27_Contract_Period" />
              </PV1.27_Contract_Period>
              <PV1.28_Interest_Code>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.28_Interest_Code" />
              </PV1.28_Interest_Code>
              <PV1.29_Transfer_to_Bad_Debt_Code>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.29_Transfer_to_Bad_Debt_Code" />
              </PV1.29_Transfer_to_Bad_Debt_Code>
              <PV1.30_Transfer_to_Bad_Debt_Date>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.30_Transfer_to_Bad_Debt_Date" />
              </PV1.30_Transfer_to_Bad_Debt_Date>
              <PV1.31_Bad_Debt_Agency_Code>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.31_Bad_Debt_Agency_Code" />
              </PV1.31_Bad_Debt_Agency_Code>
              <PV1.32_Bad_Debt_Transfer_Amount>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.32_Bad_Debt_Transfer_Amount" />
              </PV1.32_Bad_Debt_Transfer_Amount>
              <PV1.33_Bad_Debt_Recovery_Amount>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.33_Bad_Debt_Recovery_Amount" />
              </PV1.33_Bad_Debt_Recovery_Amount>
              <PV1.34_Delete_Account_Indicator>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.34_Delete_Account_Indicator" />
              </PV1.34_Delete_Account_Indicator>
              <PV1.35_Delete_Account_Date>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.35_Delete_Account_Date" />
              </PV1.35_Delete_Account_Date>
              <PV1.36_Discharge_Disposition>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.36_Discharge_Disposition" />
              </PV1.36_Discharge_Disposition>
              <PV1.37_Discharged_to_Location>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.37_Discharged_to_Location" />
              </PV1.37_Discharged_to_Location>
              <PV1.38_Diet_Type>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.38_Diet_Type" />
              </PV1.38_Diet_Type>
              <PV1.39_Servicing_Facility>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.39_Servicing_Facility" />
              </PV1.39_Servicing_Facility>
              <PV1.40_Bed_Status>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.40_Bed_Status" />
              </PV1.40_Bed_Status>
              <PV1.41_Account_Status>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.41_Account_Status" />
              </PV1.41_Account_Status>
              <PV1.42_Pending_Location>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.42_Pending_Location" />
              </PV1.42_Pending_Location>
              <PV1.43_Prior_Temporary_Location>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.43_Prior_Temporary_Location" />
              </PV1.43_Prior_Temporary_Location>
              <PV1.44_Admit_Date_Time>
                <xsl:value-of select="ORM_O01_Order_message/ORM_O01.PATIENT/ORM_O01.PATIENT_VISIT/PV1_Patient_visit_segment/PV1.44_Admit_Date_Time" />
              </PV1.44_Admit_Date_Time>
            </PV1_Patient_visit_segment>
          </ORM_O01.PATIENT_VISIT>
        </ORM_O01.PATIENT>
        <ORM_O01.ORDER>
          <ORC_Common_order_segment>
            <ORC.1_Order_Control>
              <xsl:value-of select="ORM_O01_Order_message/ORM_O01.ORDER/ORC_Common_order_segment/ORC.1_Order_Control" />
            </ORC.1_Order_Control>
            <ORC.2_Placer_Order_Number>
              <xsl:value-of select="ORM_O01_Order_message/ORM_O01.ORDER/ORC_Common_order_segment/ORC.2_Placer_Order_Number" />
            </ORC.2_Placer_Order_Number>
          </ORC_Common_order_segment>
          <ORM_O01.ORDER_DETAIL>
            <ORM_O01.CHOICE>
              <OBR_Observation_request_segment>
                <OBR.1_Set_ID_-_OBR>
                  <xsl:value-of select="ORM_O01_Order_message/ORM_O01.ORDER/ORM_O01.ORDER_DETAIL/ORM_O01.CHOICE/OBR_Observation_request_segment/OBR.1_Set_ID_-_OBR" />
                </OBR.1_Set_ID_-_OBR>
                <OBR.2_Placer_Order_Number>
                  <xsl:value-of select="ORM_O01_Order_message/ORM_O01.ORDER/ORM_O01.ORDER_DETAIL/ORM_O01.CHOICE/OBR_Observation_request_segment/OBR.2_Placer_Order_Number" />
                </OBR.2_Placer_Order_Number>
                <OBR.3_Filler_Order_Number>
                  <xsl:value-of select="ORM_O01_Order_message/ORM_O01.ORDER/ORM_O01.ORDER_DETAIL/ORM_O01.CHOICE/OBR_Observation_request_segment/OBR.3_Filler_Order_Number" />
                </OBR.3_Filler_Order_Number>
                <OBR.4_Universal_Service_ID>
                  <CE.1_identifier>
                    <xsl:value-of select="ORM_O01_Order_message/ORM_O01.ORDER/ORM_O01.ORDER_DETAIL/ORM_O01.CHOICE/OBR_Observation_request_segment/OBR.4_Universal_Service_ID/CE.1_identifier" />
                  </CE.1_identifier>
                  <CE.2_text>
                    <xsl:value-of select="ORM_O01_Order_message/ORM_O01.ORDER/ORM_O01.ORDER_DETAIL/ORM_O01.CHOICE/OBR_Observation_request_segment/OBR.4_Universal_Service_ID/CE.2_text" />
                  </CE.2_text>
                  <CE.3_name_of_coding_system>
                    <xsl:value-of select="ORM_O01_Order_message/ORM_O01.ORDER/ORM_O01.ORDER_DETAIL/ORM_O01.CHOICE/OBR_Observation_request_segment/OBR.4_Universal_Service_ID/CE.3_name_of_coding_system" />
                  </CE.3_name_of_coding_system>
                </OBR.4_Universal_Service_ID>
                <OBR.5_Priority-OBR>
                  <xsl:value-of select="ORM_O01_Order_message/ORM_O01.ORDER/ORM_O01.ORDER_DETAIL/ORM_O01.CHOICE/OBR_Observation_request_segment/OBR.5_Priority-OBR" />
                </OBR.5_Priority-OBR>
                <OBR.6_Requested_Date_time>
                  <xsl:value-of select="ORM_O01_Order_message/ORM_O01.ORDER/ORM_O01.ORDER_DETAIL/ORM_O01.CHOICE/OBR_Observation_request_segment/OBR.6_Requested_Date_time" />
                </OBR.6_Requested_Date_time>
                <OBR.7_Observation_Date_Time_>
                  <xsl:value-of select="ORM_O01_Order_message/ORM_O01.ORDER/ORM_O01.ORDER_DETAIL/ORM_O01.CHOICE/OBR_Observation_request_segment/OBR.7_Observation_Date_Time_" />
                </OBR.7_Observation_Date_Time_>
              </OBR_Observation_request_segment>
            </ORM_O01.CHOICE>
          </ORM_O01.ORDER_DETAIL>
        </ORM_O01.ORDER>
      </ORM_O01_Order_message>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

