#include DeployFox.h

define class TaskBase as Session
	DataSession   = 2
		&& run in a private datasession
	cErrorMessage = ''
		&& the text of an error
	cEncrypt      = ''
		&& a comma-delimited list of properties to encrypt
	cLogFile      = ''
		&& the path of a file to log to
	cName         = ''
		&& the name of the task
	lDebugMode    = .F.
		&& .T. to run in debug mode
	oEncrypt      = .NULL.
		&& a reference to a FoxCryptoNG object
	oVariables    = .NULL.
		&& a reference to an object containing variables
*** Note: when new properties are added, include them in INLIST statement in SaveSettings

	function Init(toVariables)
		This.oVariables = toVariables
		This.oEncrypt   = newobject('foxCryptoNG', 'foxCryptoNG.prg')
	endfunc

* Get the settings from XML.

	function GetSettings(tcSettings, tlNoExpandVariables)
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
						lcValue = trim(This.oEncrypt.Decrypt_AES(strconv(substr(lcValue, 3), 16), lcKey))
					endif lower(lcName) $ lcEncrypt ...
					if not tlNoExpandVariables
						lcValue = EvaluateExpression(lcValue, This)
					endif not tlNoExpandVariables
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
			This.Log(Format('Error getting settings: {0}', This.cErrorMessage))
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
					if not inlist(lcProperty, 'cerrormessage', 'cencrypt', ;
						'clogfile', 'cname', 'ldebugmode', 'oencrypt', 'ovariables')
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
							lcValue = '0x' + strconv(This.oEncrypt.Encrypt_AES(lcValue, lcKey), 15)
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
			This.Log(Format('Error saving settings: {0}', This.cErrorMessage))
		endtry
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
			This.Log(This.cErrorMessage)
		endtry
		return loXMLDOM
	endfunc

* Execute the task (abstract in this class).

	function Execute
	endfunc

* Log the results.

	function Log(tcMessage, tlAppend)
		if not empty(This.cLogFile)
			try
				if tlAppend
					strtofile(Format('{0}\r\n', tcMessage), This.cLogFile, .T.)
				else
					strtofile(Format('{0}: {1} ({2}) - {3}\r\n', datetime(), ;
						This.cName, This.Name, tcMessage), This.cLogFile, .T.)
				endif tlAppend
			catch
			endtry
		endif not empty(This.cLogFile)
	endfunc
enddefine

define class RegistryBaseTask as TaskBase
	cKey     = ''
		&& the Registry key
	cSetting = ''
		&& the setting
	nMainKey = cnHKEY_CURRENT_USER
		&& the main key

	function GetMainKeyName
		local lcName
		do case
			case This.nMainKey = cnHKEY_CLASSES_ROOT
				lcName = 'HKEY_CLASSES_ROOT'
			case This.nMainKey = cnHKEY_CURRENT_USER
				lcName = 'HKEY_CURRENT_USER'
			case This.nMainKey = cnHKEY_LOCAL_MACHINE
				lcName = 'HKEY_LOCAL_MACHINE'
		endcase
		return lcName
	endfunc
enddefine

define class WriteToRegistry as RegistryBaseTask
	uValue = ''
		&& the value
	nType  = 0
		&& the value type

	function Execute
		local loRegistry, ;
			llReturn, ;
			lcKey
		loRegistry = newobject('VFPXRegistry', 'VFPXRegistry.vcx')
		llReturn   = loRegistry.SetKey(This.cKey, This.cSetting, This.uValue, ;
			This.nMainKey, This.nType)
		lcKey      = This.GetMainKeyName() + '\' + This.cKey
		if llReturn
			This.Log(Format('"{0}" written to Windows Registry at {1} of {2}', ;
				This.uValue, This.cSetting, lcKey))
		else
			This.Log(Format('Failed to write "{0}" to Windows Registry at {1} of {2}', ;
				This.uValue, This.cSetting, lcKey))
		endif llReturn
		return llReturn
	endfunc
enddefine

