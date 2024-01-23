* Returns either the passed string or the textmerge of it if it contains { and
* }. Handle variables with a $ prefix.

lparameters tcExpression, ;
	toObject
local lcReturn, ;
	lcExpression, ;
	loException as Exception
if '{' $ tcExpression and '}' $ tcExpression
	lcExpression = strtran(tcExpression, '{', '<<')
	lcExpression = strtran(lcExpression, '}', '>>')
	lcExpression = strtran(lcExpression, 'This.', 'toObject.')
	for each loVariable in toObject.oVariables foxobject
		if '$' + upper(loVariable.Name) $ upper(lcExpression)
			lcExpression = strtran(lcExpression, '$' + loVariable.Name, ;
				"toObject.oVariables.Item['" + loVariable.Name + "'].Value", -1, -1, 1)
		endif '$' + upper(loVariable.Name) $ upper(lcExpression)
	next loVariable
	try
		lcReturn = textmerge(alltrim(lcExpression))
		if '{' $ lcReturn and '}' $ lcReturn
			lcReturn = EvaluateExpression(lcReturn, toObject)
				&& call ourselves recursively until all expressions are processed
		endif '{' $ lcReturn and '}' $ lcReturn
	catch to loException
		lcReturn = alltrim(tcExpression)
	endtry
else
	lcReturn = alltrim(tcExpression)
endif '{' $ tcExpression ...
return lcReturn
