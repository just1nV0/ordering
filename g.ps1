$currentDir = Get-Location
if (-Not (Test-Path -Path "$currentDir\.git")) {
    Write-Host "The current directory is not a Git repository. Please navigate to a Git repository and try again."
    exit
}

do {
    Clear-Host
    Write-Host "INTAYIN MONG GAGO KA...."
    git pull
    Write-Host "MAY IPUPUSH KA BA?" -ForegroundColor Green
    $key = [System.Console]::ReadKey($true).Key
    if ($key -eq 'Escape') {
        Write-host ""
        Write-Host "Exiting script..."
        exit
    }
    $displayKey = ""
    switch ($key) {
        'D0' { $displayKey = '0' }
        'D1' { $displayKey = '1' }
        'D2' { $displayKey = '2' }
        'D3' { $displayKey = '3' }
        'D4' { $displayKey = '4' }
        'D5' { $displayKey = '5' }
        'D6' { $displayKey = '6' }
        'D7' { $displayKey = '7' }
        'D8' { $displayKey = '8' }
        'D9' { $displayKey = '9' }
        default { $displayKey = $key.ToString() }
    }
    if ($displayKey -eq '0') {
        Clear-Host
        Write-Host "Sige. kupal"
        exit
    } elseif ($displayKey -eq '1') {
        do {
            Write-Host "MAGINTAY KANG KINGINA KA...."
            Write-Host "git status..." -BackgroundColor Green
            git status
            Write-Host "IPUPUSH MONA BA?" -ForegroundColor Green
            $gitAction = [System.Console]::ReadKey($true).Key

            if ($gitAction -eq 'Escape') {
                Write-Host "Exiting script..."
                exit
            }
            $actionKey = ""
            switch ($gitAction) {
                'D1' { $actionKey = '1' }
                'D0' { $actionKey = '0' }
                default { $actionKey = $gitAction.ToString() }
            }
            if ($actionKey -eq '1') {
                $commitMessage = ""
                do {
                    $commitMessage = Read-Host "ANO PANGALAN NG COMMIT MO KUPAL? "
                    if ([string]::IsNullOrWhiteSpace($commitMessage)) {
                        Write-Host "HINDI PWEDE EMPTY COMMIT MESSAGE, TRY AGAIN!" -ForegroundColor Red
                    }
                } while ([string]::IsNullOrWhiteSpace($commitMessage))

                git add .
                git commit -m "$commitMessage"
                git push
                break 
            } elseif ($actionKey -eq '0') {
                Clear-Host
                Write-Host "Bilisan mo kase mag code kupal" -ForegroundColor Red
                break  
            } else {
                Write-Host ""
                Write-Host "AMBOBO NAMAN $($actionKey) YUNG PININDOT, 1 OR 0 LANG KASE" -ForegroundColor Red
                Write-Host "Press any key to retry..." -ForegroundColor Yellow
                [System.Console]::ReadKey($true) | Out-Null
            }
        } while ($actionKey -notin ('0', '1'))  
        break  
    } else {
        Write-Host ""
        Write-Host "AMBOBO NAMAN $($displayKey) PININDOT, 1 OR 0 LANG KASE" -ForegroundColor Red
        Write-Host "Press any key to retry..." -ForegroundColor Yellow
        [System.Console]::ReadKey($true) | Out-Null
    }
} while ($displayKey -notin ('0', '1'))