define class ReadFromRegistry as RegistryBaseTask
	cVariable = ''
		&& the name of the variable to save the value to

	function Execute
		local loRegistry, ;
			luValue, ;
			llReturn, ;
			lcKey, ;
			loVariable
		loRegistry = newobject('VFPXRegistry', 'VFPXRegistry.vcx')
		luValue    = loRegistry.GetKey(This.cKey, This.cSetting, '', ;
			This.nMainKey)
		llReturn   = loRegistry.nResult = cnSUCCESS
		lcKey      = This.GetMainKeyName() + '\' + This.cKey
		if llReturn
			loVariable = This.oVariables.Item(This.cVariable)
			loVariable.Value = luValue
			This.Log(Format('"{0}" read from Windows Registry at {1} of {2}', ;
				luValue, This.cSetting, lcKey))
		else
			This.Log(Format('Failed to read from Windows Registry at {0} of {1}', ;
				This.cSetting, lcKey))
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
		if llReturn
			This.Log(Format('"{0}" written to {1} of [{2}] of {3}', ;
				This.cValue, This.cItem, This.cSection, This.cSource))
		else
			This.Log(Format('Failed to write "{0}" to {1} of [{2}] of {3}', ;
				This.cValue, This.cItem, This.cSection, This.cSource))
		endif llReturn
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
		local loVariable, ;
			llReturn
		if file(This.cSource)
*** TODO FUTURE: option to support decryption: need to specify key
			loVariable = This.oVariables.Item(This.cVariable)
			loVariable.Value = ReadINI(This.cSource, This.cSection, This.cItem)
			llReturn = .T.
			This.Log(Format('"{0}" read from {1} of [{2}] of {3}', ;
				loVariable.Value, This.cItem, This.cSection, This.cSource))
		else
			This.cErrorMessage = Format('{0} does not exist', This.cSource)
			This.Log(This.cErrorMessage)
		endif file(This.cSource)
		return llReturn
	endfunc
enddefine

define class UnzipFile as TaskBase
	cSource = ''
		&& the file to unzip
	cTarget = ''
		&& the folder to unzip to

	function Execute
		local loZip, ;
			llResult
		loZip    = newobject('VFPXZip', 'VFPXZip.prg')
		loZip.cWindowMode = iif(This.lDebugMode, 'NOR', 'HID')
		llResult = loZip.Unzip(This.cSource, This.cTarget)
		if llResult
			This.Log(Format('{0} unzipped to {1}', This.cSource, This.cTarget))
		else
			This.cErrorMessage = loZip.cErrorMessage
			This.Log(This.cErrorMessage)
		endif llResult
		return llResult
	endfunc
enddefine

define class ZipFiles as TaskBase
	cSource = ''
		&& a carriage return or comma-delimited list of files to zip
	cTarget = ''
		&& the ZIP file
	nUpdate = 1
		&& 1 = create new file, 2 = update existing file

	function Execute
		local loZip, ;
			llResult
		loZip    = newobject('VFPXZip', 'VFPXZip.prg')
		loZip.cWindowMode = iif(This.lDebugMode, 'NOR', 'HID')
		llResult = loZip.Zip(This.cSource, This.cTarget, This.nUpdate = 1)
		if llResult
			This.Log(Format('{0} unzipped to {1}', strtran(This.cSource, ccCR, ','), This.cTarget))
		else
			This.cErrorMessage = loZip.cErrorMessage
			This.Log(This.cErrorMessage)
		endif llResult
		return llResult
	endfunc
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
					This.Log(Format('{0} renamed to {1}', This.cSource, This.cTarget))
				catch to loException
					This.cErrorMessage = Format('Cannot rename {0} to {1}: ' + ;
						'{2}', This.cSource, This.cTarget, loException.Message)
					This.Log(This.cErrorMessage)
				endtry
			case file(This.cTarget)
				llReturn = .T.
				&& the file was previously renamed so no problem
				This.Log(Format('{0} was previously renamed to {1}', This.cSource, This.cTarget))
			otherwise
				This.cErrorMessage = Format('{0} does not exist.', This.cSource)
				This.Log(This.cErrorMessage)
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
				This.Log(Format('{0} was deleted', This.cSource))
			catch to loException
				This.cErrorMessage = Format('Cannot delete file {0}', This.cSource)
				This.Log(This.cErrorMessage)
			endtry
		else
			This.Log(Format('{0} does not exist', This.cSource))
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
		if llReturn
			This.Log(Format('{0} was copied to {1}', This.cSource, This.cTarget))
		else
			This.cErrorMessage = Format('{0} could not be copied to {1}', This.cSource, ;
				This.cTarget)
			This.Log(This.cErrorMessage)
		endif llReturn
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
			if llReturn
				This.Log(Format('Folder {0} was deleted', This.cSource))
			else
				This.cErrorMessage = Format('Cannot delete folder {0}', This.cSource)
				This.Log(This.cErrorMessage)
			endif llReturn
		else
			llReturn = .T.
			This.Log(Format('{0} does not exist', This.cSource))
		endif directory(This.cSource)
		return llReturn
	endfunc
