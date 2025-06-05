#below command will disable Triple DES from the server and create registry key and add value
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168"

# Check if the registry key exists
if (-not (Test-Path $regPath)) {
    # Create the registry key if it does not exist
    New-Item -Path $regPath -Force
}

# Disable the Triple DES (3DES) cipher
New-ItemProperty -Path $regPath -Name "Enabled" -Value 0 -PropertyType "DWORD" -Force

#below line of code will disable the cipher suite "TLS_RSA_WITH_3DES_EDE_CBC_SHA" from list of cipher suite
#Before and after running below script run below command to check status of the cipher suite if it is Enabled
#Get-TlsCipherSuite | findstr "TLS_RSA_WITH_3DES_EDE_CBC_SHA" 

$WeakCipherSuites = @(
"TLS_RSA_WITH_3DES_EDE_CBC_SHA"
)    

Foreach($WeakCipherSuite in $WeakCipherSuites){
    $CipherSuites = Get-TlsCipherSuite -Name $WeakCipherSuite

if($CipherSuites){
        Foreach($CipherSuite in $CipherSuites){
            Disable-TlsCipherSuite -Name $($CipherSuite.Name)
        }
    }
}

