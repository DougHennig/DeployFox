# DeployFox

Tracy Pearson did a presentation at Southwest Fox 2019 titled "[VFP DevOps: Implementing an Automated Build for a Complex Release of a Vertical Market Application](https://swfox.net/2019/SessionsSWFOX.aspx#DevOps_Implementing_an_Automated_Build)" that explains in detail the benefits of automating deployment.

Until recently, I used a Microsoft Excel document with a long list of tasks as a checklist for application deployment. These tasks were almost all manual. I've always wanted to automate deployment as much as possible, so I created DeployFox. DeployFox automates the steps required to deploy your applications by providing a customizable list of tasks: copy files, rename files, build a project into an EXE, digitally sign an EXE, run an Inno Setup script to create an installer, upload files to an FTP site, and so on. Now I mostly just open a DeployFox project and run it to deploy an application, saving me lots of time and making an error-free process.

Deploying an application consists of a set of tasks. In DeployFox, sets of tasks are called a project and are stored in a table located wherever you wish (usually a subdirectory of the folder for the application to deploy). DeployFox supports a lot of types of tasks, such as copying files, renaming files, uploading and downloading files, and so on.

![](Doc/deployfox.png)

## Documentation
See the [documentation](Doc/Documentation.md) for instructions on how to use DeployFox.

## Helping with this project

See [How to Contribute to DeployFox](.github/CONTRIBUTING.md) for details on how to help with this project.

## Releases

See the [change log](ChangeLog.md) for release information.
