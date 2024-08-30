lparameters tcCommand, ;
	tcFolder, ;
	tcWindowMode, ;
	tlNoWait
local lcFolder, ;
	lcCommand, ;
	lnPos, ;
	lcBatFile, ;
	loAPI, ;
	lcMessage, ;
	lnResult, ;
	llResult

* Get default values for missing parameters.

if vartype(tcFolder) <> 'C' or empty(tcFolder)
	lcFolder = fullpath('')
else
	lcFolder = tcFolder
endif vartype(tcFolder) <> 'C' or empty(tcFolder)
if right(lcFolder, 1) = '\'
	lcFolder = left(lcFolder, len(lcFolder) - 1)
endif right(lcFolder, 1) = '\'

* If the command contains a redirected output, which isn't supported by
* API_AppRun, we'll put the command into a BAT file and execute that.

lcCommand = tcCommand
lnPos     = at('>', tcCommand)
if lnPos > 0
	lcBatFile = addbs(sys(2023)) + 'Execute.bat'
	strtofile(tcCommand, lcBatFile)
	lcCommand = '"' + fullpath(lcBatFile) + '"'
endif lnPos > 0

* Use API_AppRun to execute the command.

loAPI = newobject('API_AppRun', 'API_AppRun.prg', '', lcCommand, lcFolder, ;
	evl(tcWindowMode, 'HID'))
do case
	case not empty(loAPI.icErrorMessage)
		lcMessage = loAPI.icErrorMessage
	case tlNoWait and loAPI.LaunchApp()
		lcMessage = ''
	case tlNoWait
		lcMessage = loAPI.icErrorMessage
	case loAPI.LaunchAppAndWait()
		lnResult  = nvl(loAPI.CheckProcessExitCode(), -1)
		llResult  = lnResult = 0
		lcMessage = iif(llResult, '', ;
			evl(loAPI.icErrorMessage, 'The error code is ' + transform(lnResult)))
	otherwise
		lcMessage = loAPI.icErrorMessage
endcase

* Erase the BAT file.

if lnPos > 0
	erase (lcBatFile)
endif lnPos > 0
return lcMessage
