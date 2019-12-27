$DebugPreference = 'SilentlyContinue'
$VerbosePreference = "Continue"

# Retrieving management groupname 
$managementGroupName = (Get-AzManagementGroup | Where-Object { $_.DisplayName -like "Tenant Root Group" }).Name

# Retrieving policy summary state
Write-Verbose "Retrieving the policy state summary"
$PolicySummary = Get-AzPolicyStateSummary -ManagementGroupName $managementGroupName

# Checking if there are non compliant resources
Write-Verbose "Checking if there are non-compliant resources in the summary"
if($PolicySummary.NonCompliantResources -ne 0){
    Write-Verbose "Non-compliant resources found in the summary, retrieving policy assignments where there are non-compliant resources."
    $nonCompliantPolicyAssignments = @()
    $policyAssignments = $PolicySummary.PolicyAssignments
    foreach($policy in $policyAssignments){
        if($policy.Results.NonCompliantResources -ne 0 ){
            $nonCompliantPolicyAssignments += $policy
        }
    }
    $totalassignmentcount = $nonCompliantPolicyAssignments.count
}else {
    Write-Verbose "There were no non-compliant resouces found in the summary"
    break
}

# Checking if the non-compliant assignments include any deployifnotexists policy
Write-Verbose "Checking if there are deployifnotexists resources in the non-compliant assignments"
$currentassignmentcount = $null
$executedRemedationTasks = @()
foreach($nonCompliantPolicyAssignment in $nonCompliantPolicyAssignments){
    $currentassignmentcount++
    Write-Verbose "Processing policy assignment $currentassignmentcount of $totalassignmentcount"
    $deployPolicies = $nonCompliantPolicyAssignment.PolicyDefinitions | Where-Object Effect -Like "deployifnotexists" | Where-Object NonCompliantResources -ne 0
    if(!$deployPolicies){
        Write-Verbose "No deployifnotexists policy was found in the policy $($nonCompliantPolicyAssignment.PolicyAssignmentId)"
    }else {
        foreach($deployPolicy in $deployPolicies){
            Write-Verbose "Non-compliant deployifnotexists resources found. Starting remediation task for policy $($nonCompliantPolicyAssignment.PolicyAssignmentId)"
            $remediationTaskName = ("AutoRemediationTask_" + (get-date -f hhmmssddmmyyyy))
            Write-Verbose "Starting remediation task $remediationTaskName"
            # Checking if the policy reference id is empty (initiative vs regular policy assignment)
            $policyDefinitionReferenceid = $deployPolicy.PolicyDefinitionReferenceId
            if(!$policyDefinitionReferenceid){
                $policyRemediationTask = Start-AzPolicyRemediation -Name $remediationTaskName -PolicyAssignmentId $nonCompliantPolicyAssignment.PolicyAssignmentId
            }else {
                $policyRemediationTask = Start-AzPolicyRemediation -Name $remediationTaskName -PolicyAssignmentId $nonCompliantPolicyAssignment.PolicyAssignmentId -PolicyDefinitionReferenceId $deployPolicy.PolicyDefinitionReferenceId
            }
            Write-Verbose "Request for remediationtask $remediationTaskName has been executed. Current status is $($policyRemediationTask.ProvisioningState)"
            $executedRemedationTasks += $remedationTaskName
        }
    }
}
