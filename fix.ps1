$files = @("index.html", "sach_full_anh.html")
$encoding = new-object System.Text.UTF8Encoding $false

foreach ($file in $files) {
    $html = [IO.File]::ReadAllText((Join-Path (Get-Location) $file), $encoding)
    $start = $html.IndexOf("<script>")
    $end = $html.LastIndexOf("</script>")
    
    if ($start -ge 0 -and $end -gt $start) {
        $jsName = if ($file -eq "index.html") { "app_index.js" } else { "app_sach.js" }
        
        $jsContent = $html.Substring($start + 8, $end - $start - 8)
        
        $pattern = '(?s)if \(registeredAccounts\.length === 0\) \{.*?localStorage\.setItem\(''booknest_accounts'', JSON\.stringify\(registeredAccounts\)\);\s*\}'
        
        $newUserInit = @"
        let defaultAccounts = [
            { name: "Nguyễn Văn An", phone: "0912345678", pass: "123456" },
            { name: "Trần Thị Mai", phone: "0987654321", pass: "123456" },
            { name: "toàn", phone: "toàn", pass: "12345" }
        ];

        if (registeredAccounts.length === 0) {
            registeredAccounts = defaultAccounts;
            localStorage.setItem('booknest_accounts', JSON.stringify(registeredAccounts));
        } else {
            if (!registeredAccounts.find(a => a.name === "toàn")) {
                registeredAccounts.push({ name: "toàn", phone: "toàn", pass: "12345" });
                localStorage.setItem('booknest_accounts', JSON.stringify(registeredAccounts));
            }
        }
"@
        
        if ($jsContent -match $pattern) {
            $jsContent = $jsContent -replace $pattern, $newUserInit
            Write-Host "Injected user 'toàn' into $jsName"
        } else {
            Write-Host "Warning: Could not find old user init block in $file"
        }
        
        [IO.File]::WriteAllText((Join-Path (Get-Location) $jsName), $jsContent, $encoding)
        
        $newHtml = $html.Substring(0, $start) + "`n    <script src=`"$jsName`"></script>`n" + $html.Substring($end + 9)
        
        [IO.File]::WriteAllText((Join-Path (Get-Location) $file), $newHtml, $encoding)
        
        Write-Host "Processed $file"
    }
}

