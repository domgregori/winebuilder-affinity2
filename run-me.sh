#!/usr/bin/env bash

# Debugging
# trap "set +x; sleep 2; set -x" DEBUG
JOBS=1
WINE_V="8.14"
ELEMENTALWARRIOR_BRANCH="affinity-photo2-wine8.14"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# check if user in docker group
DOCKER_SUDO="sudo"
if (getent group docker | grep -qw "$USER"); then
  DOCKER_SUDO=""
fi

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
  cd wine-source
  git switch $ELEMENTALWARRIOR_BRANCH
  mkdir "$SCRIPT_DIR"/wine-source/wine-build "$SCRIPT_DIR"/wine-source/wine-install
  cd "$SCRIPT_DIR"
}

build_docker(){
  echo "Building docker enviroment..."
  echo
  $DOCKER_SUDO docker compose build
}

start_docker(){
  echo "Starting docker container..."
  echo
  $DOCKER_SUDO docker compose up -d
}

stop_docker(){
  echo "Stopping docker container..."
  echo
  $DOCKER_SUDO docker compose down -t 0
}

make_wine(){
  echo "Making wine. This takes 1-2hrs..."
  echo
  sleep 3
  
  $DOCKER_SUDO docker compose exec -w /wine-source/wine-build builder /wine-source/configure --prefix=/wine-source/wine-install --enable-archs=i386,x86_64
  $DOCKER_SUDO docker compose exec -w /wine-source/wine-build builder make -j $JOBS
}

wine_binaries(){
  echo "Make wine Binaries..."
  echo
  $DOCKER_SUDO docker compose exec -w /wine-source/wine-build builder make install
}

install_wine(){
  echo "Installing Wine to /opt/wines/ElementalWarrior-$WINE_V..."
  echo
  sudo mkdir /opt/wines
  sudo cp -r "$SCRIPT_DIR"/wine-source/wine-install /opt/wines/ElementalWarrior-$WINE_V
  sudo ln -s /opt/wines/ElementalWarrior-$WINE_V/bin/wine /opt/wines/ElementalWarrior-$WINE_V/bin/wine64
}

install_rum(){
  echo "Getting rum..."
  echo
  git clone https://gitlab.com/xkero/rum /tmp/rum
  sudo cp /tmp/rum/rum /usr/bin/rum
  rm -rf /tmp/rum
}

setup_wine(){
  echo "Setting up wine..."
  echo
  /usr/bin/rum ElementalWarrior-$WINE_V "$HOME/.wineAffinity" wineboot --init
  /usr/bin/rum ElementalWarrior-$WINE_V "$HOME/.wineAffinity" winetricks dotnet48 corefonts vcrun2015
  /usr/bin/rum ElementalWarrior-$WINE_V "$HOME/.wineAffinity" wine winecfg -v win11
}

add_winmd(){
  while [ -z "$(/bin/ls $SCRIPT_DIR/add-Winmd-files-here)" ]; do
    echo "Winmd files need to be added to \"add-Winmd-files-here\" folder"
    read -p "Press Enter after adding files."
  done

  echo "Adding Winmd files..."
  echo
  cp -r "$SCRIPT_DIR/add-Winmd-files-here" "$HOME/.wineAffinity/drive_c/windows/system32/WinMetadata"
}

install_affinity(){
  while [ -z "$(/bin/ls $SCRIPT_DIR/add-affinity-installer-here)" ]; do
    echo "Intaller not found. Add it to \"add-affinity-installer-here\" folder"
    read -p "Press Enter after adding installer."
  done
  AFFINITY_EXE="$(/bin/ls $SCRIPT_DIR/add-affinity-installer-here/*.exe)"
  for exe in "$AFFINITY_EXE"; do
    /usr/bin/rum ElementalWarrior-$WINE_V "$HOME/.wineAffinity" wine "$exe"
  done
}

test_affinity(){
  while true; do
      read -p "Test Affinity Photo? [y/n] " yn
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
  /usr/bin/rum ElementalWarrior-$WINE_V "$HOME/.wineAffinity" wine "$HOME/.wineAffinity/drive_c/Program Files/Affinity/Photo 2/Photo.exe";
  echo
  read -p "Press Enter after done testing."
}

switch_vulkan(){
  while true; do
      read -p "Did Affinity have visual glitches? Would you like to try switching to Vulkan render? [y/n] " yn
      case $yn in
          [Yy]* ) _switch_vulkan;
                  break;;
          [Nn]* ) break;;
          * ) echo "y or n";;
      esac
  done
}

_switch_vulkan(){
  while true; do
    read -p "Change render to Vulkan or GL, or cancel: [v/g/x] " gl
      case $gl in
          [Vv]* ) echo "Switching to Vulkan"
                  /usr/bin/rum ElementalWarrior-$WINE_V $HOME/.wineAffinity winetricks renderer=vulkan;
                  break;;
          [Gg]* ) echo "Switching to GL" 
                  /usr/bin/rum ElementalWarrior-$WINE_V $HOME/.wineAffinity winetricks renderer=gl;
                  break;;
          [Xx]* ) break;;
          * ) echo "v, g, or x";;
      esac
  done
  echo
  while true; do
      read -p "Test Affinity Photo again? [y/n] " yn
      case $yn in
          [Yy]* ) _test_affinity;
                  break;;
          [Nn]* ) break;;
          * ) echo "y or n";;
      esac
  done

}

