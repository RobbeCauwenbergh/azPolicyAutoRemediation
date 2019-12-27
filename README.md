# azPolicyAutoRemediation

This simple powershell script will check the current policy state and if there are policies with the "deployifnotexists" action it will automatically run a remediation task.
There are 2 versions of the script, 1 version to run locally and 1 version to run in an Azure automation runbook.

For the automation runbook you'll need the following things:
Modules installed in the automation account:
- az.resources
- az.policyinsights
- az.accounts

I was able to get it working by giving the spn the following role assignments (but it could be that there are less rights required but that's to be tested):
- Reader
- Resource Policy Contributor

> the scope of these role assignments may vary depending on your environment. If you have, like me, policy assignments on the "Tenant Root Group" management group then you should give these rights to that scope. If you only have assignments on subscription level then giving those rights on subscription level should be enough.

