--Update DisplayText column in variable tables

Update Variable Set DisplayText = 'HCA/MCA Comment' where Name = 'HCA_Comment'
Update Variable Set DisplayText = 'HCA/MCA Confirm Date' where Name = 'HCA_Confirm_Date'
Update Variable Set DisplayText = 'HCA/MCA Name' where Name = 'HCA_Name'
Update Variable Set DisplayText = 'HCA/MCA Impact Radius' where Name = 'HCA_Impact_Radius'
Update Variable Set DisplayText = 'HCA/MCA Reason Code' where Name = 'HCA_Reason_Code'
Update Variable Set DisplayText = 'HCA/MCA Value' where Name = 'HCA_Value'
Update Variable Set DisplayText = 'HCA/MCA Reason Segment Id' where Name = 'HCA_Reason_Segment_Id'
Update Variable Set DisplayText = 'HCA/MCA Reasons' where Name = 'HCA_Reason'
Update Variable Set DisplayText = 'Calculated HCA/MCA Comment' where Name = 'HCA_Calculation_Comment'
Update Variable Set DisplayText = 'Calculated HCA/MCA Name' where Name = 'HCA_Calculation_Name'
Update Variable Set DisplayText = 'HCA/MCA Potential Impact Radius' where Name = 'HCA_PIR'
Update Variable Set DisplayText = 'HCA/MCA Reason Type' where Name = 'HCA_Type'
Update Variable Set DisplayText = 'HCA/MCA Segment ID' where Name = 'HCA_Segment_ID'

--Update VariableGroup table

Update VariableGroup Set Description = 'HCA/MCA Results' where Name = 'HCA Results'

--Update VariableCategory table

Update VariableCategory Set Name = 'HCA/MCA Gas Constant', Description = 'HCA/MCA Gas Constant' where Name = 'HCA Gas Constant'
Update VariableCategory Set Name = 'HCA/MCA PIR Buffer', Description = 'HCA/MCA PIR Buffer' where Name = 'HCA PIR Buffer'
Update VariableCategory Set Name = 'HCA/MCA Results', Description = 'HCA/MCA Results' where Name = 'HCA Results'
Update VariableCategory Set Name = 'HCA/MCA Area', Description = 'HCA/MCA Area' where Name = 'HCA Area'
Update VariableCategory Set Name = 'HCA/MCA Segment', Description = 'HCA/MCA Segment' where Name = 'HCA Segment'
Update VariableCategory Set Name = 'HCA/MCA Reasons', Description = 'HCA/MCA Reasons' where Name = 'HCA Reasons'
Update VariableCategory Set Name = 'HCA/MCA', Description = 'HCA/MCA' where Name = 'HCA'
Update VariableCategory Set Name = 'HCA/MCA Reason Types', Description = 'HCA/MCA Reason Types' where Name = 'HCA Reason Types'
