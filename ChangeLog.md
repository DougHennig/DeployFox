# DeployFox

DeployFox automates the steps required to deploy your applications by providing a customizable list of tasks: copy files, rename files, build a project into an EXE, digitally sign an EXE, run an Inno Setup script to create an installer, upload files to an FTP site, and so on.

## Releases

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
