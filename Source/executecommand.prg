lparameters tcCommand, ;
	tcFolder, ;
	tcWindowMode
local lcFolder, ;
	loAPI, ;
	lcMessage, ;
	lnResult, ;
	llResult
lcFolder = tcFolder
if right(lcFolder, 1) = '\'
	lcFolder = left(lcFolder, len(lcFolder) - 1)
endif right(lcFolder, 1) = '\'
loAPI = newobject('API_AppRun', 'API_AppRun.prg', '', tcCommand, lcFolder, ;
	tcWindowMode)
do case
	case not empty(loAPI.icErrorMessage)
		lcMessage = loAPI.icErrorMessage
	case loAPI.LaunchAppAndWait()
		lnResult  = nvl(loAPI.CheckProcessExitCode(), -1)
		llResult  = lnResult = 0
		lcMessage = iif(llResult, '', ;
			evl(loAPI.icErrorMessage, Format('The error code is {0}.', lnResult)))
	otherwise
		lcMessage = loAPI.icErrorMessage
endcase
return lcMessage