enddefine

define class CreateFolder as TaskBase
	cSource = ''
		&& the folder to create

	function Execute
		local llReturn, ;
			loException as Exception
		if not directory(This.cSource)
			try
				md (This.cSource)
				This.Log(Format('Folder {0} was created', This.cSource))
				llReturn = .T.
			catch to loException
				This.cErrorMessage = Format('Cannot create folder {0}: {1}', ;
					This.cSource, loException.Message)
				This.Log(This.cErrorMessage)
			endtry
		endif not directory(This.cSource)
		return llReturn
	endfunc
enddefine

define class RunEXE as TaskBase
	cSource     = ''
		&& the EXE to run
	cParameters = ''
		&& the parameters to pass to it
	cWindowMode = 'HID'
		&& the window mode
*** TODO FUTURE: option to wait until done (the default) or not

	function Execute
		local lcSource, ;
			lcParameters, ;
			lcCommand, ;
			lcMessage, ;
			llResult
		lcSource = EvaluateExpression(This.cSource, This)
		do case
			case empty(lcSource)
				This.cErrorMessage = Format('EXE to run is empty', lcSource)
				This.Log(This.cErrorMessage)
*** TODO FUTURE: we don't currently test FILE(lcSource) since it may be in the path
***					(e.g. curl.exe). Maybe require a full path?
*			case not file(lcSource)
*				This.cErrorMessage = Format('{0} does not exist', lcSource)
*				This.Log(This.cErrorMessage)
			otherwise
				lcParameters = EvaluateExpression(This.cParameters, This)
				lcCommand    = '"' + lcSource + '"' + ;
					icase(empty(lcParameters), '', ;
						'"' $ lcParameters, ' ' + lcParameters, ;
						' "' + lcParameters + '"')
				lcMessage = ExecuteCommand(lcCommand, justpath(fullpath(lcSource)), ;
					iif(This.lDebugMode, 'NOR', 'HID'))
				llResult  = empty(lcMessage)
				if llResult
					This.Log(Format('The command executed successfully\r\n\r\n{0}\r\n\r\n', lcCommand))
				else
					This.cErrorMessage = 'The command did not run successfully. ' + lcMessage
					This.Log(Format('{0}\r\n\r\n{1}\r\n\r\n', This.cErrorMessage, lcCommand))
				endif llResult
		endcase
		return llResult
	endfunc
enddefine

define class SignTool as RunEXE
	cSource      = '{$SignEXE}'
	cDescription = ''
		&& the description for the EXE
	cTarget      = ''
		&& the EXE to sign

	function GetSettings(tcSettings, tlNoExpandVariables)
		local llReturn, ;
			lcParameters
		llReturn     = dodefault(tcSettings, tlNoExpandVariables)
		lcParameters = EvaluateExpression('{$SignCommand}', This)
		do case
			case not llReturn
			case empty(lcParameters)
				This.cErrorMessage = 'SignCommand has not been assigned'
				This.Log(This.cErrorMessage)
				llReturn = .F.
			case empty(This.cTarget)
				This.cErrorMessage = 'The EXE to sign is not specified'
				This.Log(This.cErrorMessage)
				llReturn = .F.
			case not file(This.cTarget)
				This.cErrorMessage = Format('{0} does not exist', This.cTarget)
				This.Log(This.cErrorMessage)
				llReturn = .F.
			otherwise
				lcParameters     = substr(lcParameters, at(' sign ', lcParameters))
				This.cParameters = lcParameters + ' /d "' + This.cDescription + ;
					'" "' + This.cTarget + '"'
		endcase
		return llReturn
	endfunc
