# FalconLibrary Layout (Canonical)

## Canonical root
All FalconLibrary tool invocations must resolve under:

- `tools/FalconLibrary/`

## Required structure

```text
tools/
  FalconLibrary/
    NSudo/
      NSudoLG.exe
    Timer Resolution/
      SetTimerResolution.exe
    DPC Checker/
      dpclat.exe
    OOshutup10/
      OOSU10.exe
    Nvidia/
      Nvidia Profile Inspector/
        nvidiaProfileInspector.exe
    Edge Remover/
      setup.exe
```

## Enforcement rules
- `falconlib.run.toolPath` values must use `tools/FalconLibrary/**`.
- Legacy prefixes are prohibited:
  - `FalconLibrary/`
  - `FalconLibrary/FalconLibrary/`
- TrustedInstaller elevation must use only:
  - `tools/FalconLibrary/NSudo/NSudoLG.exe`
