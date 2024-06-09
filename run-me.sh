#!/usr/bin/env bash

# Debugging
#trap "set +x; sleep 5; set -x" DEBUG

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# check if user in docker group
DOCKER_SUDO="sudo"
if $(getent group docker | grep -vqw "$USER"); then
  DOCKER_SUDO=""

install_deps(){
  echo "Installing dependencies, sudo will be used"
  echo
  sudo apt update
  sudo apt install winetricks
  sudo apt install docker-ce docker-ce-cli docker-buildx-plugin
}

get_wine_source(){
  echo "Getting wine source from ElementalWarrior fork for Affinity..."
  echo
  git submodule update --init --progress
  mkdir "$SCRIPT_DIR"/wine-source/wine32-build "$SCRIPT_DIR"/wine-source/wine64-build "$SCRIPT_DIR"/wine-source/wine-install
}

build_docker(){
  echo "Building docker enviroment..."
  echo
  "$DOCKER_SUDO"docker compose build
}

start_docker(){
  echo "Starting docker container..."
  echo
  "$DOCKER_SUDO"docker compose up -d
}

stop_docker(){
  echo "Stopping docker container..."
  echo
  "$DOCKER_SUDO"docker compose down -t 0
}

make_wine64(){
  echo "Making Wine64. This takes 2-3hrs..."
  echo
  sleep 3
  "$DOCKER_SUDO"docker compose exec -w /wine-source/wine64-build builder /wine-source/configure --prefix=/wine-source/wine-install --enable-win64 
  "$DOCKER_SUDO"docker compose exec -w /wine-source/wine64-build builder make
}

make_wine32(){
  echo "Making Wine32. This takes another 2-3hrs..."
  echo
  sleep 3
  "$DOCKER_SUDO"docker compose exec -w /wine-source/wine32-build builder PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig /wine-source/configure --with-wine64=/wine-source/wine64-build --prefix=/wine-source/wine-install
  "$DOCKER_SUDO"docker compose exec -w /wine32-build builder make
}

wine32_binaries(){
  echo "Make Wine32 Binaries..."
  echo
  cd "$SCRIPT_DIR"/wine-source/wine32-build
  make install
}

wine64_binaries(){
  echo "Make Wine64 Binaries..."
  echo
  cd $SCRIPT_DIR/wine-source/wine64-build
  make install
}

install_wine(){
  echo "Installing Wine to /opt/wines/ElementalWarrior..."
  echo
  sudo mkdir /opt/wines
  sudo cp -r "$SCRIPT_DIR"/wine-source/wine-install /opt/wines/ElementalWarrior
}

install_rum(){
  echo "Getting rum..."
  echo
  git clone https://gitlab.com/xkero/rum /tmp/rum
  sudo cp /tmp/rum/rum /usr/bin/rum
  rm -rf /tmp/rum
}

setup_wine(){
  echo "Installing dotnet 48 and corefonts with winetricks..."
  echo
  /usr/bin/rum ElementalWarrior "$HOME/.WineAffinity" winetricks dotnet48 corefonts

  echo "Setting Win version to 11..."
  echo 
  /usr/bin/rum ElementalWarrior "$HOME/.WineAffinity" wine winecfg -v win11
}

add_winmd(){
  while [ -z "$(ls $SCRIPT_DIR/add-Winmd-files-here)" ]; do
    echo "Winmd files need to be added to \"add-Winmd-files-here\" folder"
    read -p "Press any key after adding files."
  done

  echo "Adding Winmd files..."
  echo
  cp -r "$SCRIPT_DIR/add-Winmd-files-here" "$HOME/.WineAffinity/drive_c/Windows/System32/WinMetadata"
}

install_affinity(){
  while [ -z "$(ls $SCRIPT_DIR/add-affinity2.0.4-installer-here)" ]; do
    echo "Intaller not found. Add it to \"add-affinity2.0.4-installer-here\" folder"
    echo "File name must have affinity and 2.0.4 and exe in its name."
    read -p "Press any key after adding installer."
  done
  AFFINITY_EXE="$SCRIPT_DIR/add-affinity2.0.4-installer-here/$(ls -A *ffinity*2.0.4*.exe)"
  /usr/bin/rum ElementalWarrior "$HOME/.WineAffinity" wine "$AFFINITY_EXE"
}

test_affinity(){
  while true; do
      read -p "Test Affinity Photo?" yn
      case $yn in
          [Yy]* ) _test_affinity;
                  break;;
          [Nn]* ) break;;
          * ) echo "y or n";;
      esac
  done
}

_test_affinity(){
  echo "Starting Affinity Photo";
  /usr/bin/rum ElementalWarrior "$HOME/.WineAffinity" wine "$HOME/.WineAffinity/drive_c/Program Files/Affinity/Photo 2/Photo.exe" 2>/dev/null;
  echo
  read -p "Press any key after done testing..."
}

test_affinity_vulkan(){
while true; do
    read -p "Visual Glitches in Affinity; Try with Vulkan?" yn
    case $yn in
        [Yy]* ) _test_affinity_vulkan;
                break;;
        [Nn]* ) break;;
        * ) echo "y or n";;
    esac
done
}

_test_affinity_vulkan(){
  echo "Starting Affinity Photo with Vulkan";
  /usr/bin/rum ElementalWarrior "$HOME/.WineAffinity" winetrick "$HOME/.WineAffinity/drive_c/Program Files/Affinity/Photo 2/Photo.exe" renderer=vulkan 2>/dev/null;
  echo
  read -p "Press any key after done testing..."
}

