* Returns either the passed string or the textmerge of it if it contains { and
* }.

lparameters tcExpression, ;
	toObject
local lcReturn, ;
	lcExpression, ;
	loException as Exception
if '{' $ tcExpression and '}' $ tcExpression
	lcExpression = strtran(tcExpression, '{', '<<')
	lcExpression = strtran(lcExpression, '}', '>>')
	lcExpression = strtran(lcExpression, 'This.', 'toObject.')
	try
		lcReturn = textmerge(alltrim(lcExpression))
	catch to loException
		lcReturn = alltrim(tcExpression)
	endtry
else
	lcReturn = alltrim(tcExpression)
endif '{' $ tcExpression ...
return lcReturn
