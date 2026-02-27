param(
    [int]$Width  = [int]$env:FALCON_STRETCH_WIDTH,
    [int]$Height = [int]$env:FALCON_STRETCH_HEIGHT
)

if (-not $Width -or -not $Height) {
    Write-Host "No resolution provided, aborting."
    exit 1
}

Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct DEVMODE {
    private const int DM_PELSWIDTH = 0x80000;
    private const int DM_PELSHEIGHT = 0x100000;

    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
    public string dmDeviceName;
    public short dmSpecVersion;
    public short dmDriverVersion;
    public short dmSize;
    public short dmDriverExtra;
    public int dmFields;
    public int dmPositionX;
    public int dmPositionY;
    public int dmDisplayOrientation;
    public int dmDisplayFixedOutput;
    public short dmColor;
    public short dmDuplex;
    public short dmYResolution;
    public short dmTTOption;
    public short dmCollate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
    public string dmFormName;
    public short dmLogPixels;
    public int dmBitsPerPel;
    public int dmPelsWidth;
    public int dmPelsHeight;
    public int dmDisplayFlags;
    public int dmDisplayFrequency;
    public int dmICMMethod;
    public int dmICMIntent;
    public int dmMediaType;
    public int dmDitherType;
    public int dmReserved1;
    public int dmReserved2;
    public int dmPanningWidth;
    public int dmPanningHeight;
}

public class DisplayHelper {
    [DllImport("user32.dll")]
    public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    [DllImport("user32.dll")]
    public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

    public const int ENUM_CURRENT_SETTINGS = -1;
    public const int CDS_UPDATEREGISTRY = 0x01;
    public const int CDS_GLOBAL = 0x08;
    public const int DISP_CHANGE_SUCCESSFUL = 0;
}
"@

$devMode = New-Object Win32.NativeMethods+DEVMODE
$devMode.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($devMode)

$result = [Win32.NativeMethods]::EnumDisplaySettings($null, [Win32.NativeMethods]::ENUM_CURRENT_SETTINGS, [ref]$devMode)
if ($result -eq 0) {
    Write-Host "EnumDisplaySettings failed."
    exit 1
}

$devMode.dmPelsWidth  = $Width
$devMode.dmPelsHeight = $Height
$devMode.dmFields = 0x80000 -bor 0x100000  # DM_PELSWIDTH | DM_PELSHEIGHT

$change = [Win32.NativeMethods]::ChangeDisplaySettings([ref]$devMode, [Win32.NativeMethods]::CDS_UPDATEREGISTRY)
if ($change -ne [Win32.NativeMethods]::DISP_CHANGE_SUCCESSFUL) {
    Write-Host ("ChangeDisplaySettings failed with code {0}" -f $change)
    exit 1
}

Write-Host ("Desktop resolution set to {0}x{1}" -f $Width, $Height)
exit 0
