##For Domain Joined Machines

Ensure to create a file computers.txt under folder C:\temp or any path of your choice and update computer names under computers.txt file. Only hostnames one in each line will do.
Example:
node01-2019
node02-2019
node03-2019

#Also, enter the latest Security Update patch IDs in the script below line #17, #18, #19 and #20 if applicable before you run it to get exact compliance checks done

#Enter the latest Security Patches and OOB patches against which you wish check do patch compliance check
$2016OS = ""
$2019OS = ""
$2022OS = ""
$OOB = ""

Also, if you simply wish to get compliance check based on Security Updates within the last one month, then simply hash before the below lines of code
------------------------------------------------------------------
==============================
$2016OS = ""
$2019OS = ""
$2022OS = ""
$OOB = ""
=============================
=============================

if ($hotfixeid -eq $2016OS -or $hotfixeid -eq $2019OS -or $hotfixeid -eq $2022OS -or $hotfixeid -eq $OOB) 
      {
            $PatchCompliance = "Compliant"
      } 
            else 
      {
            $PatchCompliance = "Non-Compliant, ensure you have latest Security Patch installed"
      }

=============================
And remove the hash for #$PatchCompliance = "Compliant"


--------------------------------------------------------------------

##For workgroup servers

If you are trying to execute any command from Server A to Server B, then make sure 
	1) Ensure that Windows Remote Management (WinRM) is properly configured on both the local and remote computers. This includes enabling WinRM and setting up the necessary firewall rules
        2) Basic Authentication under Service is set to "True" also  
	3) For the user account from which Invoke-command is run, you need to ensure the same user account exists on the remote server as well and with the same password or 
	4) If the passwords are different consider passing -credential <username> parameter with invoke command to prompt you for password and only then WinRM would execute successfully.

After setting the same password either on the source server or destination server, you will have to log off and login to the Source server again as previous logon session will have old passwords cached.

##Note: 
#To securely pass a username and password with Invoke-Command when targeting a workgroup server, you can use a PSCredential object. 

#Here’s how you can do it:

Create a Secure String for the Password:
----------------
$Password = "YourPassword" | ConvertTo-SecureString -AsPlainText -Force
Create the PSCredential Object:
---------------
$Username = "YourUsername"
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
---------------

Use the Credential with Invoke-Command:

Invoke-Command -ComputerName "192.168.1.100" -Credential $Credential -ScriptBlock { (Get-WmiObject win32_computersystem).Name }

#Example Script
---------------------------------
#Here’s a complete example script that securely passes the username and password:


# Convert the plain text password to a secure string
$Password = "YourPassword" | ConvertTo-SecureString -AsPlainText -Force

# Create the PSCredential object
$Username = "YourUsername"
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

# Use Invoke-Command with the credential
Invoke-Command -ComputerName "192.168.1.100" -Credential $Credential -ScriptBlock {
    (Get-WmiObject win32_computersystem).Name
}
--------------------------------

##Storing Credentials Securely
For better security, avoid hardcoding passwords in your scripts. Instead, you can store the credentials securely and retrieve them when needed:

---------------
Save the Credential to a File:

$Credential | Export-Clixml -Path "C:\Path\To\Credential.xml"
Load the Credential from the File:

$Credential = Import-Clixml -Path "C:\Path\To\Credential.xml"
--------------

#Example with Stored Credentials

--------------------------------------
Here’s how you can use stored credentials:

# Save the credential to a file (run this once)
$Password = "YourPassword" | ConvertTo-SecureString -AsPlainText -Force
$Username = "YourUsername"
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
$Credential | Export-Clixml -Path "C:\Path\To\Credential.xml"

# Load the credential from the file (use this in your script)
$Credential = Import-Clixml -Path "C:\Path\To\Credential.xml"

# Use Invoke-Command with the loaded credential
Invoke-Command -ComputerName "192.168.1.100" -Credential $Credential -ScriptBlock {
    (Get-WmiObject win32_computersystem).Name
}
---------------------------------------

This approach ensures that your credentials are stored securely and not exposed in plain text within your scripts.
