# adsync.ps1
# Steven CHARRIER - http://stevencharrier.fr/
# https://github.com/Punk--Rock/Zimbra-ADSync
# Version 1.0 - 07/04/2015

$Zimbra_Hostname = "zimbra"

$username = $env:username.ToLower()
$domain = $env:userdnsdomain.ToLower()

$Accounts_file = "\\$Zimbra_Hostname.$domain\adsync\Accounts.txt"
$Mails_file = "\\$Zimbra_Hostname.$domain\adsync\Mails.txt"

$GetADUser = Get-ADUser -Filter 'SamAccountName -eq "$env:username"' -Property *
 
foreach($donnees in $GetADUser)
{
	$Surname = $donnees.Surname
	$GivenName = $donnees.GivenName
	$LogonCount = $donnees.LogonCount
	$Accounts = "$Surname" + ":" + "$GivenName" + ":" + "$username@$domain"
	$Mails = "$username@$domain"
}

if($LogonCount -lt 2)
{
	ADD-content -path $Accounts_file -value "$Accounts"
	ADD-content -path $Mails_file -value "$Mails"
}

Write-Host "Appuyez sur une touche pour continuer..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
