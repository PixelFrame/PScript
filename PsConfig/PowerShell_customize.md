# PowerShell Customize

## Module oh-my-posh and posh-git

oh-my-posh is a module for PowerShell to customize prompt style. You can check the themes from its [Project page](https://github.com/JanDeDobbeleer/oh-my-posh#themes).
To install, run the command below. The scope can be user or machine(need Administrator privilege) and the installation location will change accordingly.

```PowerShell
Install-Module oh-my-posh -Scope CurrentUser
```

Then we will import the modules and the theme.

```PowerShell
Import-Module oh-my-posh
Set-Theme Paradox
```

## Profile

The 2 modules mentioned above needs to be imported every time PowerShell is launched.
So we will need Profile files.

## Coloring

## Terminal
