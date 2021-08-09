Import-Module Activedirectory
#$alladuser=$alladuser1,$alladuser2,$alladuser3,$alladuser4,$alladuser5,$alladuser6,$alladuser7,$alladuser8,$alladuser9,$alladuser10,$alladuser11,$alladuser12,$alladuser13,$alladuser14
$alladuser=get-aduser -searchbase "OU=Branch,DC=contoso,DC=com" -filter 'Enabled -eq $true' | %{$_.Samaccountname}
#上面的“cn=***,dc=***,dc=***,dc=***” 根据自己域结构实际情况填写
$userlist = @()
#echo $alladuser
#echo $userlist
foreach ($user in $alladuser){
#密码最后一次更改时间
$pwdlastset=Get-ADUser $user -Properties * | %{$_.passwordlastset}
#密码的过期时间
$pwdlastday=$pwdlastset.AddDays(60)
#当前时间
$now=get-date
#判断账户是否设置了永不过期
$neverexpire=get-aduser $user -Properties * |%{$_.PasswordNeverExpires}
#距离密码过期的时间
$expire_days=($pwdlastday - $now).Days
#判断过期时间天小于7天大于-7天（即已过期7天）的并且没有设置密码永不过期的账户
if($expire_days -lt 7 -and $expire_days -gt -7 -and $neverexpire -like "false"){
$chineseusername= Get-ADUser $user -Properties * | %{$_.Displayname}
#邮件正文
$Emailbody=
"亲爱的 $chineseusername :

您的域账户和邮箱密码即将在 $expire_days 天后过期， $pwdlastday 之后您将无法登录计算机和收发邮件，请您尽快更改。
重置密码过程请遵循以下原则：

• 不得再次使用近期用过的密码，禁止使用最近三次使用过的密码
• 连续五次输入密码错误将导致账户锁定 
• 请勿向他人透漏密码，也不要将密码写在纸上放在可见位置
• 密码标准：
    - 密码至少包含八位字符
    - 密码不得含有重复字符,且密码口令中不得包括全部或部分用户名
    - 密码至少由以下四种分类中的三种类型组成：
         小写字母: a, b, c, …z
         大写字母: A, B, C, …Z
         阿拉伯数字: 0,1,2,….9
         非文字或数字字符: 如 - _ ^ / # {
"
#下面的一个邮箱地址，另外一个邮箱后缀根据自己实际情况填写 smtpserver也根据自己实际情况填写
Send-MailMessage -from "sender@contoso.com" -to "$user@contoso.com" -subject "您的域账户密码即将过期,请尽快修改,谢谢" -body $Emailbody -Attachments c:\修改域账户密码方法.pdf -smtpserver "mail.contoso.com" -Encoding ([System.Text.Encoding]::UTF8)
#############################################
#查找账户的密码过期时间并发送至管理员账户
#############################################
$username=Get-ADUser $user  -Properties *
$userobject=New-object psobject
$userobject | Add-Member -membertype noteproperty -Name 用户名            -value $username.displayname
$userobject | Add-Member -membertype noteproperty -Name 邮箱              -Value $username.mail
$userobject | Add-Member -membertype noteproperty -Name 最后一次密码设置  -Value $username.Passwordlastset
$userobject | Add-Member -membertype noteproperty -Name 密码过期时间      -Value $pwdlastday
$userobject | Add-Member -membertype noteproperty -Name 距离密码过期天数  -Value $expire_days
$userlist+=$userobject
}
}
$EmailbodyHTML=$userlist|
sort-object 距离密码过期天数 |
ConvertTo-Html |
Out-String
#下面两个邮箱都可以填写为管理员的邮箱根据自己实际情况填写 smtpserver也根据自己实际情况填写
Send-Mailmessage -from  "sender@contoso.com" –to "admin1@contoso.com","admin2@contoso.com"-Bodyashtml $EmailbodyHTML -Subject "Email Title" -smtpserver maildb.contoso.com -Encoding ([System.Text.Encoding]::UTF8)