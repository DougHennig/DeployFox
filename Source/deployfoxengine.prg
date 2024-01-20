#include DeployFox.h

define class DeployFoxEngine as Custom
	cProjectFile = ''
		&& the path to the project file

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
*** TODO: not public variable
		release AppPath
		public AppPath
		AppPath = addbs(lcPath)

* Open the encryption library.

*** TODO: use FoxCrypto_NG?
		if not 'vfpencryption71' $ set('LIBRARY')
			set library to (AppPath + 'VFPEncryption71.fll')
		endif not 'vfpencryption71' $ set('LIBRARY')

* Get the DeployFox settings.

		lcKey = GetKey()
*** TODO: delete Value for CertPassword before deploying
		use (AppPath + 'DeployFoxSettings') again shared
		scan
			lcVariable = trim(Setting)
			lcValue    = Value
			if Encrypt and left(lcValue, 2) = '0x'
				lcValue = trim(Decrypt(strconv(substr(lcValue, 3), 16), lcKey))
			endif Encrypt ...
*** TODO: don't use public variables
			release &lcVariable
			public &lcVariable
			store lcValue to (lcVariable)
		endscan

	endfunc

* Open a project.

	function OpenProject(tcPath)
		use in select('curProject')
		use in select('ProjectFile')
		This.cProjectFile = tcPath
		use (This.cProjectFile) alias ProjectFile
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
*** TODO: local
		if not used('TaskTypes')
			use TaskTypes in 0
		endif not used('TaskTypes')
		select * ;
			from (This.cProjectFile) ;
			where Active ;
			order by Order ;
			into cursor curRun
		scan
*** TODO: call a function to run current task. That way, can test single task
			lcTaskType = trim(Task)
			select TaskTypes
			locate for upper(Type) = upper(lcTaskType)
			lcFile = trim(File)
			loTask = newobject(lcTaskType, lcFile)
			if loTask.GetSettings(Settings)
				select 0
				llReturn = loTask.Execute()
				if llReturn
					raiseevent(This, 'Update', curRun.ID, 'Success')
				else
set step on 
					raiseevent(This, 'Update', curRun.ID, 'Failed')
					messagebox(loTask.cErrorMessage, 16, 'DeployFox')
					exit
				endif llReturn
*** TODO: what if it closes all data: run in private datasession? Maybe run form and have form instantiate this class into This.oEngine
			else
*** TODO: what to do
set step on 
				messagebox(loTask.cErrorMessage, 16, 'DeployFox')
				exit
			endif loTask.GetSettings(Settings)
		endscan
	endfunc

* This function is here so we can use RAISEEVENT.

	function Update(tcID, tcMessage)
	endfunc
enddefine
