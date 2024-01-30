* Set the path to the source folders if we're not running an app.

lnStack = astackinfo(laStack)
if justext(laStack[lnStack, 2]) <> 'app'
	set path to 'Source,' + ;
		'Packages\FoxCryptoNG,' + ;
		'Packages\Format,' + ;
		'Packages\VFPXFramework,' + ;
		'Packages\OOPMenu' ;
		additive
endif justext(laStack[lnStack, 2]) <> 'app'

* Create and display the DeployFoxForm form.

public poDeployFoxForm
poDeployFoxForm = newobject('DeployFoxForm', 'DeployFoxUI.vcx')
poDeployFoxForm.Show()
