# Registry engine

Supported value types in `registry.set`/`registry.check`:
- DWORD -> UInt32 (`Convert-ToDword`)
- QWORD -> UInt64 (`Convert-ToQword`)
- Binary -> `byte[]` from normalized hex (`Convert-HexStringToByteArray`)
- default -> string compare

Validation uses typed compare; DWORD handles max values like `4294967295`.
