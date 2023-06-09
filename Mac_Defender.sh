#!/bin/bash

echo "***********************************************"
echo "This script changes the computer name to either XXXX-SERIALNUM or your preference"
echo "It changes the time server to time.uottawa.ca"
echo "Deactivate Filevault (encryption if active)"
echo "Removes Sophos if present"
echo "Checks whether the uOttawa MDM profile is installed, if not, installs Company Portal using this script https://github.com/microsoft/shell-intune-samples/blob/master/macOS/Apps/Company%20Portal/installCompanyPortal.sh"
echo "     "
echo "if this script fails to run, use: xattr -d com.apple.quarantine Mac_provisioning.sh  "
echo "***********************************************"

#Get the Mac serial number
serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
current_name=$(scutil --get ComputerName)

#Display the Mac Serial number
echo "This Mac has the following serial number: $serial"
echo "it is also named: $current_name"
echo "***********************************************" 

#Prompt user for computer name option
echo "Do you want to use a basic 4 digit Prefix (e.g. 1803, 2101, 3700, etc.)" 
read -p "Or customize the computer name to your liking? (BASIC/CUSTOM): " answer

#If user chooses to use a 4-digit Banner code
if [ "$answer" == "BASIC" ] || [ "$answer" == "basic" ]; then

#Prompt user for 4-digit number
read -p "Enter a 4-digit number for the prefix: " XXXX

#Append serial number to computer name in this form BANN-SERIAL
computer_name="$XXXX-$serial"
if [ ${#computer_name} -gt 15 ]; then
computer_name=${computer_name:0:15}
fi

else
#Prompt user for computer name
read -p "Enter a custom name for this computer: " computer_name
fi

#Set the Mac Name to this result and display it
echo "***********************************************"
echo "Trying to set computer name to: $computer_name ..."
sudo scutil --set ComputerName "$computer_name"
sudo scutil --set HostName "$computer_name"
sudo scutil --set LocalHostName "$computer_name"

#check if name is correctly applied
Echo "Computer name is now:"
sudo scutil --get ComputerName


# Set time server and update time
echo "***********************************************"
echo "Setting Time server to time.uottawa.ca"
sudo systemsetup -setusingnetworktime on
sudo systemsetup -setnetworktimeserver time.uottawa.ca &> /dev/null
sudo sntp time.uottawa.ca


# Remove Sophos
echo "***********************************************"
echo "Removing Sophos if present"

# Search for InstallationDeployer in /Applications/Remove Sophos Endpoint.app/Contents/MacOS/tools
if [[ -f "/Applications/Remove Sophos Endpoint.app/Contents/MacOS/tools/InstallationDeployer" ]]; then
  echo "InstallationDeployer found in /Applications/Remove Sophos Endpoint.app/Contents/MacOS/tools"
  sudo "/Applications/Remove Sophos Endpoint.app/Contents/MacOS/tools/InstallationDeployer" --force_remove
  exit 0
fi

# Search for InstallationDeployer in /Applications/Sophos/Remove Sophos Endpoint.app/Contents/MacOS/tools
if [[ -f "/Applications/Sophos/Remove Sophos Endpoint.app/Contents/MacOS/tools/InstallationDeployer" ]]; then
  echo "Sophos found. Uninstalling..."
  sudo "/Applications/Sophos/Remove Sophos Endpoint.app/Contents/MacOS/tools/InstallationDeployer" --force_remove
fi

# If InstallationDeployer not found in either location, print error message and exit with error code
echo "Sophos not installed"
echo "***********************************************" 

# Check if FileVault is enabled
fv_status=$(fdesetup status)
if [[ $fv_status == "FileVault is On." ]]; then
    # Fetch the current logged-in user
    current_user=$(ls -l /dev/console | awk '{ print $3 }')
    # Prompt the user to decrypt the drive
    read -p "FileVault is currently enabled. Do you want to decrypt the drive? (mandatory to get it enabled by Defender) (y/n) " choice
    case "$choice" in 
        y|Y ) echo "$password" | sudo -S fdesetup disable -user "$current_user";;
        n|N ) echo "Drive will remain encrypted.";;
        * ) echo "Invalid choice. Please enter y or n.";;
    esac
else
    echo "FileVault is currently disabled."
    echo "***********************************************" 
fi

echo "***********************************************" 
echo "Do you want to check for uOttawa MDM Profile? (y/n)"
read answer

if [ "$answer" == "y" ]; then
  if [ -f "/private/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound" ]; then
    if grep -q "ottawa" "/private/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound"; then
    echo "***********************************************"
    echo "Once the Profile has been installed through Company portal"
    echo "Add $computer_name to the Defender Group (might not be available instantly)."
    echo "***********************************************"
    else
      echo "uOttawa MDM Profile not found."
    echo "Do you want to install Company Portal app (which will require manual intervention)? (y/n)"
      read install_answer
      if [ "$install_answer" == "y" ]; then
        # Download and run the Company Portal installation script
        sudo curl https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/macOS/Apps/Company%20Portal/installCompanyPortal.sh | sudo bash &> /dev/null

        # Open the Company Portal app
        open "/Applications/Company Portal.app"

# /Applications/Company Portal.app/Contents
      fi
    fi
  else
    echo "uOttawa MDM Profile not found."
    echo "Do you want to install Company Portal app (which will require manual intervention)? (y/n)"
    read install_answer
    if [ "$install_answer" == "y" ]; then
      # Download and run the Company Portal installation script
      sudo curl https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/macOS/Apps/Company%20Portal/installCompanyPortal.sh | sudo bash &> /dev/null

      # Open the Company Portal app#
      open "/Applications/Company Portal.app"
    fi
    echo "***********************************************"
    echo "Once the Profile has been installed through Company portal"
    echo "Add $computer_name to the Defender Group (might not be available instantly)."
    echo "***********************************************"
  fi
fi