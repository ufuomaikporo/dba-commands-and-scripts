Set-Location "C:\Users\Ufuoma_Ikporo\Documents\AccessChk"
gwmi Win32_UserProfile | foreach-object {
 $sid = New-Object System.Security.Principal.SecurityIdentifier($_.SID)
 $user = $sid.Translate([System.Security.Principal.NTAccount])
 $username = $user.Value
 $username
 #RETURN
 $chkCmd = "accesschk """ + $username + """ -a * -q"
 $chkCmd | cmd
 ""
}