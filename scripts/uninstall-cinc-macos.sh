#!/bin/sh

if [ $(osascript -e 'application "Cinc Foundation" is running') = 'true' ]; then
  echo "Closing Cinc Foundation..."
  sudo osascript -e 'quit app "Cinc Foundation"' > /dev/null 2>&1;
fi
echo "Uninstalling Cinc Foundation..."
echo "  -> Removing files..."
sudo rm -rf '/opt/cinc'
sudo rm -rf '/Applications/Cinc Foundation.app'
echo "  -> Removing binary links in /usr/local/bin..."
sudo find /usr/local/bin -lname '/opt/cinc/*' -delete
echo "  -> Forgeting com.cinc-project.pkg.cinc-foundation package..."
sudo pkgutil --forget com.cinc-project.pkg.cinc-foundation > /dev/null 2>&1;
echo "Cinc Foundation Uninstalled."