enddefine

define class BuildSetupInno as RunEXE
	cSource     = '{$BuildEXEWithInno}'
	cScriptFile = ''

	function GetSettings(tcSettings, tlNoExpandVariables)
		local llReturn
		llReturn = dodefault(tcSettings, tlNoExpandVariables)
		do case
			case not llReturn
			case empty(This.cSource)
				This.cErrorMessage = 'BuildEXEWithInno has not been assigned'
				This.Log(This.cErrorMessage)
				llReturn = .F.
			case not file(This.cSource)
				This.cErrorMessage = Format('{0} does not exist', This.cSource)
				This.Log(This.cErrorMessage)
				llReturn = .F.
			otherwise
				This.cParameters = ' /cc "' + This.cScriptFile + '"'
		endcase
		return llReturn
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
		do case
			case empty(This.cSource)
				This.cErrorMessage = 'The PRG to run is empty'
				This.Log(This.cErrorMessage)
			case not file(This.cSource)
				This.cErrorMessage = Format('{0} does not exist', This.cSource)
				This.Log(This.cErrorMessage)
			otherwise
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
					This.Log(Format('{0} was passed {1} and executed successfully', ;
						This.cSource, This.cParameters))
				catch to loException
					This.cErrorMessage = Format('Error running {0}: {1}', This.cSource, ;
						loException.Message)
					This.Log(This.cErrorMessage)
				finally
					cd (lcCurrPath)
				endtry
		endcase
		return llReturn
	endfunc
enddefine

define class ExecuteScript as TaskBase
	cCode = ''
		&& the code to execute

	function Execute
		local llReturn, ;
			loException as Exception
		if empty(This.cCode)
			This.cErrorMessage = 'The code to execute is empty'
			This.Log(This.cErrorMessage)
		else
			try
				execscript(This.cCode)
				llReturn = .T.
				This.Log('Script executed successfully')
			catch to loException
				This.cErrorMessage = Format('Error running script: {0}', ;
					loException.Message)
				This.Log(This.cErrorMessage)
			endtry
		endif empty(This.cCode)
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
		do case
			case empty(This.cSource)
				This.cErrorMessage = 'The project to build is empty'
				This.Log(This.cErrorMessage)
			case not file(This.cSource)
				This.cErrorMessage = Format('{0} does not exist', This.cSource)
				This.Log(This.cErrorMessage)
			otherwise
				try
					erase (This.cTarget)
					lcRecompile = iif(This.lRecompile, 'recompile', '')
					build exe (This.cTarget) from (This.cSource) &lcRecompile
					llReturn = file(This.cTarget)
					This.Log(Format('{0} was built from {1}', This.cTarget,This.cSource))
				catch to loException
					This.cErrorMessage = Format('Cannot build {0} from {1}: {2}', This.cTarget, ;
						This.cSource, loException.Message)
					This.Log(This.cErrorMessage)
				endtry
		endcase
		return llReturn
	endfunc
enddefine

define class UploadDownload as TaskBase
	cRemoteFile = ''
		&& the remote file to download or upload to
	cLocalFile  = ''
		&& the local file to upload or download to
	cServer     = ''
		&& the server
	cUserName   = ''
		&& the user name to connect to the server
	cPassword   = ''
		&& the password to connect to the server
	cEncrypt    = 'cPassword'
enddefine

