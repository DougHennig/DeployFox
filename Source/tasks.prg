#include DeployFox.h

define class TaskBase as Custom
	cErrorMessage = ''
		&& the text of an error
	cEncrypt      = ''
		&& a comma-delimited list of properties to encrypt

* Get the settings from XML.

	function GetSettings(tcSettings)
		local loXMLDOM, ;
			lcEncrypt, ;
			lcKey, ;
			loNodes, ;
			loNode, ;
			loPNode, ;
			lcName, ;
			lcValue, ;
			lcType, ;
			llReturn, ;
			loException as Exception
		try
			loXMLDOM = This.GetXMLParser(tcSettings)
			if vartype(loXMLDOM) = 'O'
				lcEncrypt = lower(This.cEncrypt)
				lcKey     = GetKey()
				loNodes   = loXMLDOM.selectNodes('/settings/setting')
				for each loNode in loNodes foxobject
					loPNode = loNode.selectSingleNode('name')
					lcName  = loPNode.text
					loPNode = loNode.selectSingleNode('value')
					lcValue = loPNode.text
					if lower(lcName) $ lcEncrypt and left(lcValue, 2) = '0x'
						lcValue = Decrypt(strconv(substr(lcValue, 3), 16), lcKey)
					endif lower(lcName) $ lcEncrypt ...
					lcValue = EvaluateExpression(lcValue, This)
					lcType  = upper(left(lcName, 1))
					do case
						case lcType = 'N'
							store val(lcValue) to ('This.' + lcName)
						case lcType = 'L'
							store lcValue = 'Y' to ('This.' + lcName)
						otherwise
							store lcValue to ('This.' + lcName)
					endcase
				next loNode
				llReturn = .T.
			endif vartype(loXMLDOM) = 'O'
		catch to loException
			This.cErrorMessage = Format('Error processing XML: {0}', loException.Message)
		endtry
		return llReturn
	endfunc

