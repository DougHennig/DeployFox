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
		&& a collection of recent projects
	oVariables      = .NULL.
		&& a reference to an object containing variables

	function Init
		local laStack[1], ;
			lnI, ;
			lcPath, ;
			loRegistry, ;
			lcValue, ;
			lcInnoCompiler, ;
			loDecrypt, ;
			lcKey, ;
			lcVariable

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

		This.oRecentProjects = createobject('Collection')
		loRegistry = newobject('VFPXRegistry', 'VFPXRegistry.vcx')
		for lnI = cnMRUProjects to 1 step -1
			lcValue = loRegistry.GetKey(ccREGISTRY_KEY, 'Project' + transform(lnI))
			if not empty(lcValue)
				This.oRecentProjects.Add(lcValue, lcValue)
			endif not empty(lcValue)
		next lnI

* Create a collection of variables.

		This.oVariables = newobject('DeployFoxVariables', 'DeployFoxEngine.prg')

* Get the DeployFox settings. If we don't have any, we'll create some defaults.

*** TODO: delete DeployFoxSettings.dbf before deploying
		select 0
		if not file(lcPath + 'DeployFoxSettings.dbf')

* See if Inno Setup is installed.

			lcInnoCompiler = loRegistry.GetKey('InnoSetupScriptFile\Shell\Compile\Command', ;
				'', '"C:\Program Files (x86)\Inno Setup 6\iscc.exe"', cnHKEY_CLASSES_ROOT)
			lcInnoCompiler = strtran(lcInnoCompiler, '"%1"')

* Create the DeployFoxSettings table.

			create table (lcPath + 'DeployFoxSettings') (Setting C(20), Value M, Encrypt L)
			insert into DeployFoxSettings values ('SignEXE', '{$AppPath}signtool.exe', .F.)
			insert into DeployFoxSettings values ('SignCommand', '', .F.)
			insert into DeployFoxSettings values ('BuildEXEWithInno', lcInnoCompiler, .F.)
			insert into DeployFoxSettings values ('CertPassword', '', .T.)
		endif not file(lcPath + 'DeployFoxSettings.dbf')

* Create a decryption object and get the key to use.

		loDecrypt = newobject('foxCryptoNG', 'foxCryptoNG.prg')
		lcKey     = GetKey()

* Get the settings from the DeployFoxSettings table.

		use (lcPath + 'DeployFoxSettings') again shared
		scan
			lcVariable = trim(Setting)
			lcValue    = Value
			if Encrypt and left(lcValue, 2) = '0x'
				lcValue = trim(loDecrypt.Decrypt_AES(strconv(substr(lcValue, 3), 16), lcKey))
			endif Encrypt ...
			This.oVariables.AddVariable(lcVariable, lcValue, .T.)
		endscan
		This.oVariables.AddVariable('AppPath', This.cAppPath, .T.)

* Get a task types cursor.

		This.GetTaskTypes()

* Declare the Sleep API function.

		declare Sleep in Win32API integer nMilliseconds
	endfunc

* Open a project.

	function OpenProject(tcPath)
		local loRegistry, ;
			laProjects[1], ;
			lnLast, ;
			lnI, ;
			lcProject, ;
			lcValue
		use in select('curProject')
		use in select('ProjectFile')
		This.cProjectFile = tcPath
		use (This.cProjectFile) alias ProjectFile in 0
*** TODO: check structure to ensure it's a project file
		select *, space(20) as Status ;
			from (This.cProjectFile) ;
			into cursor curProject readwrite
		index on Order tag Order
		This.cLogFile = forcepath('DeployFoxLog.txt', justpath(tcPath))
		try
*** TODO: option to timestamp and keep log files?
			erase (This.cLogFile)
		catch
		endtry

* Add it to the list of recent projects if it isn't already there.

		if This.oRecentProjects.GetKey(tcPath) = 0
			This.oRecentProjects.Add(tcPath, tcPath)
			loRegistry = newobject('VFPXRegistry', 'VFPXRegistry.vcx')
			dimension laProjects[cnMRUProjects]
			lnLast = cnMRUProjects
			for lnI = cnMRUProjects to 1 step -1
				laProjects[lnI] = loRegistry.GetKey(ccREGISTRY_KEY, 'Project' + transform(lnI))
				lnLast = iif(empty(laProjects[lnI]), lnI, lnLast)
			next lnI
			if empty(laProjects[cnMRUProjects])
				laProjects[lnLast] = tcPath
			else
				adel(laProjects, 1)
				laProjects[cnMRUProjects] = tcPath
			endif empty(laProjects[cnMRUProjects])
			for lnI = 1 to cnMRUProjects
				loRegistry.SetKey(ccREGISTRY_KEY, 'Project' + transform(lnI), laProjects[lnI])
			next lnI
		endif This.oRecentProjects.GetKey(lcPath) = 0
	endfunc

* Create a new project.

	function NewProject(tcPath)
		create table (tcPath) (ID C(10), Order I, Task C(20), Name C(80), Active L, ;
			Settings M, Comments M)
		use
		This.OpenProject(tcPath)
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
*** TODO: option to timestamp and keep log files?
			erase (This.cLogFile)
		catch
		endtry
		lnSelect = select()
		select * ;
			from (This.cProjectFile) ;
			where Active ;
			order by Order ;
			into cursor curRun
		llReturn = This.SetVariables()
		if llReturn
			scan for Task <> 'SetVariable'
				llReturn = This.RunTask(ID, Name, Task, Settings, tlDebug)
				if not llReturn
					exit
				endif not llReturn
			endscan for Task <> 'SetVariable'
		endif llReturn
		use in curRun
		select (lnSelect)
	endfunc

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
