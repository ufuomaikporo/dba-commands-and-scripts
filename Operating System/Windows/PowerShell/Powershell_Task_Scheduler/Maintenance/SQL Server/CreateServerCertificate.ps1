<#
Create Server certificate with private key in the personal store for the local computer
using the computer name. This can be used as a server certificate for the SQL Server service.

1. Create a certificate with a subject that contains the FQDN of the machine
2. Export the root certificate to the 'Trusted Root Certificate Authorities' store
  under the local computer of the server and every client machine that will be connecting to the server via an 
    encrypted connection (SSL/TLS).
3. Give the database service user read access on the certificate 

--------------------- cmdlet Parameters ----------------------------------

CertStoreLocation - Specifies the certificate store in which to store the new certificate. Use Cert:\CurrentUser\My for the current user's
                    certificate store and Cert:\LocalMachine\My for the local machine's certificate store. "Cert:\LocalMachine\My" should be used
                    so you can give access to other users (such as SQL Server service) on the machine

DnsName - Specifies one or more DNS names to put into the subject alternative name extension of the certificate when a certificate to be copied is not 
          specified via the CloneCert parameter. The first name in the list must be the Servername name or server FQDN if the certificate is to be
          used by the SQL Server service otherwise you get the error "SSL provider error:0 - The target principal name is incorrect "

NotAfter - sets the expiration date. If not set, the certificate expires in 1 year
 
HashAlgorithm - Specifies the name of the hash algorithm to use to sign the new certificate (SHA-256 is recommended for its good balance 
                between security and performance). SQL Server 2016 (13.x) and earlier versions use the SHA1 algorithm. However, the SHA1 algorithm and 
                many older algorithms are deprecated beginning with SQL Server 2016. Upgrade to SQL Server 2017 (14.x) or a later version that 
                uses a stronger hash algorithm (SHA256) for self-signed certificates.

KeyAlgorithm - Specifies the name of the algorithm that creates the asymmetric keys that are associated with the new certificate.
               RSA, especially with 2048-bit keys, has long been the industry standard. ECC, particularly ECDSA, offers a good balance of security and 
               efficiency, and can achieve similar security levels with smaller key sizes. 

KeyExportPolicy - Specifies the policy for exporting the private key that is associated with the certificate. The default value of ExportableEncrypted 
                  is not compatible with KSP and CSPs that do not allow key export. These include the Microsoft Smart Card Key Storage Provider 
                  and the Microsoft Platform Crypto Key Storage Provider. Specify NonExportable for providers that do not allow key export

KeyLength - Specifies the length, in bits, of the key that is associated with the new certificate (2048 is recommended for RSA keys)


KeyLocation - Specifies the file system location where this cmdlet stores the private keys associated with the new certificate. 
              Specify this parameter only when you specify the Microsoft Platform Crypto Provider.

Provider - Specifies the name of the KSP (Key Storage Provider) or CSP (Cryptographic Service Provider) that this cmdlet uses to create the certificate.

Subject - Specifies the string that appears in the subject of the new certificate. You must use the FQDN as the subject name of
            the certificate if it is to be used by the SQL Server service for encryption.

Type - Specifies the type of certificate that this cmdlet creates.
#>
$certificateParams = @{
    Type = "SSLServerAuthentication"
    Subject = "CN=$env:COMPUTERNAME"
    DnsName = @("$($env:COMPUTERNAME)", $([System.Net.Dns]::GetHostEntry('').HostName), 'localhost')
    KeyAlgorithm = "RSA"
    KeyLength = 2048
    KeyExportPolicy = "NonExportable"
    HashAlgorithm = "SHA256"
    TextExtension = "2.5.29.37={text}1.3.6.1.5.5.7.3.1"
    NotAfter = (Get-Date).AddMonths(36)
    KeySpec = "KeyExchange"
    Provider = "Microsoft RSA SChannel Cryptographic Provider"
    CertStoreLocation = "cert:\LocalMachine\My"
}

# Call the cmdlet
New-SelfSignedCertificate @certificateParams