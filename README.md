# winebuilder for Affinity 2.0.4

🍷 Wine build environment with Docker using ElementalWarrior fork of wine https://gitlab.winehq.org/ElementalWarrior/wine

Script is based off this post: https://forum.affinity.serif.com/index.php?/topic/182758-affinity-suite-v204-on-linux-wine/

As well as this fork from https://github.com/castaneai/winebuilder

## Clone repo
```git clone https://github.com/domgregori/winebuilder-affinity2.git```
```cd winebuilder-affinity2```

## Add Installer
Add Affinity installer to ```add-affinity2.0.4-installer-here```

## Add Winmd files
***you will need a to get Winmd files from a windows virtual machine, partition or from a friend***

Located in ```C:/Windows/System32/WinMetadata```

Files inside of ```WinMetadata``` need to be coppied to ```add-Winmd-files-here```


## Run Scipt
in the ```winebuilder-affinity2``` folder run script

```./run-me.sh```

To run the full script, choose ```A```
