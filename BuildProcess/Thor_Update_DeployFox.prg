*File to control Thor CFU for application DeployFox
lparameters;
	toUpdateObject

local;
	lcRepositoryURL    as string, ;
	lcDownloadsBranch  as string, ;
	lcDownloadsURL     as string, ;
	lcVersionFileURL   as string, ;
	lcZIPFileURL       as string, ;
	lcRegisterWithThor as string

* Get the URL for the version and ZIP files.

lcRepositoryURL   = 'https://github.com/DougHennig/DeployFox'
	&& the URL for the project's repository
* Note: If you use a more recent version of git, your default branch may not be "master".
lcDownloadsBranch = 'master'
lcDownloadsURL    = strtran(m.lcRepositoryURL, 'github.com', ;
	'raw.githubusercontent.com') + '/' + m.lcDownloadsBranch + '/ThorUpdater/'
lcVersionFileURL  = m.lcDownloadsURL + 'DeployFoxVersion.txt' &&'DeployFoxVersion.txt'
	&& the URL for the file containing code to get the available version number
lcZIPFileURL      = m.lcDownloadsURL + 'DeployFox.zip'
	&& the URL for the zip file containing the project


text to lcRegisterWithThor noshow textmerge
	messagebox('From the Thor menu, choose "More -> Open Folder -> Components" to see the folder where DeployFox was installed', 0, 'DeployFox Installed', 5000)
endtext

* Set the properties of the passed updater object.

with m.toUpdateObject
	.ApplicationName      = 'DeployFox'
	.VersionLocalFilename = 'DeployFoxVersionFile.txt'
	.VersionFileURL       = m.lcVersionFileURL
	.SourceFileUrl        = m.lcZIPFileURL
	.Component            = 'No'
	.Link                 = m.lcRepositoryURL
	.LinkPrompt           = 'DeployFox Home Page'
	.ProjectCreationDate  = date(2024, 7, 21)
	.Dependencies         = ''	&& a comma or space delimited list of other Thor applications (ApplicationName) that this project depends on
	.RegisterWithThor     = m.lcRegisterWithThor

endwith

return m.toUpdateObject

*created by VFPX Deployment, 07/21/2024 9:43:40 AM