* Create an XML string for the settings.

	function SaveSettings
		local loXMLDOM, ;
			loRootNode, ;
			lcEncrypt, ;
			lcKey, ;
			laProperties[1], ;
			lnProperties, ;
			lnI, ;
			lcProperty, ;
			luValue, ;
			lcType, ;
			lcValue, ;
			loChildNode, ;
			loNode, ;
			loCDATA, ;
			lcSettings, ;
			loException as Exception
		try
			loXMLDOM = This.GetXMLParser()
			if vartype(loXMLDOM) = 'O'
				loRootNode = loXMLDOM.createElement('settings')
				loXMLDOM.appendChild(loRootNode)
				lcEncrypt    = lower(This.cEncrypt)
				lcKey        = GetKey()
				lnProperties = amembers(laProperties, This, 0, 'U')
				for lnI = 1 to lnProperties
					lcProperty = lower(laProperties[lnI])
					if not inlist(lcProperty, 'cerrormessage', 'cencrypt')
						luValue = evaluate('This.' + lcProperty)
						lcType  = vartype(luValue)
						do case
							case lcType = 'N'
								lcValue = transform(luValue)
							case lcType = 'L'
								lcValue = iif(luValue, 'Y', 'N')
							otherwise
								lcValue = alltrim(luValue)
						endcase
						if lower(lcProperty) $ lcEncrypt
							lcValue = '0x' + strconv(Encrypt(lcValue, lcKey), 15)
						endif lower(lcProperty) $ lcEncrypt
						loChildNode = loXMLDOM.createElement('setting')
						loRootNode.appendChild(loChildNode)
						loNode = loXMLDOM.createElement('name')
						loNode.text = lcProperty
						loChildNode.appendChild(loNode)
						loNode = loXMLDOM.createElement('value')
						if ccCR $ lcValue
							loCDATA = loXMLDOM.createCDATASection(lcValue)
							loNode.appendChild(loCDATA)
						else
							loNode.text = lcValue
						endif ccCR $ lcValue
						loChildNode.appendChild(loNode)
					endif not inlist(lcProperty ...
				next lnI
				lcSettings = loXMLDOM.xml
			endif vartype(loXMLDOM) = 'O'
		catch to loException
			lcSettings = ''
			This.cErrorMessage = Format('Error creating XML: {0}', loException.Message)
		endtry
set step on 
		return lcSettings
	endfunc

* Get an XML parser and optional load the settings as XML.

	function GetXMLParser(tcSettings)
		local loXMLDOM
		loXMLDOM = NULL
		try
			loXMLDOM = createobject('MSXML2.DOMDocument.3.0')
			loXMLDOM.async = .F.
			if vartype(loXMLDOM) = 'O' and not empty(tcSettings)
				loXMLDOM.loadXML(tcSettings)
				if loXMLDOM.parseError.errorCode <> 0
					This.cErrorMessage = Format('The following error occurred parsing ' + ;
						'the XML at position {0} of line {1}:\r\r{2}', ;
						loXMLDOM.parseError.linepos, loXMLDOM.parseError.line, ;
						loXMLDOM.parseError.reason)
					loXMLDOM = NULL
				endif loXMLDOM.parseError.errorCode <> 0
			endif vartype(loXMLDOM) = 'O' ...
		catch
			This.cErrorMessage = 'Cannot create XML parser.'
		endtry
		return loXMLDOM
	endfunc

* Execute the task (abstract in this class).

	function Execute
	endfunc
enddefine

define class RegistryBase as TaskBase
	cKey     = ''
		&& the Registry key
	cSetting = ''
		&& the setting
	nMainKey = cnHKEY_CURRENT_USER
		&& the main key
enddefine

define class WriteToRegistry as RegistryBase
	uValue = ''
		&& the value
	nType  = 0
		&& the value type

	function Execute
		local loRegistry, ;
			llReturn
		loRegistry = newobject('VFPXLibraryRegistry', 'VFPXLibraryRegistry.vcx')
		llReturn   = loRegistry.SetKey(This.cSubKey, This.cSetting, This.uValue, ;
			This.nMainKey, This.nType)
		return llReturn
	endfunc
enddefine

define class ReadFromRegistry as RegistryBase
	cVariable = ''
		&& the name of the variable to save the value to

	function Execute
		local loRegistry, ;
			luValue, ;
			llReturn
		loRegistry = newobject('VFPXLibraryRegistry', 'VFPXLibraryRegistry.vcx')
*** TODO: what default value to use?
		luValue    = loRegistry.GetKey(This.cSubKey, This.cSetting, '', ;
			This.nMainKey)
		llReturn   = loRegistry.nResult = cnSUCCESS
		if llReturn
			store luValue to (This.cVariable)
		endif llReturn
		return llReturn
	endfunc
enddefine

define class WriteToINI as TaskBase
	cSource   = ''
		&& the INI file to write to
	cSection  = ''
		&& the section to write to
	cItem     = ''
		&& the item to get the value for
	cValue    = ''
		&& the value to write

	function Execute
		local llReturn
*** TODO FUTURE: option to support encryption: need to specify key
		llReturn = WriteINI(This.cSource, This.cSection, This.cItem, This.cValue)
		return llReturn
	endfunc
enddefine

define class ReadFromINI as TaskBase
	cSource   = ''
		&& the INI file to read from
	cSection  = ''
		&& the section to read from
	cItem     = ''
		&& the item to get the value for
	cVariable = ''
		&& the name of the variable to save the value to

	function Execute
*** TODO FUTURE: option to support decryption: need to specify key
		store ReadINI(This.cSource, This.cSection, This.cItem) to (This.cVariable)
		return .T.
	endfunc
enddefine

define class UnzipFile as TaskBase
	cSource = ''
		&& the file to unzip
	cTarget = ''
		&& the folder to unzip to

	function Execute
		local llResult, ;
			loException as Exception, ;
			loShell, ;
			loFiles, ;
			lcCommand, ;
			loAPI, ;
			lcMessage

* Create the extraction if necessary.

		if not directory(This.cTarget)
			try
				md (This.cTarget)
				llResult = .T.
			catch to loException
				This.cErrorMessage = Format('Error creating {0}: {1}', ;
					This.cTarget, loException.Message)
			endtry
			if not llResult
				return .F.
			endif not llResult
		endif not directory(This.cTarget)

* Try to use Shell.Application to extract files.

		try
			loShell = createobject('Shell.Application')
			loFiles = loShell.NameSpace(This.cSource).Items
			if loFiles.Count > 0
*** TODO: delete files first or prevent prompt to overwrite them
				loShell.NameSpace(This.cTarget).CopyHere(loFiles, 16)
				llResult = .T.
			endif loFiles.Count > 0
		catch to loException
			This.cErrorMessage = Format('Error extracting from zip using ' + ;
				'Shell.Application: {0}', loException.Message)
		endtry

* If that failed, use PowerShell.

		if not llResult
*** TODO: PowerShell Expand-Archive gets cranky if the files already exist. How to know which files?
			lcCommand = 'cmd /c %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe ' + ;
				'Microsoft.Powershell.Archive\Expand-Archive ' + ;
				"-Path '" + This.cSource + "' " + ;
				"-DestinationPath '" + This.cTarget + "'"
			loAPI = newobject('API_AppRun', 'API_AppRun.prg', '', lcCommand, ;
				This.cTarget, 'HID')
			do case
				case not empty(loAPI.icErrorMessage)
					lcMessage = loAPI.icErrorMessage
				case loAPI.LaunchAppAndWait()
					llResult  = nvl(loAPI.CheckProcessExitCode(), -1) = 0
					lcMessage = evl(loAPI.icErrorMessage, 'API_AppRun failed on execution')
				otherwise
					lcMessage = loAPI.icErrorMessage
			endcase
			if not llResult
				This.cErrorMessage = lcMessage
			endif not llResult
		endif not llResult
		return llResult
	endfunc
enddefine

define class ZipFiles as TaskBase
*** TODO
enddefine

define class RenameFile as TaskBase
	cSource = ''
		&& the file to rename
	cTarget = ''
		&& what to rename it to

	function Execute
		local llReturn, ;
			loException as Exception
		do case
			case file(This.cSource)
				try
					if file(This.cTarget)
						erase (This.cTarget)
					endif file(This.cTarget)
					rename (This.cSource) to (This.cTarget)
					llReturn = .T.
				catch to loException
					This.cErrorMessage = Format('Cannot rename {0} to {1}: ' + ;
						'{2}', This.cSource, This.cTarget, loException.Message)
				endtry
			case file(This.cTarget)
				llReturn = .T.
				&& the file was previously renamed so no problem
			otherwise
				This.cErrorMessage = Format('Source file {0} does not exist.', This.cSource)
		endcase
		return llReturn
	endfunc
enddefine

define class DeleteFile as TaskBase
	cSource = ''
		&& the file to delete

	function Execute
		local llReturn, ;
			loException as Exception
		if file(This.cSource)
			try
				erase (This.cSource)
				llReturn = .T.
			catch to loException
				This.cErrorMessage = Format('Cannot delete file {0}', This.cSource)
			endtry
		else
			llReturn = .T.
		endif file(This.cSource)
		return llReturn
	endfunc
enddefine

define class CopyFile as TaskBase
	cSource = ''
		&& the file(s) to copy
	cTarget = ''
		&& the path to copy to

	function Execute
		local llReturn
		llReturn = FileOperation(This.cSource, This.cTarget, 'copy')
		return llReturn
	endfunc
enddefine

define class DeleteFolder as TaskBase
	cSource = ''
		&& the folder to delete

	function Execute
		local llReturn
		if directory(This.cSource)
			llReturn = FileOperation(This.cSource, '', 'DELETE')
			if not llReturn
				This.cErrorMessage = Format('Cannot delete folder {0}', This.cSource)
			endif not llReturn
		else
			llReturn = .T.
		endif directory(This.cSource)
		return llReturn
	endfunc
enddefine

define class RunEXE as TaskBase
	cSource     = ''
		&& the EXE to run
	cParameters = ''
		&& the parameters to pass to it
*** TODO: for debugging, probably want NOR
	cWindowMode = 'HID'
		&& the window mode
*** TODO: option to wait until done or not

	function Execute
		local lcSource, ;
			lcCommand, ;
			loAPI, ;
			lcMessage, ;
			llResult
		lcSource  = EvaluateExpression(This.cSource, This)
		lcCommand = '"' + lcSource + '"' + ;
			icase(empty(This.cParameters), '', ;
				'"' $ This.cParameters, ' ' + This.cParameters, ;
				' "' + This.cParameters + '"')
*** TODO: add logging: command being executed
		loAPI     = newobject('API_AppRun', 'API_AppRun.prg', '', lcCommand, ;
			justpath(fullpath(lcSource)), This.cWindowMode)
		do case
			case not empty(loAPI.icErrorMessage)
				lcMessage = loAPI.icErrorMessage
*** TODO: problem: SQConfig doesn't terminate
			case loAPI.LaunchAppAndWait()
				llResult  = nvl(loAPI.CheckProcessExitCode(), -1) = 0
				lcMessage = evl(loAPI.icErrorMessage, 'API_AppRun failed on execution')
			otherwise
				lcMessage = loAPI.icErrorMessage
		endcase
		if not llResult
			This.cErrorMessage = lcMessage
		endif not llResult
		return llResult
	endfunc
enddefine

define class SignTool as RunEXE
	cSource      = '{SignEXE}'
	cDescription = ''
		&& the description for the EXE
	cTarget      = ''
		&& the EXE to sign

	function GetSettings(tcSettings)
		local llReturn, ;
			lcParameters
		llReturn = dodefault(tcSettings)
		if llReturn
			lcParameters     = EvaluateExpression('{SignCommand}', This)
			lcParameters     = substr(lcParameters, at(' sign ', lcParameters))
			lcParameters     = strtran(lcParameters, '$q', '"')
			This.cParameters = strtran(lcParameters, '$p') + ' /d "' + This.cDescription + '" "' + This.cTarget + '"'
		endif llReturn
	endfunc
enddefine

define class BuildSetupInno as RunEXE
	cSource     = '{BuildEXE}'
	cScriptFile = ''

	function GetSettings(tcSettings)
		local llReturn
		llReturn = dodefault(tcSettings)
		if llReturn
			This.cParameters = '"' + EvaluateExpression(SignCommand, This) + '" "' + This.cScriptFile + '"'
		endif llReturn
	endfunc
enddefine

define class RunPRG as TaskBase
	cSource     = ''
		&& the PRG to run
	cParameters = ''
		&& the parameters to pass to it

	function Execute
		local lcCurrPath, ;
			lcPath, ;
			lcParameters, ;
			llReturn, ;
			loException as Exception
		lcCurrPath = sys(5) + curdir()
		lcPath     = justpath(This.cSource)
		try
			cd (lcPath)
			if empty(This.cParameters)
				do (This.cSource)
			else
				lcParameters = This.cParameters
				do (This.cSource) with &lcParameters
			endif empty(This.cParameters)
			llReturn = .T.
		catch to loException
			This.cErrorMessage = Format('Error running {0}: {1}', This.cSource, ;
				loException.Message)
		finally
			cd (lcCurrPath)
		endtry
		return llReturn
	endfunc
enddefine

define class ExecuteScript as TaskBase
	cCode = ''
		&& the code to execute

	function xxGetSettings(tcSettings)
		local loXMLDOM, ;
			loNode, ;
			llReturn, ;
			loException as Exception
		try
			loXMLDOM = This.GetXMLParser(tcSettings)
			if vartype(loXMLDOM) = 'O'
				loNode = loXMLDOM.selectSingleNode('/settings/script')
				This.cCode = loNode.text
				llReturn = .T.
			endif vartype(loXMLDOM) = 'O'
		catch to loException
			This.cErrorMessage = Format('Error processing XML: {0}', ;
				loException.Message)
		endtry
		return llReturn
	endfunc

	function Execute
		local llReturn, ;
			loException as Exception
		try
			execscript(This.ccCode)
			llReturn = .T.
		catch to loException
			This.cErrorMessage = Format('Error running script: {0}', ;
				loException.Message)
		endtry
		return llReturn
	endfunc
enddefine

define class BuildEXE as TaskBase
	cSource    = ''
		&& the project to build
	cTarget    = ''
		&& the EXE to create
	lRecompile = .F.
		&& .T. to recompile

	function Execute
		local lcRecompile, ;
			llReturn, ;
			loException as Exception
		try
			erase (This.cTarget)
			lcRecompile = iif(This.lRecompile, 'recompile', '')
			build exe (This.cTarget) from (This.cSource) &lcRecompile
			llReturn = file(This.cTarget)
		catch to loException
			This.cErrorMessage = Format('Cannot build {0} from {1}: {2}', This.cTarget, ;
				This.cSource, loException.Message)
		endtry
		return llReturn
	endfunc
enddefine

define class DownloadFile as RunEXE
	cSource     = 'curl.exe'
	cRemoteFile = ''
		&& the file to upload to
	cLocalFile  = ''
		&& the file to upload
	cUserName   = ''
		&& the user name to connect to the server
	cPassword   = ''
		&& the password to connect to the server
	cEncrypt    = 'cPassword'

	function Execute
		local llReturn
		This.cParameters = '-o "' + This.cLocalFile + '" ' + This.cRemoteFile + ;
			iif(empty(This.cUserName), '', ' -u ' + This.cUserName + ':' + This.cPassword)
		llReturn = dodefault()
		return llReturn
	endfunc
enddefine

define class UploadFile as RunEXE
	cSource     = 'curl.exe'
	cRemoteFile = ''
		&& the file to upload to
	cLocalFile  = ''
		&& the file to upload
	cServer     = ''
		&& the server
	cUserName   = ''
		&& the user name to connect to the server
	cPassword   = ''
		&& the password to connect to the server
	cEncrypt    = 'cPassword'

	function Execute
		local llReturn
		This.cParameters = '-T "' + This.cLocalFile + ;
			'" ftp://' + This.cServer + This.cRemoteFile + ;
			' -u ' + This.cUserName + ':' + This.cPassword
		llReturn = dodefault()
		return llReturn
	endfunc
enddefine

define class SetVariable as TaskBase
	cVariable = ''
		&& the name of the variable
	cValue    = ''
		&& the value
	lEncrypt  = .F.
		&& .T. to encrypt the value
*** TODO: need data type so can convert

* Flag that we're encrypting cValue if necessary.

	function lEncrypt_Assign(tlValue)
		This.lEncrypt = tlValue
		This.cEncrypt = iif(tlValue, 'cValue', '')
	endfunc

* If we're encrypting the value, read the settings again so we decrypt it this time.

	function GetSettings(tcSettings)
		llReturn = dodefault(tcSettings)
		if This.lEncrypt
			llReturn = dodefault(tcSettings)
		endif This.lEncrypt
		return llReturn
	endfunc

	function Execute
		local lcVariable, ;
			luValue
		lcVariable = This.cVariable
*** TODO: no public vars: in expressions, use $VariableName. Then in GetSettings, change to VarHolderObject.VariableName???
		release &lcVariable
		public &lcVariable
		luValue = EvaluateExpression(This.cValue, This)
		store luValue to (lcVariable)
	endfunc
enddefine

define class ReplaceInFile as TaskBase
*** TODO
enddefine

define class WriteToFile as TaskBase
	cSource    = ''
		&& the text to write
	cTarget    = ''
		&& the file to write to
	lOverwrite = .F.
		&& .T. to overwrite the file, .F. to append

	function Execute
		local llReturn, ;
			loException as Exception
		try
			strtofile(This.cSource, This.cTarget, This.lOverwrite)
			llReturn = .T.
		catch to loException
			This.cErrorMessage = Format('Error writing to {0}: {1}', This.cTarget, ;
				loException.Message)
		endtry
		return llReturn
	endfunc
enddefine
