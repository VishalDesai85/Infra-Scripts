# **Hyper-V Checkpoint Dashboard Script**

This PowerShell script generates an HTML report detailing the checkpoints (snapshots) for Virtual Machines running on a Hyper-V Failover Cluster. The report provides information about the first and last snapshot creation dates and the total count of snapshots for each VM on each active cluster node.

The script also includes logic to send this report via email.

**Note:** This script is designed for a **Hyper-V Failover Cluster** environment. The provided script **will not work** on a standalone Hyper-V server without modifications.

## **Features**

* Connects to a Hyper-V Failover Cluster.  
* Iterates through each active node in the cluster.  
* Retrieves all Virtual Machines on each node.  
* For each VM, checks for existing checkpoints.  
* Reports the creation date of the oldest and newest checkpoint, and the total number of checkpoints.  
* Generates an HTML report file with the collected information.  
* Includes a custom message body in the report.  
* Sends the HTML report as an email with the report file attached.

## **Prerequisites**

* A Windows Server machine that is a **node in a Hyper-V Failover Cluster**.  
* PowerShell 5.1 or later (included in modern Windows Server versions).  
* The Hyper-V PowerShell module installed.  
* The FailoverClusters PowerShell module installed.  
* Appropriate permissions to query the Hyper-V cluster and its nodes (Get-Cluster, Get-ClusterNode, Get-VM, Get-VMSnapshot).  
* Permissions to create files in the $ReportPath directory.  
* Access to an SMTP server for sending email.

## **How to Use**

1. **Save the Script:** Save the entire script code as a .ps1 file (e.g., Generate-CheckpointReport.ps1).  
2. **Configure Variables:**  
   * $ReportPath: Update this variable to the desired directory where the HTML report should be saved. Ensure the user account running the script has write permissions to this path.  
   * $body: Customize the HTML content of the message body included in the report.  
   * Send-MailMessage parameters: Update the \-To, \-Cc, \-From, and \-SmtpServer parameters with your organization's email addresses and SMTP server details.  
3. **Run the Script:** Open PowerShell as an Administrator on one of the Hyper-V cluster nodes and execute the script:  
   .\\Generate-CheckpointReport.ps1

## **Script Logic Overview**

1. **Initialization:** Sets variables for the date, report path, and output file name. Imports necessary PowerShell modules (FailoverClusters, Hyper-V). Creates the output HTML file.  
2. **HTML Writing Functions:** Defines several helper functions (fWriteHTML, fWriteRole, fWriteTable, fWriteNode, fWriteVMInfo) to generate the HTML structure and content of the report.  
3. **Report Body:** Defines the $body variable containing the custom message to be included in the report.  
4. **fCreateReport Function:**  
   * Takes $Name (cluster name) and $Type ("cluster") as parameters.  
   * Retrieves active cluster nodes (Get-ClusterNode | where {$\_.state \-eq "Up"}).  
   * Loops through each active node.  
   * Retrieves VMs on the current node (Get-VM \-ComputerName).  
   * Loops through each VM.  
   * Checks if the VM has snapshots ($vmInfo.ParentSnapShotID).  
   * If snapshots exist, retrieves them, sorts by creation time, and gets the first/last date and total count.  
   * If no snapshots, sets snapshot info to "NA".  
   * Uses the HTML writing functions to add VM information to the report file.  
5. **Main Execution Block:**  
   * Calls fWriteHTML to start the HTML report structure.  
   * Checks if the server is part of a cluster using Get-Cluster.  
   * If it's a cluster node, it gets the cluster name and calls fCreateReport with the cluster name and "Cluster" type.  
   * If it's not a cluster node (based on the ElseIf (Get-Cluster) which seems logically incorrect and will never be reached if the first If is false), it outputs a message to run from a cluster node.  
6. **Emailing:** Uses Send-MailMessage to send the generated HTML file as the email body and attachment.

## **Output**

The script generates an HTML file named Checkpoint\_Report\_\<ClusterName\>\_\<YYYY-MM-DD\>.html in the directory specified by $ReportPath. This file contains the formatted report of VM checkpoint information.

The script also sends this HTML content and file via email.

## **Customization**

* Modify the HTML writing functions (fWrite...) to change the report's appearance and layout.  
* Adjust the $ReportPath variable to save the report elsewhere.  
* Edit the $body variable to change the message content in the report.  
* Update the Send-MailMessage parameters for your email environment.  
* To adapt this script for a **standalone Hyper-V server**, you would need to remove or significantly modify the parts that use Get-Cluster and Get-ClusterNode and instead iterate directly through VMs on the local machine.