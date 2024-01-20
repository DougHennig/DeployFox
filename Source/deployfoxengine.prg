#include DeployFox.h

define class DeployFoxEngine as Custom
	cProjectFile  = ''
		&& the path to the project file
	cErrorMessage = ''
		&& the text of an error
	oVariables    = .NULL.
		&& a reference to an object containing variables

	function Init
		local laStack[1], ;
			lnI, ;
			lcPath

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

* Open the encryption library.

*** TODO: use FoxCrypto_NG?
		if not 'vfpencryption71' $ set('LIBRARY')
			set library to (lcPath + 'VFPEncryption71.fll')
		endif not 'vfpencryption71' $ set('LIBRARY')

* Get the DeployFox settings.

		This.oVariables = newobject('DeployFoxVariables', 'DeployFoxEngine.prg')
		lcKey = GetKey()
*** TODO: delete Value for CertPassword before deploying
		select 0
		use (lcPath + 'DeployFoxSettings') again shared
		scan
			lcVariable = trim(Setting)
			lcValue    = Value
			if Encrypt and left(lcValue, 2) = '0x'
				lcValue = trim(Decrypt(strconv(substr(lcValue, 3), 16), lcKey))
			endif Encrypt ...
			This.oVariables.Add(lcVariable, lcValue)
		endscan

	endfunc

* Open a project.

	function OpenProject(tcPath)
		use in select('curProject')
		use in select('ProjectFile')
		This.cProjectFile = tcPath
		use (This.cProjectFile) alias ProjectFile in 0
*** TODO: check structure to ensure it's a project file
		select *, space(20) as Status ;
			from (This.cProjectFile) ;
			into cursor curProject readwrite
		index on Order tag Order
	endfunc

* Create a new project.

	function NewProject(tcPath)
		create table (tcPath) (ID C(10), Order I, Task C(20), Name C(80), Active L, ;
			Settings M, Comments M)
		use
		This.OpenProject(tcPath)
	endfunc

* Run the tasks for the project.

	function Run
		local llReturn
		if not used('TaskTypes')
			use TaskTypes in 0
		endif not used('TaskTypes')
		select * ;
			from (This.cProjectFile) ;
			where Active ;
			order by Order ;
			into cursor curRun
		scan
			raiseevent(This, 'Update', curRun.ID, 'Running', '')
			llReturn = This.RunTask(Task, Settings)
			if llReturn
				raiseevent(This, 'Update', curRun.ID, 'Success', '')
			else
				raiseevent(This, 'Update', curRun.ID, 'Failed', This.cErrorMessage)
				exit
			endif llReturn
		endscan
	endfunc

* Run the current task.

	function RunTask(tcTaskType, tcSettings)
		local lcFile, ;
			loTask, ;
			llReturn
		lcTaskType = trim(tcTaskType)
		select TaskTypes
		locate for upper(Type) = upper(lcTaskType)
		lcFile = trim(File)
		loTask = newobject(lcTaskType, lcFile, '', This.oVariables)
		if loTask.GetSettings(tcSettings)
			llReturn = loTask.Execute()
		endif loTask.GetSettings(tcSettings)
		This.cErrorMessage = loTask.cErrorMessage
		return llReturn
	endfunc

* This function is here so we can use RAISEEVENT.

	function Update(tcID, tcStatus, tcMessage)
	endfunc
enddefine

define class DeployFoxVariables as Custom
	function Add(tcName, tuValue)
		addproperty(This, tcName, tuValue)
	endfunc
enddefine
