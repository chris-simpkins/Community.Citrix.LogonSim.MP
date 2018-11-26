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
 
Import-Module (Join-Path $PSScriptRoot "Selenium.psm1")

. C:\Monitoring\Citrix\Scripts\Test-Citrix.ps1

function waitForElement($selectorType, $selector) {
    
    for($i=0; $i -le $ElementTimeout; $i++) {
        Set-Variable -Name "ElementPresent" -value $false -Scope Global
        Set-Variable -Name "Element" -Value $null -Scope Global
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

        if($Element) { 
            write-LauncherLog "Found element!"  
            Set-Variable -Name "ElementPresent" -value $true -Scope Global     
            Set-Variable -Name "Element" -Value $Element -Scope Global
            $i=$ElementTimeout
        } elseif((!$Element) -and ($i -eq $ElementTimeout)){
			Write-LauncherLog "Unable to locate element: $selector"
		}
    }
}

function Enter-Url($Url) {

    Enter-SeUrl -Driver $Driver -Url $Url

}

function Click-Button {

    param(
        [Parameter(ParameterSetName = "name")]
        $Name,
        [Parameter(ParameterSetName = "id")]
        $Id,
        [Parameter(ParameterSetName = "class")]
        $ClassName,
        [Parameter(ParameterSetName = "link")]
        $LinkText,
        [Parameter(ParameterSetName = "tag")]
        $TagName,
        [Parameter(ParameterSetName = "xpath")]
        $XPath,
        [Parameter()]
        $optional
    )

    switch ($PSCmdlet.ParameterSetName) {

        "name" { waitForElement "name" $Name }
        "id" { waitForElement "id" $Id }
        "link" { waitForElement "link" $LinkText }
        "class" { waitForElement "class" $ClassName }
        "tag" { waitForElement "tag" $TagName }
        "xpath" { waitForElement "xpath" $XPath }

    }

    if(!$Element){
        if(!$optional){
            Write-LauncherLog "Unable to find element"
            Exit 1
        }
    } else {
        Invoke-SeClick -Element $Element
    }

}

function Enter-Text {

    param(
        [Parameter(ParameterSetName = "name")]
        $Name,
        [Parameter(ParameterSetName = "id")]
        $Id,
        [Parameter(ParameterSetName = "class")]
        $ClassName,
        [Parameter(ParameterSetName = "link")]
        $LinkText,
        [Parameter(ParameterSetName = "tag")]
        $TagName,
        [Parameter(ParameterSetName = "xpath")]
        $XPath,
        [Parameter()]
        $text
    )

    switch ($PSCmdlet.ParameterSetName) {

        "name" { waitForElement "name" $Name }
        "id" { waitForElement "id" $Id }
        "link" { waitForElement "link" $LinkText }
        "class" { waitForElement "class" $ClassName }
        "tag" { waitForElement "tag" $TagName }
        "xpath" { waitForElement "xpath" $XPath }

    }

    Send-SeKeys -Element $Element -Keys $text

}

function Check-Exist {

    param(
        [Parameter(ParameterSetName = "name")]
        $Name,
        [Parameter(ParameterSetName = "id")]
        $Id,
        [Parameter(ParameterSetName = "class")]
        $ClassName,
        [Parameter(ParameterSetName = "link")]
        $LinkText,
        [Parameter(ParameterSetName = "tag")]
        $TagName,
        [Parameter(ParameterSetName = "xpath")]
        $XPath,
        [Parameter()]
        $text
    )

    switch ($PSCmdlet.ParameterSetName) {

        "name" { waitForElement "name" $Name }
        "id" { waitForElement "id" $Id }
        "link" { waitForElement "link" $LinkText }
        "class" { waitForElement "class" $ClassName }
        "tag" { waitForElement "tag" $TagName }
        "xpath" { waitForElement "xpath" $XPath }

    }

    if($ElementPresent -eq $false){
        write-launcherLog "Element was not found, aborting..."
        exit 1
    } else {
        write-launcherLog "Element found, continuing..."
    }

}

function Check-NotExist {

    param(
        [Parameter(ParameterSetName = "name")]
        $Name,
        [Parameter(ParameterSetName = "id")]
        $Id,
        [Parameter(ParameterSetName = "class")]
        $ClassName,
        [Parameter(ParameterSetName = "link")]
        $LinkText,
        [Parameter(ParameterSetName = "tag")]
        $TagName,
        [Parameter(ParameterSetName = "xpath")]
        $XPath,
        [Parameter()]
        $text
    )

    switch ($PSCmdlet.ParameterSetName) {

        "name" { waitForElement "name" $Name }
        "id" { waitForElement "id" $Id }
        "link" { waitForElement "link" $LinkText }
        "class" { waitForElement "class" $ClassName }
        "tag" { waitForElement "tag" $TagName }
        "xpath" { waitForElement "xpath" $XPath }

    }

    if($ElementPresent -eq $false){
        write-launcherLog "Element was not found, continuing..."
    } else {
        write-launcherLog "Element found, aborting..."
        exit 1
    }

}

function Switch-Tab($index) {

    $index = $($index - 1)

    Set-Variable -Name "Tab" -Value $Driver -Scope Global

    $Driver.SwitchTo().Window($Driver.WindowHandles[$index])

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
    } elseif($Browser -eq "chrome") {
        $Driver = Start-SeChrome
    } else {
        $Driver = Start-SeIe
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
