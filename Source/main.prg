* Set the path to the source folders if we're not running an app.

lnStack = astackinfo(laStack)
if justext(laStack[lnStack, 2]) <> 'app'
	set path to 'Source,' + ;
		'Packages\Format,' + ;
		'Packages\VFPXFramework,' + ;
		'Packages\OOPMenu' ;
		additive
endif justext(laStack[lnStack, 2]) <> 'app'

* Run System.app so things using GDI+ have access to it.

if file('System.app')
	do System.app
else
	do (addbs(justpath(sys(16))) + 'System.app')
endif file('System.app')

* Create and display the DeployFoxForm form.

public poDeployFoxForm
poDeployFoxForm = newobject('DeployFoxForm', 'DeployFoxUI.vcx')
poDeployFoxForm.Show()