create_shortcuts(){
  while true; do
      read -p "Create Shortcuts?" yn
      case $yn in
          [Yy]* ) _create_shortcuts;
                  break;;
          [Nn]* ) break;;
          * ) echo "y or n";;
      esac
  done
}

_create_shortcuts(){
  echo "[Desktop Entry]" >> "$HOME/.local/share/applications/Affinity Photo.desktop"
  echo "Name=Affinity Photo" >> "$HOME/.local/share/applications/Affinity Photo.desktop"
  echo "Icon=" >> "$HOME/.local/share/applications/Affinity Photo.desktop"
  echo "Comment=" >> "$HOME/.local/share/applications/Affinity Photo.desktop"
  echo "Categories=Graphics" >> "$HOME/.local/share/applications/Affinity Photo.desktop"
  echo "Terminal=false" >> "$HOME/.local/share/applications/Affinity Photo.desktop"
  echo "Type=Application" >> "$HOME/.local/share/applications/Affinity Photo.desktop"

  echo "Exec=/usr/bin/rum ElementalWarrior $HOME/.WineAffinity wine \'$HOME.WineAffinity/drive_c/Program Files/Affinity/Photo 2/Photo.exe\'" >> "$HOME/.local/share/applications/Affinity Photo.desktop"
}

cleanup(){
  while true; do
    read -p "Clean up docker and files? (Only do this if Affinity is working.)" yn
      case $yn in
          [Yy]* ) _cleanup;
                  break;;
          [Nn]* ) echo "Leaving docker enviroment and wine build folders";
                  break;;
          * ) echo "y or n";;
      esac
  done
}

_cleanup(){
  echo "Removing docker and folders";
  cd "$SCRIPT_DIR";
  docker compose down --remove-orphans -v --rmi all;
  cd ..;
  rm -rf "$SCRIPT_DIR";
}

full_script(){
  install_deps
  get_wine_source
  build_docker
  start_docker
  make_wine64
  make_wine32
  wine32_binaries
  wine64_binaries
  install_wine
  install_rum
  setup_wine
  add_winmd
  install_affinity
  test_affinity
  test_affinity_vulkan
  create_shortcuts
}

echo
echo
echo "     _     __  __ _       _ _          __        ___             "
echo "    / \   / _|/ _(_)_ __ (_) |_ _   _  \ \      / (_)_ __   ___  "
echo "   / _ \ | |_| |_| | '_ \| | __| | | |  \ \ /\ / /| | '_ \ / _ \ "
echo "  / ___ \|  _|  _| | | | | | |_| |_| |   \ V  V / | | | | |  __/ "
echo " /_/   \_\_| |_| |_|_| |_|_|\__|\__, |    \_/\_/  |_|_| |_|\___| "
echo "               ___           _  |___/ _ _                        "
echo "              |_ _|_ __  ___| |_ __ _| | | ___ _ __              "
echo "               | || '_ \/ __| __/ _\` | | |/ _ \ '__|            "
echo "               | || | | \__ \ || (_| | | |  __/ |                "
echo "              |___|_| |_|___/\__\__,_|_|_|\___|_|                "
echo "                                                                 "
echo
echo
echo


while true; do
    echo "   ######### Full script choose 'A' ###########"
    echo "   A................................Full Script"
    echo "   1............................Get Wine-Source"
    echo "   2...............................Build Docker"
    echo "   3...............................Start Docker"
    echo "   4................................Make Wine64"
    echo "   5................................Make Wine32"
    echo "   6.....................Create Wine32 Binaries"
    echo "   7.....................Create Wine64 Binaries"
    echo "   8.....................Install Wine on System"
    echo "   9......................Install rum on System"
    echo "   B......................Setup Wine Enviroment"
    echo "   C............................Add Winmd Files"
    echo "   D...........................Install Affinity"
    echo "   E.......................Install Dependencies"
    echo "   F..............................Test Affinity"
    echo "   G..................Test Affinity with Vulkan"
    echo "   H..................Create Launcher Shortcuts"
    echo "   I......................Stop Docker Container"
    echo "   X......................Clean up docker/files"
    echo

    read -p "Choice: " ans
    case $ans in
        [Aa]* ) echo "Running Full Script";
                full_script
                break;;
        [1]* )  get_wine_source;
                break;;
        [2]* )  build_docker;
                break;;
        [3]* )  start_docker;
                break;;
        [4]* )  make_wine64;
                break;;
        [5]* )  make_wine32;
                break;;
        [6]* )  wine32_binaries;
                break;;
        [7]* )  wine64_binaries;
                break;;
        [8]* )  install_wine;
                break;;
        [9]* )  install_rum;
                break;;
        [Bb]* ) setup_wine;
                break;;
        [Cc]* ) add_winmd;
                break;;
        [Dd]* ) install_affinity;
                break;;
        [Ee]* ) install_deps;
                break;;
        [Ff]* ) _test_affinity;
                break;;
        [Gg]* ) _test_affinity_vulkan;
                break;;
        [Hh]* ) _create_shortcuts;
                break;;
        [Ii]* ) stop_docker;
                break;;
        [Xx]* ) _cleanup;
                break;;
        * ) echo "Not a valid choice.";;
    esac
done
