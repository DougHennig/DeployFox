#include DeployFox.h

define class DeployFoxEngine as Custom
	cAppPath        = ''
		&& the path to DeployFox.app
	cLogFile        = ''
		&& the path of a file to log to
	cErrorMessage   = ''
		&& the text of an error
	cProjectFile    = ''
		&& the path to the project file
	oRecentProjects = .NULL.
		&& a references to a VFPXMRUFile object
	oVariables      = .NULL.
		&& a reference to an object containing variables

	function Init
		local laStack[1], ;
			lnI, ;
			lcPath, ;
			loRegistry, ;
			lcValue, ;
			lcInnoCompiler, ;
			lcSignEXE, ;
			lcSignCommand, ;
			loDecrypt, ;
			lcKey, ;
			lcName, ;
			lcValue, ;
			luValue

* Get the path we're running from.

		for lnI = 1 to astackinfo(laStack)
			if laStack[lnI, 3] = 'main'
				lcPath = justpath(laStack[lnI, 2])
				exit
			endif laStack[lnI, 3] = 'main'
		next lnI
		if empty(lcPath)
			lcPath = justpath(substr(sys(16), at(' ', sys(16), 2) + 1))
		endif empty(lcPath)
		if lower(substr(lcPath, rat('\', lcPath) + 1)) = 'source'
			lcPath = fullpath('..\', addbs(lcPath))
		endif lower(substr(lcPath ...
		lcPath = addbs(lcPath)
		This.cAppPath = lcPath

* Populate the list of recent projects.

		This.oRecentProjects = newobject('VFPXMRUFile', 'VFPXMRU.prg')
		This.oRecentProjects.cItemName    = 'Project'
		This.oRecentProjects.cRegistryKey = ccREGISTRY_KEY
		This.oRecentProjects.nMaxItems    = cnMRU_PROJECTS
		This.oRecentProjects.LoadMRUs()

* Create a collection of variables.

		This.oVariables = newobject('DeployFoxVariables', 'DeployFoxEngine.prg')

* Get the DeployFox settings. If we don't have any, we'll create some defaults.

		select 0
		if not file(lcPath + 'DeployFoxSettings.dbf')

* See if Inno Setup is installed.

			loRegistry     = newobject('VFPXRegistry', 'VFPXRegistry.vcx')
			lcInnoCompiler = loRegistry.GetKey('InnoSetupScriptFile\Shell\Compile\Command', ;
				'', '', cnHKEY_CLASSES_ROOT)
			lcInnoCompiler = strtran(strtran(lcInnoCompiler, ' /cc "%1"'), '"')

* Set other settings values.

			lcSignEXE     = '{$AppPath}signtool.exe'
			lcSignCommand = '"{$SignEXE}" sign /fd SHA256 ' + ;
				'/tr http://timestamp.digicert.com /td SHA256 ' + ;
				'/f "{$CertPath}" ' + ;
				'/p {$CertPassword}'

* Create the DeployFoxSettings table.

			create table (lcPath + 'DeployFoxSettings') (Setting C(20), Value M, ;
				Encrypt L, Type C(1), Variable L)
			insert into DeployFoxSettings values ('SignEXE',          lcSignEXE, ;
				.F., 'C', .T.)
			insert into DeployFoxSettings values ('SignCommand',      lcSignCommand, ;
				.F., 'C', .T.)
			insert into DeployFoxSettings values ('BuildEXEWithInno', lcInnoCompiler, ;
				.F., 'C', .T.)
			insert into DeployFoxSettings values ('CertPassword',     '', ;
				.T., 'C', .T.)
			insert into DeployFoxSettings values ('CertPath',         '', ;
				.F., 'C', .T.)
			insert into DeployFoxSettings values ('TaskIncrement',    '1', ;
				.F., 'I', .F.)
		endif not file(lcPath + 'DeployFoxSettings.dbf')

* Create a decryption object and get the key to use.

		loDecrypt = newobject('DeployFoxEncryption', 'DeployFoxEncryption.prg')
		lcKey     = GetKey()

* Get the settings from the DeployFoxSettings table.

		use (lcPath + 'DeployFoxSettings') again shared
		scan
			lcName  = trim(Setting)
			lcValue = Value
			if Encrypt and left(lcValue, 2) = '0x'
				lcValue = trim(loDecrypt.Decrypt_AES(strconv(substr(lcValue, 3), 16), lcKey))
			endif Encrypt ...
			do case
				case Type = 'I'
					luValue = int(val(lcValue))
				case Type = 'N'
					luValue = val(lcValue)
				otherwise
					luValue = lcValue
			endcase
			if Variable
				This.oVariables.AddVariable(lcName, luValue, .T.)
			else
				This.AddProperty(lcName, luValue)
			endif Variable
		endscan
		use
		This.oVariables.AddVariable('AppPath',     This.cAppPath, .T.)
		This.oVariables.AddVariable('ProjectPath', '',            .T.)

* Get a task types cursor.

		This.GetTaskTypes()

* Declare the Sleep API function.

		declare Sleep in Win32API integer nMilliseconds
	endfunc

* Open a project.

	function OpenProject(tcPath)
		local loException as Exception, ;
			lnFields, ;
			laFields[1], ;
			lnTestFields, ;
			laTestFields[1], ;
			llOK, ;
			lnI, ;
			llReturn
		if file(tcPath)
			use in select('curProject')
			use in select('ProjectFile')

* Try to open the project file.

			try
				use (tcPath) alias ProjectFile in 0
			catch to loException
				This.cErrorMessage = 'Error opening ' + tcPath + ': ' + ;
					loException.Message
			endtry
			if used('ProjectFile')

* Ensure it's a valid project file.

				This.CreateProject('curTestStructure', .T.)
				lnFields     = afields(laFields,     'ProjectFile')
				lnTestFields = afields(laTestFields, 'curTestStructure')
				llOK = lnFields = lnTestFields
				if llOK
					for lnI = 1 to lnFields
						llOK = laFields[lnI, 1] == laTestFields[lnI, 1] and ;
							laFields[lnI, 2] = laTestFields[lnI, 2]
						if not llOK
							exit
						endif not llOK
					next lnI
				endif llOK
				if llOK
					This.cProjectFile = tcPath
					SetVariable('ProjectPath', addbs(justpath(This.cProjectFile)))
					select *, space(20) as Status ;
						from (This.cProjectFile) ;
						into cursor curProject readwrite
					index on Order tag Order

* Erase the log file for the project.

					This.cLogFile = forcepath('DeployFoxLog.txt', justpath(tcPath))
					try
*** TODO FUTURE: option to timestamp and keep log files
						erase (This.cLogFile)
					catch
					endtry

* Add it to the list of recent projects.

					This.oRecentProjects.Add(tcPath)
					llReturn = .T.
				else
					This.cErrorMessage = tcPath + ' is not DeployFox project file.'
				endif llOK
			endif used('ProjectFile')
		else
			This.cErrorMessage = tcPath + ' does not exist.'
		endif file(tcPath)
		return llReturn
	endfunc

* Create a new project.

	function NewProject(tcPath)
		This.CreateProject(tcPath)
		insert into (tcPath) (Order) values (1)
		use
	endfunc

* Create a project table or cursor.

	function CreateProject(tcPath, tlCursor)
		text to lcCommand noshow textmerge pretext 2
		create <<iif(tlCursor, 'cursor', 'table')>> (tcPath) (ID C(10), 
			Order I, Task C(20), Name C(80), Active L, Incomplete L,
			AlwaysRun L, Settings M, Comments M)
		endtext
		lcCommand = chrtran(lcCommand, ccCRLF, '')
		&lcCommand
	endfunc

* Get a cursor of task types, combining TaskTypes (built-in) and MyTaskTypes (custom).

	function GetTaskTypes
		local lcPath
		if not used('curTaskTypes')
			select * ;
				from TaskTypes ;
				into cursor curTaskTypes readwrite
			lcPath = This.cAppPath
			if not file(lcPath + 'MyTaskTypes.dbf')
				copy to (lcPath + 'MyTaskTypes.dbf') for .F.
			endif not file(lcPath + 'MyTaskTypes.dbf')
			append from (lcPath + 'MyTaskTypes.dbf')
		endif not used('curTaskTypes')
	endfunc

* Fill an array with defined variable names.

	function GetVariableNames(taArray, tlIncludeBuiltIn)
		local lnSelect, ;
			lnVariables, ;
			lnI, ;
			loVariable
		lnSelect = select()
		select * ;
			from (This.cProjectFile) ;
			where Active ;
			order by Order ;
			into cursor curRun
		This.SetVariables()
		use in curRun
		lnVariables = 0
		for lnI = 1 to This.oVariables.Count
			loVariable = This.oVariables.Item[lnI]
			if tlIncludeBuiltIn or not loVariable.BuiltIn
				lnVariables = lnVariables + 1
				dimension taArray[lnVariables]
				taArray[lnVariables] = loVariable.Name
			endif tlIncludeBuiltIn ....,
		next lnI
		select (lnSelect)
		return lnVariables
	endfunc

* Run the tasks for the project. First, set all the variables, then run the other tasks.

	function Run(tlDebug)
		local lnSelect, ;
			llReturn
		try
*** TODO FUTURE: option to timestamp and keep log files
			erase (This.cLogFile)
		catch
		endtry
		lnSelect = select()
		select * ;
			from (This.cProjectFile) ;
			where Active and not Incomplete ;
			order by Order ;
			into cursor curRun
		llReturn = This.AlwaysRun()
		if llReturn
			scan for not AlwaysRun
				llReturn = This.RunTask(ID, Name, Task, Settings, tlDebug)
				if not llReturn
					exit
				endif not llReturn
			endscan for not AlwaysRun
		endif llReturn
		use in curRun
		select (lnSelect)
	endfunc

* Run all the "always run" tasks.

	function AlwaysRun
		local llReturn
		llReturn = .T.
		scan for AlwaysRun
			llReturn = This.RunTask(ID, Name, Task, Settings)
			if not llReturn
				exit
			endif not llReturn
		endscan for AlwaysRun
		return llReturn
	endfunc

* Run all the "SetVariable" tasks.

	function SetVariables
		local llReturn
		llReturn = .T.
		scan for Task = 'SetVariable'
			llReturn = This.RunTask(ID, Name, Task, Settings)
			if not llReturn
				exit
			endif not llReturn
		endscan for Task = 'SetVariable'
		return llReturn
	endfunc

* Run the current task.

	function RunTask(tcID, tcName, tcTaskType, tcSettings, tlDebug)
		local lnSelect, ;
			lcTaskType, ;
			lcFile, ;
			loTask, ;
			llReturn, ;
			lcMessage, ;
			loException as Exception
		lnSelect = select()
		raiseevent(This, 'Update', tcID, 'Running', '')
		lcTaskType = trim(tcTaskType)
		This.GetTaskTypes()
		select curTaskTypes
		locate for upper(Type) = upper(lcTaskType)
		lcFile = trim(File)
		loTask = newobject(lcTaskType, lcFile, '', This.oVariables)
		loTask.cName      = trim(tcName)
		loTask.lDebugMode = tlDebug
		loTask.cLogFile   = This.cLogFile
		if loTask.GetSettings(tcSettings)
			try
				llReturn  = loTask.Execute()
				lcMessage = loTask.cErrorMessage
			catch to loException
				lcMessage = loException.Message
			endtry
		else
			lcMessage = loTask.cErrorMessage
		endif loTask.GetSettings(tcSettings)
		This.cErrorMessage = lcMessage
		if llReturn
			raiseevent(This, 'Update', tcID, 'Success', '')
		else
			raiseevent(This, 'Update', tcID, 'Failed', lcMessage)
		endif llReturn
		select (lnSelect)
		return llReturn
	endfunc

* This function is here so we can use RAISEEVENT.

	function Update(tcID, tcStatus, tcMessage)
	endfunc
enddefine

* A collection of defined variables.

define class DeployFoxVariables as Collection
	function AddVariable(tcName, tuValue, tlBuiltIn)
		local loVariable
		lcName = upper(tcName)
		if This.GetKey(lcName) = 0
			loVariable = newobject('DeployFoxVariable', 'DeployFoxEngine.prg')
			loVariable.Name    = tcName
			loVariable.Value   = tuValue
			loVariable.BuiltIn = tlBuiltIn
			This.Add(loVariable, lcName)
		endif This.GetKey(lcName) = 0
	endfunc

* Case-insensitive Item method (keys are upper-cased).

	function Item(tuIndex)
		local luReturn, ;
			lcIndex
		luReturn = .NULL.
		if vartype(tuIndex) = 'C'
			lcIndex = upper(alltrim(tuIndex))
			if This.GetKey(lcIndex) > 0
				luReturn = dodefault(lcIndex)
			endif This.GetKey(lcIndex) > 0
		else
			try
				luReturn = dodefault(tuIndex)
			catch
			endtry
		endif vartype(tuIndex) = 'C'
		nodefault
		return luReturn
	endfunc
enddefine

* A variable.

define class DeployFoxVariable as Custom
	Value   = .NULL.
	BuiltIn = .F.
enddefine
