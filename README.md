# Winebuilder For Affinity

Docker container and script for building ElementalWarrior's fork of wine [link](https://gitlab.winehq.org/ElementalWarrior/wine)

ElementalWarrior's fork will run Affinity Photo/Designer/Publisher

Script is based off this [site](https://codeberg.org/Wanesty/affinity-wine-docs)

Docker container is a fork of [winebuilder](https://github.com/castaneai/winebuilder)
<br/><br/>

# Dependencies
`sudo apt update && sudo apt install git`

I'm running on Ubuntu 22

Also `docker`, `winetricks` are needed and can be installed with script
<br/><br/>

## Clone repo
`git clone https://github.com/domgregori/winebuilder-affinity2.git && cd winebuilder-affinity2`
<br/><br/>

## Add Installer
Add Affinity msi .exe installer to `add-affinity-installer-here` folder

Installer can be downloaded from Serif site [here](https://store.serif.com/en-us/update/windows/photo/2/)
<br/><br/>

## Add Winmd files
**you will need a to get Winmd files from a windows virtual machine, partition or from a friend**

Located in `C:/Windows/System32/WinMetadata`

*.winmd files inside of `WinMetadata` need to be copied to `add-Winmd-files-here` folder
<br/><br/>

## Run Scipt
run `./run-me.sh`

To run the full script, choose `A`

<br/><br/>

# Why
Having the right building dependencies can be a nightmare especially with multiple architectures. This docker container makes it much eaiser.

ElementalWarrior forked the wine source to make a version that works with Affinity but it needs to be built.

Created the script to make the process more cohesive.
