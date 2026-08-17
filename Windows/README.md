# Windows scripts

Standard Windows scripts live here. Anything dropped in this folder is picked up
automatically and listed in the [root README](../README.md).

Give each script a description header so it gets a useful label:

```powershell
# Description: Install the thing
# Platform: Windows
```

Scripts here are listed with a PowerShell run command:

```powershell
irm https://raw.githubusercontent.com/sanjaykshebbar/lazy-code/main/Windows/<script>.ps1 | iex
```

For Windows scripts packaged for Intune deployment, use `Intune/Windows/` instead.
