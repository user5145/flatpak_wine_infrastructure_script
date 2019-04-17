#!/bin/bash
set -e
if [ -z "$4" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
        echo "
this script tries to be helpful during wine setup inside flatpak.
it runs extensions installers, stops if return value is different than 0,
allows for custom launchers and starts the main install script for your game. Basically can be used to not reimplement all the time the same code
when experimenting with winepack and/or flatpak
        
The first parameter points to a file which existence prevents game's installer from activation (e.g. game files)
The second parameter points to the installation script
The third parameter is a bash expression which points to extensions install scripts (e.g. /app/extensions/*/bin/install.sh),
they have to validate by themselves if they have to do something or not because they run on every startup
The fourth parameter does basically what the third does, though it allows different extensions to coexist
by executing the first script returned by bash (e.g. /app/extensions/*/bin/start.sh) after they were set up. It is for custom launchers
        
example can be used like that 
setup_infrastructure.sh \"${WINEPREFIX}/Game.exe\" \"/app/bin/installer\" \"/app/extensions/*/bin/installer\" \"/app/extensions/*/bin/starter\" "
        exit 0
fi

#install if file doesn't exist
if ! [ -e "$1" ] ; then
     echo "installing $2"
     source "$2"
     if [[ $? != 0 ]]; then
         echo "Installation failed, aborting."
         exit $?
     fi
fi

# install extensions
# for every installer in extensions/*/bin test if any exists and run it
for f in $3 ; do
      test -f "$f" && source "$f"
      # close if the scripts request it
      if [[ $? != 0 ]]; then
           echo "error code $? forced the script to stop."
           exit $?
      fi
done

# start extensions
for f in $4 ; do
      test -f "$f" && source "$f"
done
