<#
This script has been tested on the following StoreWeb versions:
	- release/18.46
#>

function Test-Citrix {

    Write-LauncherLog "Testing URL $SiteURL"
    Enter-Url $SiteURL

    Check-Exist -Id "username"
	Write-LauncherLog "Login page loaded successfully"

	Write-LauncherLog "Entering Username"
	Enter-Text -Id "username" -text $UserName
    
    Write-LauncherLog "Entering Password"
    Enter-Text -Id "password" -text $Password
   
    Write-launcherLog "Clicking Logon" 
    Click-Button -Id "loginBtn" 

    Write-launcherLog "Checking for errors"
    Check-NotExist -class "error"

    Write-LauncherLog "Looking for Lite version popup..."
    Click-Button -class "button_30ql4o" -optional $true
    
    Write-LauncherLog "Clicking resource: $ResourceName"
    Click-Button -xpath "//span[@title='$ResourceName']"
	
	Write-LauncherLog "Checking resource launched" #This step may not be necessary
	Check-Exist -class "loadingIcon_11uwnfs" -optional $true
	if($exist -eq $false){
		Click-Button -xpath "//span[@title='$ResourceName']" #If not loading, click again
	}

    Write-LauncherLog "Waiting for resource timeout"
    start-sleep -seconds $ResourceTimeout

    Write-LauncherLog "Verifying session launched"
    Verify-Launched $ResourceName

}