define class DownloadFile as UploadDownload
	function Execute
		local loInternet, ;
			llResult
		loInternet = newobject('VFPXInternet', 'VFPXInternet.prg')
		loInternet.cWindowMode = iif(This.lDebugMode, 'NOR', 'HID')
		llResult = loInternet.DownloadFile(This.cRemoteFile, This.cLocalFile, This.cServer, ;
			This.cUserName, This.cPassword)
		if llResult
			This.Log(Format('{0} was downloaded from {1} at {2} using {3} as ' + ;
				'the user name and {4} as the password', This.cLocalFile, This.cRemoteFile, ;
				This.cServer, This.cUserName, This.cPassword), .T.)
		else
			This.cErrorMessage = Format('{0} was not downloaded: {1}', This.cRemoteFile, ;
				loInternet.cErrorMessage)
			This.Log(This.cErrorMessage)
		endif llResult
		return llResult
	endfunc
enddefine

define class UploadFile as UploadDownload
	function Execute
		local loInternet, ;
			llResult
		loInternet = newobject('VFPXInternet', 'VFPXInternet.prg')
		loInternet.cWindowMode = iif(This.lDebugMode, 'NOR', 'HID')
		llResult = loInternet.UploadFile(This.cRemoteFile, This.cLocalFile, This.cServer, ;
			This.cUserName, This.cPassword)
		if llResult
			This.Log(Format('{0} was uploaded to {1} at {2} using {3} as ' + ;
				'the user name and {4} as the password', This.cLocalFile, This.cRemoteFile, ;
				This.cServer, This.cUserName, This.cPassword), .T.)
		else
			This.cErrorMessage = Format('{0} was not uploaded: {1}', This.cLocalFile, ;
				loInternet.cErrorMessage)
			This.Log(This.cErrorMessage)
		endif llResult
		return llResult
	endfunc
enddefine

define class SetVariable as TaskBase
	cVariable = ''
		&& the name of the variable
	cValue    = ''
		&& the value
	lEncrypt  = .F.
		&& .T. to encrypt the value
*** TODO FUTURE: need data type property so can support types other than character

* Flag that we're encrypting cValue if necessary.

	function lEncrypt_Assign(tlValue)
		This.lEncrypt = tlValue
		This.cEncrypt = iif(tlValue, 'cValue', '')
	endfunc

* If we're encrypting the value, read the settings again so we decrypt it this time.

	function GetSettings(tcSettings, tlNoExpandVariables)
		llReturn = dodefault(tcSettings, tlNoExpandVariables)
		if This.lEncrypt
			llReturn = dodefault(tcSettings, tlNoExpandVariables)
		endif This.lEncrypt
		return llReturn
	endfunc

	function Execute
		local lcVariable, ;
			luValue
		lcVariable = This.cVariable
		luValue    = EvaluateExpression(This.cValue, This)
		This.oVariables.AddVariable(This.cVariable, luValue)
		This.Log(Format('{0} was assigned to {1}', luValue, This.cVariable))
	endfunc
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
		if empty(This.cTarget)
			This.cErrorMessage = 'The file to write to is empty'
			This.Log(This.cErrorMessage)
		else
			try
				strtofile(This.cSource, This.cTarget, This.lOverwrite)
				llReturn = .T.
				This.Log(Format('{0} was written to {1} ({2})', This.cSource, ;
					This.cTarget, iif(This.lOverwrite, 'overwrite', 'append')))
			catch to loException
				This.cErrorMessage = Format('Error writing to {0}: {1}', This.cTarget, ;
					loException.Message)
				This.Log(This.cErrorMessage)
			endtry
		endif empty(This.cTarget)
		return llReturn
	endfunc
enddefine

define class ExecutePSScript as RunExe
	cSource     = 'cmd.exe'
	cParameters = '/c %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File'
	cScriptFile = ''

	function GetSettings(tcSettings, tlNoExpandVariables)
		local llReturn
		llReturn = dodefault(tcSettings, tlNoExpandVariables)
		if llReturn
			This.cParameters = This.cParameters + ' "' + This.cScriptFile + '"'
		endif llReturn
		return llReturn
enddefine

define class RunBat as RunExe
	cSource     = 'cmd.exe'
	cParameters = '/c'
	cBatFile    = ''

	function GetSettings(tcSettings, tlNoExpandVariables)
		local llReturn
		llReturn = dodefault(tcSettings, tlNoExpandVariables)
		if llReturn
			This.cParameters = This.cParameters + ' "' + This.cBatFile + '"'
		endif llReturn
		return llReturn
enddefine