create_shortcuts(){
  while true; do
      read -p "Create Shortcuts? [y/n] " yn
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

  echo "Exec=/usr/bin/rum ElementalWarrior-$WINE_V $HOME/.wineAffinity wine '$HOME/.wineAffinity/drive_c/Program Files/Affinity/Photo 2/Photo.exe'" >> "$HOME/.local/share/applications/Affinity Photo.desktop"
}

cleanup(){
  while true; do
    read -p "Clean up docker and files? (Only do this if Affinity is working.) [y/n] " yn
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
  echo "Removing docker and folders"
  cd "$SCRIPT_DIR"
  $DOCKER_SUDO docker compose down --remove-orphans -v --rmi all
  cd ..
  sudo rm -rf "$SCRIPT_DIR"
}

change_jobs(){
  read -p "How many threads for building wine: " num
  re='^[0-9]+$'
  if [[ $num =~ $re ]]; then
    JOBS=$num
  fi
  main
}

full_script(){
  install_deps
  get_wine_source
  build_docker
  start_docker
  make_wine
  make_wine32
  wine32_binaries
  wine_binaries
  install_wine
  install_rum
  setup_wine
  add_winmd
  install_affinity
  test_affinity
  switch_vulkan
  create_shortcuts
}

main(){
  while true; do
      echo "  ########## Full script choose 'A' ##########"
      echo "  Get Wine-Source............................1"
      echo "  Build Docker...............................2"
      echo "  Start Docker...............................3"
      echo "  Make Wine..................................4"
      echo "  Create Wine Binaries.......................5"
      echo "  Install Wine on System.....................6"
      echo "  Install rum on System......................7"
      echo "  Setup Wine Enviroment......................8"
      echo "  Add Winmd Files............................9"
      echo "  Install Affinity...........................B"
      echo "  Install Dependencies.......................C"
      echo "  Test Affinity..............................D"
      echo "  Switch Between Vulkan/GL...................E"
      echo "  Create Launcher Shortcuts..................F"
      echo "  Stop Docker Container......................G"
      echo "  Change # of threads to use.................J"
      echo "  Clean up docker/files......................X"
      echo "  Quit Script................................Q"
      echo
      echo "  Full Script................................A"
      echo
      echo "  *Note:  If not in the docker group, sudo will be used*"
      echo

      read -p "Choice[A]: " ans
      case $ans in
          [Aa]* ) echo "Running Full Script";
                  full_script;
                  break;;
          [1]* )  get_wine_source;
                  break;;
          [2]* )  build_docker;
                  break;;
          [3]* )  start_docker;
                  break;;
          [4]* )  make_wine;
                  break;;
          [5]* )  wine_binaries;
                  break;;
          [6]* )  install_wine;
                  break;;
          [7]* )  install_rum;
                  break;;
          [8]* )  setup_wine;
                  break;;
          [9]* )  add_winmd;
                  break;;
          [Bb]* ) install_affinity;
                  break;;
          [Cc]* ) install_deps;
                  break;;
          [Dd]* ) _test_affinity;
                  break;;
          [Ee]* ) _switch_vulkan;
                  break;;
          [Ff]* ) _create_shortcuts;
                  break;;
          [Gg]* ) stop_docker;
                  break;;
          [Jj]* ) change_jobs;
                  break;;
          [Xx]* ) _cleanup;
                  break;;
          [Qq]* ) echo "Bye!!";
                  exit;;
          * )     full_script;
                  break;;
      esac
  done
}

clear
echo " █████  ███████ ███████ ██ ███    ██ ██ ████████ ██    ██     ";
echo "██   ██ ██      ██      ██ ████   ██ ██    ██     ██  ██      ";
echo "███████ █████   █████   ██ ██ ██  ██ ██    ██      ████       ";
echo "██   ██ ██      ██      ██ ██  ██ ██ ██    ██       ██        ";
echo "██   ██ ██      ██      ██ ██   ████ ██    ██       ██        ";
echo "                                                              ";
echo "                                                              ";
echo "██     ██ ██ ███    ██ ███████                                ";
echo "██     ██ ██ ████   ██ ██                                     ";
echo "██  █  ██ ██ ██ ██  ██ █████                                  ";
echo "██ ███ ██ ██ ██  ██ ██ ██                                     ";
echo " ███ ███  ██ ██   ████ ███████                                ";
echo "                                                              ";
echo "                                                              ";
echo "██████  ██    ██ ██ ██      ██████  ███████ ██████            ";
echo "██   ██ ██    ██ ██ ██      ██   ██ ██      ██   ██           ";
echo "██████  ██    ██ ██ ██      ██   ██ █████   ██████            ";
echo "██   ██ ██    ██ ██ ██      ██   ██ ██      ██   ██           ";
echo "██████   ██████  ██ ███████ ██████  ███████ ██   ██           ";
echo

main
