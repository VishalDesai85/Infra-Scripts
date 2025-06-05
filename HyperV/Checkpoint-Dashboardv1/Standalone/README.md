
# **Hyper-V Checkpoint Dashboard Script**

## Purpose
This PowerShell script generates an HTML report detailing the checkpoints (snapshots) for Virtual Machines running on a Standalone Hyper-V Base Machine. The report provides information about the first and last snapshot creation dates and the total count of snapshots for each VM on the HyperV Host.

The script also includes logic to send this report via email.

## Prerequisites
- PowerShell 5.0 or later
- Hyper-V module installed
- SMTP server for sending emails
- Permissions to create files in the $ReportPath directory.  
- Access to an SMTP server for sending email.

## Usage
1. Save the script to a file, e.g., Save the entire script code as a .ps1 file (e.g., Generate-CheckpointReport.ps1)..
2. Open PowerShell and navigate to the directory where the script is saved.
3. Run the script using the command: `.\Generate-CheckpointReport.ps1`.

## Script Behavior
- The script creates a directory `C:\scripts\Checkpoint-Dashboard` if it does not exist.
- It generates an HTML report file named `Checkpoint_Report_<hostname>_<date>.html`.
- The report includes a table with VM name, first snapshot date, last snapshot date, and snapshot count.
- The script sends an email with the report attached to specified recipients.

## Output
- HTML report file: `Checkpoint_Report_<hostname>_<date>.html`
- Email with the report attached
- Below is the sample report
  ![image](https://github.com/user-attachments/assets/a7978468-7564-46f0-82c1-82c27df0b7bc)


## Customization
- Modify the `$ReportPath` variable to change the directory where the report is saved.
- Update the email recipients in the `Send-MailMessage` cmdlet to match your requirements.
- Customize the HTML report styling by modifying the `fWriteHTML` function.

## Batch File
- You can make use of HypervCheckpointDashboard.bat to run this powershell script via Task scheduler and configure the scheduler to run twice a day which will trigger email twice with the dashboard view of the checkpoints.
