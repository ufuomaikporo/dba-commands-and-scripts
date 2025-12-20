# Install the necessary packages for mailkit
Install-Package -Name 'MimeKit' -Source "https://www.nuget.org/api/v2" -SkipDependencies
Install-Package -Name 'MailKit' -Source "https://www.nuget.org/api/v2"
Install-Package -Name 'Portable.BouncyCastle' -Source "https://www.nuget.org/api/v2" 

# Add the paths for the dlls
Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\Portable.BouncyCastle.1.9.0\lib\net40\BouncyCastle.Crypto.dll"
Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MimeKit.3.4.1\lib\netstandard2.0\MimeKit.dll"
Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MailKit.3.4.1\lib\netstandard2.0\MailKit.dll"

# try-catch block to get more info out of error messages that may be generated
try   { Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MimeKit.3.4.1\lib\netstandard2.0\MimeKit.dll"
}
catch { $_.Exception.LoaderExceptions }

$Password = Read-Host -Prompt "Enter the password for the database user" -AsSecureString
[System.Net.NetworkCredential]::new("", $Password).Password
