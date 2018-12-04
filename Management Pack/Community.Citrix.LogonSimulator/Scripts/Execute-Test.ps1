param(
	$StoreFrontUrl,
	$ResourceName,
	$Domain,
	$UserName,
	$Password,
	$TestName,
	$ConfigurationPath,
	$LogFileName,
	$Browser,
	$TestScript,
	$TimeoutForResource,
	$TimeoutForElements
)

$scriptName = "Execute-Test.ps1"

# Initialise SCOM API
$api = new-object -comObject "MOM.ScriptAPI"

# Put everything in a try-catch to report errors to SCOM
try {

	# SCOM log start
	$api.LogScriptEvent($scriptName, 1000, 0, "Started")

	# Execute logon simulator script
	$scriptResult = (Start-Process powershell -verb 'runas' -ArgumentList '-File',"$ConfigurationPath\Scripts\Execute-Script.ps1",'-LogFilePath',"$ConfigurationPath\Logs",'-LogFileName',$LogFileName,'-SiteURL',$StoreFrontUrl,'-UserName',"$Domain\$UserName",'-Password',$Password,'-ResourceName',`"$ResourceName`",'-Browser',$Browser,'-ResourceTimeout',$TimeoutForResource,'-ElementTimeout',$TimeoutForElements,'-TestScript',$TestScript -Wait -PassThru).ExitCode	

	# If script fails, retry
	if($scriptResult -eq 1){ $scriptResult = (Start-Process powershell -verb 'runas' -ArgumentList '-File',"$ConfigurationPath\Scripts\Execute-Script.ps1",'-LogFilePath',"$ConfigurationPath\Logs",'-LogFileName',$LogFileName,'-SiteURL',$StoreFrontUrl,'-UserName',"$Domain\$UserName",'-Password',$Password,'-ResourceName',`"$ResourceName`",'-Browser',$Browser,'-ResourceTimeout',$TimeoutForResource,'-ElementTimeout',$TimeoutForElements,'-TestScript',$TestScript -Wait -PassThru).ExitCode }

	# Log complete
	$api.LogScriptEvent($scriptName, 1001, 0, "Finished with output: $scriptResult")

	# Interpret errors as SCOM monitor result
	if($scriptResult -eq 0) { $state = "good" } else { $state = "bad" }

	$api.LogScriptEvent($scriptName, 1001, 0, "Adding state: $state")

	# Create the SCOM "property bag"
	$pb = $api.CreatePropertyBag()

	$pb.AddValue("State", $state)

	# Write the property bag to the output        
	$pb

}
catch {
	# Top level error handling - log to SCOM
	$api.LogScriptEvent($scriptName, 1002, 2, $_.Exception.Message)
}