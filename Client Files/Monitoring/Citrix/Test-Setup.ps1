function DiscoverConfig {

    Process {
    
        $configuration = $_

        $Env:StoreFrontURL = $configuration.storeFrontUrl
        $Env:ResourceName = $configuration.resourceName
        $Env:LogFileName = $configuration.logFileName
        $Env:Browser = $configuration.browser
        $Env:TimeoutForResource = $configuration.timeoutForResource
        $Env:TimeoutForElements = $configuration.timeoutForElements
		$Env:TestScript = $configuration.testScript
        $Credentials = Get-Credential -message "Please enter credentials for citrix logon"
        $Env:Username = $Credentials.username
        $Env:Password = $Credentials.GetNetworkCredential().Password

    }

}

Write-Output "Starting script Test-Setup.ps1"

Get-Item "*.json" | Get-Content -Raw | ConvertFrom-Json | DiscoverConfig

Get-Item "*.xml" | Get-Content -Raw | ForEach-Object { [xml]$_ } | Select -ExpandProperty "Configuration" | DiscoverConfig

Get-Item "*.csv" | Get-Content -Raw | ConvertFrom-Csv | DiscoverConfig

$scriptResult = (Start-Process powershell -verb 'runas' -ArgumentList '-File',".\Scripts\Test-CitrixApp.ps1",'-LogFilePath',".\Logs",'-LogFileName',$Env:LogFileName,'-SiteURL',$Env:StoreFrontUrl,'-UserName',$Env:Username,'-Password',$Env:Password,'-ResourceName',$Env:ResourceName,'-Browser',$Env:Browser,'-ResourceTimeout',$Env:TimeoutForResource,'-ElementTimeout',$Env:TimeoutForElements,'-TestScript',$Env:TestScript -Wait -PassThru).ExitCode

Write-Output $scriptResult

if($scriptResult -eq 0){ write-output "Script ran successfully" } else { write-output "Test Script Failed, please check the logs" }
 