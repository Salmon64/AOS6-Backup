cls
Write-Host "Welcome! You are using Salmon64 s PowerShell script to read from an Alcatel Omniswitch over IP."
Write-Host "Checking if Posh-SSH is installed..."  #It is checked below whether Posh-SSH is installed

if (Get-Module -ListAvailable -Name Posh-SSH) {
    Write-Host "Posh-SSH Module exists"
} 
else {
    Write-Host "Posh-SSH Module does not exist"
    Write-Host "internet connection requiered. Installing it now"
    Install-Module -Name Posh-SSH -RequiredVersion 3.0.8 -Force
}

Import-Module Posh-SSH #import SSH Module

#------------------CREDENTIALS------------EDIT_BY_USER-----------------------

$password = "switch" #password of the switch, default "switch"
$username =  "admin" #SSH Username of the switch , default "admin"
$Switch_IP = "192.168.2.123" #Enter your Switch IP
$revision = "false" #must stay "false" - Not yet implemented (true) for AOS 8 
$Prompt = "->" #The basic prompt character is defined here, by default "->" ; It will later be replaced by the complete prompt of the switch. For example: "->" to "test_switch ->"

#------------------COMMANDS------------EDIT_BY_USER--------------------------

#AOS Revision 6 commands, Rev. 6 Switch
# Here you can add or delete commands   syntax: 'command' separated by ","

$commandArrayOldSyntax = @('show system','show chassis','show module','show module status','show ip helper dhcp-snooping binding','show interfaces status','show mac-address-table','show arp','show lldp remote-system','write terminal','show microcode')

#------------------OUTPUT LOCATION = SCRIPT LOCATION-------------------------

$directory_save = $PSScriptRoot + "\AOS_switch\" #$PSScriptRoot is the script location
$directory_save_with_ip = $directory_save + $Switch_IP + "\"

$PathArray = @($directory_save,$directory_save_with_ip)

foreach ($item in $PathArray) {

    if (Test-Path $item) {
        # Folder exists
    }
    else {
        #Folder does not exist - create a new one
        New-Item -Path $item -ItemType Directory
    }
}

#-------------------LOGIN----------------------#DO_NOT_EDIT--------------------
#creating login creadentials
function create_login_data($username, $password){
	[ValidateNotNullOrEmpty()]$securityPassword = $password
	$securityPassword = ConvertTo-SecureString -String $securityPassword -AsPlainText -Force
	$logindata = New-Object Management.Automation.PSCredential ($username, $securityPassword)
    return $logindata
}

#open SSH session
$sshLoginData= create_login_data $username $password
$Rev6Session = New-SSHSession -ComputerName $Switch_IP -Credential $sshLoginData -AcceptKey -ConnectionTimeout 300 -Force
$Rev6Stream = $Rev6Session.Session.CreateShellStream($Switch_IP,0,0,0,0,100)
$Session_Number = Get-SSHSession | Select -ExpandProperty SessionID -First 1
echo "Info: SessionID:" $Session_Number


#check if session is correct
if($Session_Number -eq $null) {
	Write-Host -BackgroundColor Red "SESSION IS NULL, check connection -> exit script"
    Remove-SSHSession -SessionId $Global:session
    exit
	} 

#check if Alcatel Omniswitch AOS 6 or AOS 8 is used by user,  AOS8 will be added later
if ($revision -eq $false){
    Write-Host " AOS REVISION 6 COMMANDS" 

#------------find prompt----------------------------------------------------------
$find_complete_prompt += $Rev6Stream.read()
$outputLines2 = $find_complete_prompt.Split("`n") #separation with each new line
    foreach ($line2 in $outputLines2) {
        if ($line2 -match $Prompt) { #line 22
            Write-Host "complete prompt:" $line2 #-ForegroundColor red
		    $complete_Prompt = $line2
            }
    }

#-----------command execution-----------------------------------------------------

foreach ($command in $commandArrayOldSyntax) {
    #echo $command
    #store each command into .txt file
	$path_to_txt_file = $directory_save_with_ip + $command + ".txt"

    do { #stream is beeing emptied until there is no more stream
        $Rev6Stream.read() | Out-Null 
        } 
        while ($Rev6Stream.DataAvailable)

    $Rev6Stream.writeline($command) #sending command

    # to remove command line from output -> remove "#" below
    #$Rev6Stream.ReadLine() | Out-Null

    #Start-Sleep -Milliseconds 500

    while ($Rev6Stream.DataAvailable -eq $false){ #If there is no stream wait
    Write-Host "wait for stream" -ForegroundColor Yellow 
    Start-Sleep -Milliseconds 500
    } 

    $out = ''

    # read all output until there is no more
    do { 
        $out += $Rev6Stream.read()
        Write-Host $out -ForegroundColor green
        $outputLines = $out.Split("`n") #separation with each new line

        foreach ($line in $outputLines) {
            if ($line -eq "") { #If the line of the stream is empty, wait (e.g. write terminal is a slow command)
                Write-Host "line empty" -ForegroundColor DarkYellow
                Start-Sleep -Milliseconds 500
            }
            if ($line -ne $complete_Prompt) { #Check whether the line of the stream contains the correct prompt (line 22 -> line 77)
                #Write-Host "unequal" -ForegroundColor yellow
            }
            else {
            #Write-Host "equal" -ForegroundColor Green
            Write-Host "prompt recieved:" $line
            Write-Host "continue with next command"
            }
        }

        $out | Out-File -FilePath $path_to_txt_file #write into file
    
        } while ($Rev6Stream.DataAvailable)

    }
    
}

#end
Remove-SSHSession -SSHSession $Rev6Session
echo "end of the script, connection terminated : " $Rev6Session
echo "output stored under:" $directory_save_with_ip
