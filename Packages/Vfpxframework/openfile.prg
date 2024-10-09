lparameters tcFile
declare integer ShellExecute in Shell32.dll ;
	integer hwnd, ;
	string lpVerb, ;
	string lpFile, ;
	string lpParameters, ;
	string lpDirectory, ;
	long nShowCmd 
declare integer FindWindow in Win32API ;
	string cNull, string cWinName
ShellExecute(FindWindow(0, _screen.Caption), 'Open', tcFile, '', '', 1)
