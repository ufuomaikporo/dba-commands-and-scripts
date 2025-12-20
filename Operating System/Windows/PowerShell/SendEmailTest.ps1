$GSender = "ufo992@gmail.com"
$GPassword = "wsjsfwdtbyzariqv"
$Recipient = $EmailSender
$MSender = "Ufuoma_Ikporo@outlook.com"
$MPassword = 'rctgznvcqrwnueld'
$Drecipient = "Ufuoma_Ikporo@dynamicrisk.net"
$DSender = $Drecipient
$Dpassword = 'BackupReport123'
$ReportDir = "C:\Users\Ufuoma_Ikporo\Documents\Backup_Reports\Monthly_Backup_Report"

 # For Gmail
#  $SMTP     = New-Object MailKit.Net.Smtp.SmtpClient
#  $Message  = New-Object MimeKit.MimeMessage
#  $TextPart = [MimeKit.TextPart]::new("plain")
#  $TextPart.Text = "This is a test."
#  $Message.From.Add($GEmailSender)
#  $Message.To.Add($DRecipient)
#  $Message.Subject = 'Test Message'
#  $Message.Body    = $TextPart
#  $SMTP.Connect('smtp.gmail.com', 587, $False)
#  $SMTP.Authenticate($GSender, $GPassword )
#  $SMTP.Send($Message)
#  $SMTP.Disconnect($true)
#  $SMTP.Dispose()

#  $SMTP = New-Object MailKit.Net.Smtp.SmtpClient
#  $Message = New-Object MimeKit.MimeMessage
#  $TextPart = [MimeKit.TextPart]::new("plain")
#  $TextPart.Text = "This is a test."
#  $Message.From.Add($MSender)
#  $Message.To.Add($DRecipient)
#  $Message.Subject = 'Test Message'
#  $Message.Body    = $TextPart
#  $Message.Priority = MimeKit.MessagePriority.Normal
#  $SMTP.Connect('smtp.outlook.com', 587, $False)
#  $SMTP.Authenticate($MSender, $MPassword )
#  $SMTP.Send($Message)
#  $SMTP.Disconnect($true)
#  $SMTP.Dispose()

# For outlook
function Send-Email {
    param ($Recipient, $SubjectLine, $Message, $EmailPriority)
    $EmailSender = "ufuoma.ikporo@gmail.com"
	$SenderPass = 'glxstlnokmlrmjuq'
	$RecipientList = @($EmailSender)

	$SMTP = New-Object MailKit.Net.Smtp.SmtpClient
    $Email = New-Object MimeKit.MimeMessage
    $Builder = New-Object MimeKit.BodyBuilder
    $TextPart = [MimeKit.TextPart]::new("plain")
    $Builder.TextBody = $Message
    $Email.From.Add($EmailSender)
	ForEach ($person in $RecipientList)
	{
		$Email.To.Add($person)
	}
    $Email.Subject = $SubjectLine
    $Email.Body = $TextPart
	$Builder.Attachments.Add("C:\Users\Ufuoma_Ikporo\Documents\Backup_Reports\Monthly_Backup_Report\SQL2012_Monthly_Backup_Report.txt")
    $Email.Body = $Builder.ToMessageBody()
    $AttachedFiles = (Get-ChildItem -Path $ReportDir | ForEach-Object {$_.FullName})
	# ForEach ($File in $AttachedFiles)
	# {
    #     $Email.Body = $Builder.ToMessageBody()
	# 	$Builder.Attachments.Add($File)
	# }
    $Email.Priority = 0
    $SMTP.Connect('smtp.gmail.com', 587, [MailKit.Security.SecureSocketOptions]::StartTls, $False)
    $SMTP.Authenticate($EmailSender, $SenderPass)
    $SMTP.Send($Email)
    $SMTP.Disconnect($true)
    $SMTP.Dispose()

    #return $AttachFiles
}

Send-Email -SubjectLine 'Test email' -$Message "This is a test" -EmailPriority 1

