# VFPX Framework Documentation

*** TODO: discuss others: Format, FoxCryptoNG, OOP Menu

### Base classes
VFPXBaseLibrary.vcx and h (VFPXGridBuilder.prg)

### Specialty classes
- VFPXPersistentForm.vcx and SFMonitors.prg (discussed below)
- VFPXDropDownMenuButton.vcx

### Running executables
API_AppRun.prg and ExecuteCommand.prg

### File and folder operations
- FileOperation.prg and ClsHeap.prg
- OpenFile.prg
- GetProperFileCase.prg

### File dialogs
- GetFileName.prg and VFPXCommonDialog.vcx
- VFPXFileCtrls.vcx (uses GetFileName.prg and VFPXCommonDialog.vcx), builders

### Other dialogs
- GetValue.prg

### Reading from and writing to INI files
- ReadINI.prg and WriteINI.prg

### Reading from and writing to the Windows Registry
- VFPXRegistry.vcx and h and VFPXBaseLibrary.h
- why better than FFC _Registry.vcx

### Uploading and downloading files
VFPXInternet.prg

### Zipping and unzipping files
VFPXZip.prg: why not VFPCompression.fll

### Others
- SFMonitors.prg
