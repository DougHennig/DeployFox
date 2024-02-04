lparameters tcVariable, ;
	tuValue
*** TODO: ensure valid name
local lcVariable, ;
	loVariable, ;
	loCurrVariable
lcVariable = upper(tcVariable)
loVariable = NULL
for each loCurrVariable in poDeployFoxForm.oEngine.oVariables foxobject
	if upper(loCurrVariable.Name) $ lcVariable
		loVariable = loCurrVariable
		exit
	endif upper(loCurrVariable.Name) $ lcVariable
next loVariable
if vartype(loVariable) <> 'O'
	poDeployFoxForm.oEngine.oVariables.AddVariable(tcVariable, tuValue)
else
	loVariable.Value = tuValue
endif vartype(loVariable) <> 'O'
