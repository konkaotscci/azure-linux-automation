﻿<#-------------Create Deployment Start------------------#>
Import-Module .\TestLibs\RDFELibs.psm1 -Force
$result = ""
$testResult = ""
$resultArr = @()

$isDeployed = DeployVMS -setupType $currentTestData.setupType -Distro $Distro -xmlConfig $xmlConfig
if ($isDeployed)
{
	try
	{
		$hs1VIP = $AllVMData.PublicIP
		$hs1vm1sshport = $AllVMData.SSHPort
		$hs1ServiceUrl = $AllVMData.URL
		$hs1vm1Dip = $AllVMData.InternalIP
		LogMsg "Trying to restart $($AllVMData.RoleName)..."
		if ( $UseAzureResourceManager )
		{
			$restartVM = Restart-AzureRmVM -ResourceGroupName $AllVMData.ResourceGroupName -Name $AllVMData.RoleName -Verbose
			if ( $restartVM.Status -eq "Succeeded" )
			{
				$isSSHOpened = isAllSSHPortsEnabledRG -AllVMDataObject $AllVMData
				if ( $isSSHOpened -eq "True" )
				{
					$isRestarted = $true
				}
				else
				{
					LogErr "VM is not available after restart"
					$isRestarted = $false
				}
			}
			else
			{
				$isRestarted = $false
				LogErr "Restart Failed. Operation ID : $($restartVM.OperationId)"
			}
		}
		else
		{
			$out = RestartAllDeployments -DeployedServices $isDeployed
			$isRestarted = $?
		}
		if ($isRestarted)
		{
			LogMsg "Virtual machine restart successful."
			$testResult = "PASS"
		}
		else
		{
			LogErr "Virtual machine restart failed."
			$testResult = "FAIL"
		}

	}

	catch
	{
		$ErrorMessage =  $_.Exception.Message
		LogMsg "EXCEPTION : $ErrorMessage"   
	}
	Finally
	{
		$metaData = ""
		if (!$testResult)
		{
			$testResult = "Aborted"
		}
		$resultArr += $testResult
#$resultSummary +=  CreateResultSummary -testResult $testResult -metaData $metaData -checkValues "PASS,FAIL,ABORTED" -testName $currentTestData.testName# if you want to publish all result then give here all test status possibilites. if you want just failed results, then give here just "FAIL". You can use any combination of PASS FAIL ABORTED and corresponding test results will be published!
	}   
}

else
{
	$testResult = "FAIL"
	$resultArr += $testResult
}

$result = GetFinalResultHeader -resultarr $resultArr

#Clean up the setup
DoTestCleanUp -result $result -testName $currentTestData.testName -deployedServices $isDeployed -ResourceGroups $isDeployed

#Return the result and summery to the test suite script..
return $result
