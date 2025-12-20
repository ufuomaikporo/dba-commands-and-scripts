
$StringList = @('ANODE',
'ATMOSPHERICINSPECTION',
'BIOPROBE',
'BOND',
'CAMBIO',
'CLEANINGTOOL',
'CLEANINGTOOLRECEIVERLOC',
'COUPON',
'EQUIPMENT',
'GDB_ITEMS',
'GROUNDBED'
'HIGHIMPACTLOCATION'
'INCIDENT'
'INLINEINSPECTIONEVENT'
'KEY_AREA'
'KEY_LINES',
'NODECONNECTION',
'NODECONNECTIONFLOWDIRECTION',
'PIPELINECHEMICALBATCH',
'PIPELINECHEMICALINJECTION',
'PRESSURETEST',
'PROBE',
'RECTIFIERENCLOSURE',
'REPAIR',
'RISER',
'STATIONSERIES',
'STATIONSERIES2017',
'TANK',
'TESTPOINT',
'VALVE',
'WATERCROSSING',
'WELL',
'WELLCHEMICALBATCH',
'WELLCHEMICALINJECTION')

Get-ChildItem "C:\Users\Ufuoma_Ikporo\OneDrive - dynamicrisk.net\Scripts\Microsoft SQL Server\Working Scripts\Upstream_Client_Upgrade\Client_Script_Version6.3_Release_1.sql" |


#   where { $_ | Select-String -Pattern 'VendorEnquiry' } |
#   where { $_ | Select-String -Pattern 'Failed' } |
#   where { $_ | Select-String -Pattern 'Failed' } |
#     where { $_ | Select-String -Pattern 'Failed' } |
#       where { $_ | Select-String -Pattern 'Failed' } |
#   where { $_ | Select-String -Pattern 'Failed' } |
#     where { $_ | Select-String -Pattern 'Failed' } |
#   where { $_ | Select-String -Pattern 'Failed' } |
#     where { $_ | Select-String -Pattern 'Failed' } |
#       where { $_ | Select-String -Pattern 'Failed' } | where { $_ | Select-String -Pattern 'Failed' } |
# where { $_ | Select-String -Pattern 'Failed' } |
 