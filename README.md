# AOS6-Backup
A Powershell script to read and save the configuration of an Alcatel Omniswitch over SSH IP into .txt files as a backup.

currently supported: AOS6

planned: AOS8

usage:

first of all: check if it is allowed to execute external scripts

https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.3

the backup files are stored where the script is executed


1. start PowerShell ISE for the first time as administrator and load the script
2. customize the switch credentials according to your Alcatel Omniswitch
3. customize the commands according to your wishes
4. start the script (PowerShell ISE - keyboard F5)

Wait until the script has finished and open the location mentioned by the script



POSH SSH is used as a module and will be installed:

https://github.com/darkoperator/Posh-SSH
