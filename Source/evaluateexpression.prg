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
	lcExpression = strtran(lcExpression, '$', 'toObject.oVariables.')
	try
		lcReturn = textmerge(alltrim(lcExpression))
	catch to loException
		lcReturn = alltrim(tcExpression)
	endtry
else
	lcReturn = alltrim(tcExpression)
endif '{' $ tcExpression ...
return lcReturn
