define class DeployFoxEngine as Custom
	cProjectFile = ''
		&& the path to the project file

	function Init
		public SignEXE, ;
			SignCommand, ;
			BuildEXE
*** TODO: remove; get from settings file
		SignEXE = 'C:\Development\SFQuery\Certificate\signtool.exe'
*** TODO: remove; get from settings file (decrypt it)
		SignCommand = '/sStandard=$q{SignEXE}$q sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /f $qC:\Development\SFQuery\Certificate\mycert.pfx$q /p Cert_4_Me $p'
*** TODO: remove; get from settings file
		BuildEXE = 'C:\Program Files (x86)\Inno Setup 6\iscc'

		set library to VFPEncryption71.fll
	endfunc

	function OpenProject(tcPath)
		use in select('ProjectFile')
		use in select('curProject')
		This.cProjectFile = tcPath
		use (This.cProjectFile) alias ProjectFile
*** TODO: check structure to ensure it's a project file
		select *, space(20) as Status ;
			from (This.cProjectFile) ;
			order by Order ;
			into cursor curProject readwrite
	endfunc

	function NewProject(tcPath)
		create table (tcPath) (ID C(10), Order I, Task C(20), Name C(80), Active L, Settings M, Comments M)
		use
		This.OpenProject(tcPath)
	endfunc

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
