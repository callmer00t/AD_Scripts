Import-Module Activedirectory
$lockeduser=get-aduser -filter * -properties * | where {$_.lockedout} | %{$_.Samaccountname}
$userlist=@()
foreach ($user in $lockeduser)
{
$username=Get-ADUser $user -Properties *
$userobject=New-object psobject
$userobject | Add-Member -membertype noteproperty -Name Login -value $username.SamAccountName
$userobject | Add-Member -membertype noteproperty -Name User -value $username.displayname
$userobject | Add-Member -membertype noteproperty -Name Enabled -Value $username.enabled
$userobject | Add-Member -membertype noteproperty -Name Lockedout -Value $username.lockedout
$userlist+=$userobject
}
$EmailbodyHTML=$userlist|
sort-object Login |
ConvertTo-Html |
Out-String
Send-Mailmessage -from "sender@contoso.com" –to "recipient1@contoso.com","recipient2@contoso.com" -Bodyashtml $EmailbodyHTML -Subject "Email Title" -smtpserver "mail.contoso.com" -Encoding ([System.Text.Encoding]::UTF8)
