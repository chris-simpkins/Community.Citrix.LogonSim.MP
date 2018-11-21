Param (
    [Parameter(Mandatory=$true,Position=0)] [string]$SiteURL,
    [Parameter(Mandatory=$true,Position=1)] [string]$UserName,
    [Parameter(Mandatory=$true,Position=2)] [string]$Password,
    [Parameter(Mandatory=$true,Position=3)] [string]$ResourceName,
    [Parameter(Mandatory=$false,Position=4)] [string]$LogFilePath = "$($env:SystemDrive)\Temp\",
    [Parameter(Mandatory=$false,Position=5)] [string]$LogFileName = "Launcher_$($UserName.Replace('\','_')).log",
    [Parameter(Mandatory=$false,Position=6)] [switch]$NoLogFile,
    [Parameter(Mandatory=$false,Position=7)] [switch]$NoConsoleOutput,
    [Parameter(Mandatory=$true,Position=8)] [string]$Browser,
    [Parameter(Mandatory=$false,Position=9)] [int]$ResourceTimeout,
    [Parameter(Mandatory=$false,Position=10)] [int]$ElementTimeout
)

Set-Variable -Name "present" -Value $false -Scope Global
 
Import-Module (Join-Path $PSScriptRoot "Selenium.psm1")

function Test-Citrix {  

    Write-LauncherLog "Testing URL $SiteURL"
    Enter-SeUrl -Driver $Driver -Url $SiteURL

    waitForElement id "username"
    Write-LauncherLog "Login page loaded successfully"

    Write-LauncherLog "Testing login"
    $Element = Find-SeElement -Driver $Driver -Id "username" 
    Invoke-SeClick -Element $Element
    Send-SeKeys -Element $Element -Keys $UserName
    $Element = Find-SeElement -Driver $Driver -Id "password"
    Send-SeKeys -Element $Element -Keys $Password
    $Element = Find-SeElement -Driver $Driver -Id "loginBtn"
    Invoke-SeClick -Element $Element

    Write-LauncherLog "Looking for Lite version popup..."
    waitForElement class "button_30ql4o"

    if($present -ne $false) {
        write-LauncherLog "Lite version popup found"
        $Element = Find-SeElement -Driver $Driver -ClassName "button_30ql4o" #This may differ on different deployments of citrix
        Invoke-SeClick -Element $Element
    }
    
    Write-LauncherLog "Waiting for resource: $ResourceName"
    waitForElement xpath "//span[@title='$ResourceName']"

    Write-LauncherLog "Getting resource: $ResourceName"
    $Element = Find-SeElement -Driver $Driver -XPath "//span[@title='$ResourceName']"

    Write-LauncherLog "Clicking resource: $ResourceName"
    Invoke-SeClick -Element $Element
    
    Write-LauncherLog "Waiting for resource timeout"
    start-sleep -seconds $ResourceTimeout

    Write-LauncherLog "Verifying session launched"
    $Driver.SwitchTo().Window($Driver.WindowHandles[1])

    $Application = $Driver.Title

    if($Application -eq $ResourceName){
        Write-LauncherLog "Resource $ResourceName launched successfully"
    } else {
        throw "Unable to confirm session launched"
    }  

}

function waitForElement($selectorType, $selector) {
    
    for($i=0; $i -le $ElementTimeout; $i++) {
        Set-Variable -Name "present" -value $false -Scope Global 
        Start-Sleep -Seconds 1
        Write-LauncherLog "$i : Waiting for element: $selector"

        switch ($selectorType) {
            "name" { $Element = Find-SeElement -Driver $Driver -Name $selector }
            "id" { $Element = Find-SeElement -Driver $Driver -Id $selector }
            "xpath" { $Element = Find-SeElement -Driver $Driver -XPath $selector}
            "tag" { $Element = Find-SeElement -Driver $Driver -TagName $selector }
            "class" { $Element = Find-SeElement -Driver $Driver -ClassName $selector }
            "link" { $Element = Find-SeElement -Driver $Driver -LinkText $selector }
        }

        if($null -ne $Element) { 
            write-LauncherLog "Found element!"  
            Set-Variable -Name "present" -value $true -Scope Global        
            $i=$ElementTimeout
        } elseif(($null -eq $Element) -and ($i -eq $ElementTimeout)){
	    Write-output "Unable to locate element: $selector"
	}
    }
}

function Switch-Tab {

    $wshell=New-Object -ComObject wscript.shell
    $wshell.SendKeys('^{PGUP}')

}

function Clear-Log {

	$LogFile = $($LogFilePath.TrimEnd('\') + "\$LogFileName")
	if(Test-Path "$LogFile" -PathType Leaf) {
        Remove-Item -Path $LogFile -Force -ErrorAction Stop | Out-Null
    }

    $ContentPath = $($LogFilePath.TrimEnd('\') + "\content.html")
    if(Test-Path "$ContentPath" -PathType Leaf) {
        Remove-Item -Path $ContentPath -Force -ErrorAction Stop | Out-Null
    }

}

function Write-LauncherHeader {

    Write-LauncherLog "SiteURL: $SiteURL"
    Write-LauncherLog "UserName: $UserName"
    Write-LauncherLog "Password: ******"
    Write-LauncherLog "ResourceName: $ResourceName"
    Write-LauncherLog "Browser: $Browser"
    Write-LauncherLog "Timeout For Resource: $ResourceTimeout"
    Write-LauncherLog "Timeout For Elements: $ElementTimeout"

}

function Write-LauncherLog {

    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] [string]$Message,
        [Parameter(Mandatory=$false)] [string]$LogFile=$($LogFilePath.TrimEnd('\') + "\$LogFileName"),
        [Parameter(Mandatory=$false)] [bool]$NoConsoleOutput=$NoConsoleOutput,
        [Parameter(Mandatory=$false)] [bool]$NoLogFile=$NoLogFile
    )
    Begin {

        if(-not (Test-Path $LogFilePath -PathType Container)) {
            New-Item $LogFilePath -Type Directory
        }

        if(Test-Path $LogFile -IsValid) {
            if(!(Test-Path "$LogFile" -PathType Leaf)) {
                New-Item -Path $LogFile -ItemType "file" -Force -ErrorAction Stop | Out-Null			
            }
        } else {
            throw "Log file path is invalid"
        }
    }
    Process {
        $Message = [DateTime]::Now.ToString("[MM/dd/yyy HH:mm:ss.fff]: ") + $Message

        if (-not $NoConsoleOutput) {
            Write-Host $Message
        }
              
        if (-not $NoLogFile) {
            $Message | Out-File -FilePath $LogFile -Append
        }
    }
}

try {

    Clear-Log

    Write-LauncherLog "*************** LAUNCHER SCRIPT BEGIN ***************"
    
    Write-LauncherHeader

    Write-LauncherLog "Opening Driver Browser"
    if($Browser -eq "firefox") {
        $Driver = Start-SeFirefox
    } elseif($Browser -eq "ie") {
        $Driver = Start-SeIe
    } else {
        $Driver = Start-SeChrome
    }
    
    Test-Citrix

}
catch {

    Write-LauncherLog "Exception caught by script"
    $_.ToString() | Write-LauncherLog
    $_.InvocationInfo.PositionMessage | Write-LauncherLog
    exit 1

}
finally {   

    if($Driver -ne $Null){
        Stop-SeDriver $Driver  
    }      

    Write-LauncherLog "***************  LAUNCHER SCRIPT END  ***************"

}

exit 0
