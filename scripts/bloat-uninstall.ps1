param(
    [Parameter(Mandatory = $true)]
    [string]$Target
)

function Remove-AppxGroup {
    param(
        [string[]]$NamePatterns
    )
    foreach ($pattern in $NamePatterns) {
        try {
            Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $pattern } | ForEach-Object {
                try {
                    Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
                } catch {}
            }
        } catch {}
        try {
            Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $pattern -or $_.PackageName -like $pattern } | ForEach-Object {
                try {
                    Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
                } catch {}
            }
        } catch {}
    }
}

function Disable-OptionalFeatureSafe {
    param(
        [string[]]$FeatureNames
    )
    foreach ($f in $FeatureNames) {
        try {
            Disable-WindowsOptionalFeature -Online -FeatureName $f -NoRestart -ErrorAction SilentlyContinue | Out-Null
        } catch {}
    }
}

$targetKey = $Target.ToLowerInvariant()

switch ($targetKey) {
    'onedrive' {
        Remove-AppxGroup @('Microsoft.OneDrive*')
    }
    'xbox' {
        Remove-AppxGroup @('Microsoft.Xbox*', 'Microsoft.GamingApp*')
    }
    'xboxgamebar' {
        Remove-AppxGroup @('Microsoft.XboxGamingOverlay*', 'Microsoft.XboxGameOverlay*', 'Microsoft.XboxGameCallableUI*')
    }
    'clipchamp' {
        Remove-AppxGroup @('Clipchamp.Clipchamp*')
    }
    'teamsconsumer' {
        Remove-AppxGroup @('MSTeams*', 'MicrosoftTeams*')
    }
    'mixedreality' {
        Remove-AppxGroup @('Microsoft.MixedReality.Portal*')
        Disable-OptionalFeatureSafe @('Windows-Holographic', 'Holographic-Desktop')
    }
    'fax_xps_workfolders' {
        Disable-OptionalFeatureSafe @('FaxServicesClientPackage', 'Printing-XPSServices-Features', 'WorkFolders-Client', 'XPS-Viewer')
    }
    'inboxbloat' {
        Remove-AppxGroup @(
            'Microsoft.3DBuilder*',
            'Microsoft.3DViewer*',
            'Microsoft.Bing*',
            'Microsoft.GetHelp*',
            'Microsoft.Getstarted*',
            'Microsoft.MicrosoftOfficeHub*',
            'Microsoft.MicrosoftSolitaireCollection*',
            'Microsoft.MicrosoftStickyNotes*',
            'Microsoft.MSPaint*',
            'Microsoft.Paint3D*',
            'Microsoft.People*',
            'Microsoft.SkypeApp*',
            'Microsoft.WindowsAlarms*',
            'Microsoft.WindowsCommunicationsApps*',
            'Microsoft.WindowsFeedbackHub*',
            'Microsoft.WindowsMaps*',
            'Microsoft.WindowsSoundRecorder*',
            'Microsoft.Xbox*',
            'Microsoft.ZuneMusic*',
            'Microsoft.ZuneVideo*'
        )
    }
    default {
        Write-Host "Unknown bloat uninstall target: $Target"
    }
}
