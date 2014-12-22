#!/bin/bash

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi
if [ -f ~/.profile ]; then
  source ~/.profile
fi

PATH=/usr/local/bin:/usr/local/homebrew/bin:$PATH

action=$1
query=$2

function installed_brews {
  installed_brews=$(brew list|sed -e 's/^[ \t]*/ /')
}

case "$action" in
  home)
    brew home $query
  ;;

  notify)
    installed_brews
    if [[ $installed_brews =~ (^|[[:space:]])$query($|[[:space:]]) ]]; then
      echo Uninstalling $query
    else
      echo Installing $query
    fi
  ;;

  execute)
    sleep 2
    installed_brews
    if [[ $installed_brews =~ (^|[[:space:]])$query($|[[:space:]]) ]]; then
      brew uninstall $query > /dev/null
      if [ $? -eq 0 ]; then
        echo ✓ $query has been uninstalled
        exit 0
      fi

      echo ✗ failed to uninstall $query
      exit 0
    fi

    brew install $query > /dev/null
    if [ $? -eq 0 ]; then
      echo ✓ $query has been installed
      exit 0
    fi

    echo ✗ failed to install $query
  ;;

  list)
    # Search local repo to not get IP-blocked by github
    results=$(ls $(brew --prefix)/Library/Formula | sed "s/\.rb$//" | grep -E "^$query(.*)$")
    installed_brews

    out=""; count=0
    for brew in $results; do
      count=$((count+1))
      if [ $count -gt 20 ]; then break; fi

      title=$brew
      subtitle="Install formula"
      icon="icon-install.png"
      if [[ $installed_brews =~ (^|[[:space:]])$brew($|[[:space:]]) ]]; then
        title="$title [installed]" #✓
        subtitle="Uninstall formula"
        icon="icon-uninstall.png"
      fi

        out+="<item arg=\"$brew\" uid=\"brew-$(date +%s)\" valid=\"yes\">\
                <title>$title</title>\
                <subtitle>$subtitle (⌘+enter to open homepage)</subtitle>\
                <icon>$icon</icon>\
            </item>"
    done
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><items>$out</items>"
  ;;

esac
