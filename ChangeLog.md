# DeployFox

DeployFox automates the steps required to deploy your applications by providing a customizable list of tasks: copy files, rename files, build a project into an EXE, digitally sign an EXE, run an Inno Setup script to create an installer, upload files to an FTP site, and so on.

## Releases

### 2025-12-24

* Issues with cloning a task were fixed.

* When a new project is created, the first task is active by default.

* The status bar now displays long paths properly and displays the correct path when opening a project that's a clone of another.

### 2024-10-09

* UploadFile and DownloadFile tasks no longer output the user name and password to the log file.

* The log file is no longer opened in the background on Windows 10 machines (issue #2). Note: this is actually a change in OpenFile.prg, which is part of [VFPX Framework](https://github.com/VFPX/VFPXFramework). Thanks to Joel Leach for the fix.

* FoxCryptoNG.prg was renamed to DeployFoxEncryption.prg to prevent conflict building projects that contained that program.

### 2024-08-30

* Added a Home Page link to the DeployFox dialog.

* Added a Clone Task function.

* Added a *Wait until done* setting to RunEXE and ExecutePSScript tasks.

* Added a *Log file* setting to BuildSetupInno tasks.

* Deleting tasks now renumbers other tasks.

* Fixed an issue with ReadFromINI and WriteToINI tasks not displaying the selected section and item if the INI file doesn't exist.

* Fixed an issue saving RunBat and ExecutePSScript tasks.

* DeployFox now uses ISCC rather than COMPIL32 to build a setup with Inno Setup.

* Implemented VFPX Framework 2024-08-30.

### 2024-08-18

* Added the $ProjectPath built-in variable.

* Fixed issues with the BuildSetupInno task.

* Added the Test Project folder with a test project.

* Renamed SFMenu.vcx to VFPXMenu.vcx to prevent problems building an EXE containing SFMenu.vcx (issue #1).

* Prevented an issue with a dangling datasession.

* New tasks are active by default.

### 2024-07-27

* Made it display the properties for the current task when single-stepping through tasks.

* Incomplete tasks are no longer executed.

* Signtool.exe is now included when using Thor Check for Updates to install it.

### 2024-07-21

* Initial release.
