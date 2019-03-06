$pbeJson = sfdx force:data:soql:query -q "SELECT Id, Product2.ACD_Name__c, Pricebook2.Name FROM PricebookEntry" --json | ConvertFrom-Json
$pbe = $pbeJson.result.records
$opps = (Get-Content 'data/Opportunities/Active_with_Products.json' | Out-String | ConvertFrom-Json).records
$pbeHash = @{}
$pbe | ForEach-Object -Process {$pbeHash["$($_.Product2.ACD_Name__c) - $($_.Pricebook2.Name)"] = $_.Id}

$opps | ForEach-Object -Process {
    $opp = $_
    $pbName = If ($opp.Is_Monthly__c) {"Sustainer"} Else {"One Time"}
    $opp.OpportunityLineItems.records | ForEach-Object -Process {
	$_.PricebookEntryId = $pbeHash["$($_.PricebookEntryId) - $($pbName)"]
    }
}
$opps = @{"records" = $opps}
$opps | ConvertTo-Json -Depth 100 -Compress | Out-File 'data/TempOutput.json' -Encoding ASCII
sfdx force:data:tree:import -p data/PS_Opportunity_Plan.json
Remove-Item -path data/TempOutput.json