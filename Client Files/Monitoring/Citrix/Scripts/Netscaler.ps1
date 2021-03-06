﻿<#
This script has been tested and is working on the following versions of Citrix Netscaler:
	- 
#>

function Test-Citrix {

    Write-LauncherLog "Testing URL $SiteURL"
    Enter-Url $SiteURL

    Check-Exist -Id "login"
	Write-LauncherLog "Login page loaded successfully"

	Write-LauncherLog "Entering Username"
	Enter-Text -Id "login" -text $UserName
    
    Write-LauncherLog "Entering Password"
    Enter-Text -Id "passwd" -text $Password
   
    Write-launcherLog "Clicking Logon" 
    Click-Button -Id "Log_On" 

    Write-launcherLog "Checking for errors"
    Check-NotExist -class "error"

    Write-LauncherLog "Looking for Lite version popup..."
    Click-Button -class "button_30ql4o" -optional $true
    
    Write-LauncherLog "Clicking resource: $ResourceName"
    Click-Button -xpath "//span[@title='$ResourceName']"

    Write-LauncherLog "Waiting for resource timeout"
    start-sleep -seconds $ResourceTimeout

    Write-LauncherLog "Verifying session launched"
    Switch-Tab 2 #Change to second tab

    $Application = $Tab.Title #Get title of second tab

    if($Application -eq $ResourceName){ #Check title of second tab is same as resource
        Write-LauncherLog "Resource $ResourceName launched successfully"
    } else {
        throw "Unable to confirm session launched"
    }  

}