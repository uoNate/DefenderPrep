#!/bin/bash
Clear
echo "***********************************************"
echo "This script changes the computer name to your preference"
echo "Deactivate Filevault (encryption if active)"
echo "Removes Sophos if present"
echo "Checks whether the uOttawa MDM profile is installed, if not, installs Company Portal using this script https://github.com/microsoft/shell-intune-samples/blob/master/macOS/Apps/Company%20Portal/installCompanyPortal.sh"
echo "It finally asks if you want to create the Computer object in AD, under Faculties/FACULTY_NAME/Computers"
echo "and bind the Mac to this object."
echo "You can also accept to add the proper GG_F_Deskside_Admin group for administration"
echo "     "
echo "if this script fails to run, use: xattr -d com.apple.quarantine Mac_provisioning.sh  "
echo "***********************************************"

bold=$(tput bold)
normal=$(tput sgr0)
#Get the Mac serial number
serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
current_name=$(scutil --get ComputerName)

#Display the Mac Serial number
echo "${bold}Mac Serial Number: $serial${normal}"
echo "Current name: ${bold}$current_name${normal}"
echo "***********************************************"
read -p "Do you want to rename your computer? (y (auto.)/n/custom): " response

if [[ "$response" == "" || "$response" == "y" ]];
then
    # Prompt the user for a prefix (required)
    read -p "Enter a prefix for the computer name (2101, 1803-CV, etc.): " prefix
    # Prompt the user for a suffix (optional)
    read -p "Enter a suffix for the computer name (-prf, -P, etc.), hit Return for no suffix: " suffix
    
    # If the user didn't enter anything for the suffix, set it to empty
    if [[ "$suffix" == "" ]]; then
        addsuffix="n"
    else
        addsuffix="y"
    fi

    # Trim the serial number if necessary to ensure the total character limit is 15
    if [[ "$addsuffix" == "y" ]]; then
        namelength=$(( ${#prefix} + ${#serial} + ${#suffix} + 2 ))
        if [[ "$namelength" -gt 15 ]]; then
            serial=$(echo "$serial" | cut -c 1-$(( 15 - ${#prefix} - ${#suffix} - 2 )))
        fi
    else
        namelength=$(( ${#prefix} + ${#serial} + 1 ))

        if [[ "$namelength" -gt 15 ]]; then
            serial=$(echo "$serial" | cut -c 1-$(( 15 - ${#prefix} - 1 )))
        fi
    fi

    # Create the computer name using the prefix, serial number, and suffix (if applicable)
    if [[ "$addsuffix" == "y" ]]; then
        name="$prefix-$serial-$suffix"
    else
        name="$prefix-$serial"
    fi

    # Remove any double dashes in the name
    name=$(echo "$name" | sed 's/--/-/g')

    # Check for double dashes due to prefix or suffix
    while [[ "$name" == *"--"* ]]; do
        name=$(echo "$name" | sed 's/--/-/g')
    done

# Ask the user to confirm the name
echo "The computer will be set to: $name" 
read -p "Is this name correct? (y/n): " confirm

# If the user confirms the name, set the computer name
if [[ "$confirm" == "y" ]]; then
    sudo scutil --set ComputerName "$name"
    sudo scutil --set HostName "$name"
    sudo scutil --set LocalHostName "$name"
    dscacheutil -flushcache
   echo "The computer name has been set to: $name"
else
    echo "The computer name has not been changed."
fi

elif [ "$response" = "custom" ]; then
  read -p "Enter a custom name for this computer (max 15 characters): " custom_name
  while [[ ${#custom_name} -gt 15 ]]; do
    read -p "Name must be 15 characters or less. Please enter a custom name: " custom_name
  done
  echo "The computer name you've entered is: ${bold}$custom_name${normal}."
  read -p "Is this correct? (y/n): " confirm_name
  if [[ $confirm_name =~ ^[Yy]$ ]]; then
    computer_name="$custom_name"
    echo "The new computer name will be: ${bold}$computer_name${normal}."
    read -p "Do you want to proceed with changing the computer name? (y/n): " confirm_change
    if [[ $confirm_change =~ ^[Yy]$ ]]; then
      sudo scutil --set ComputerName "$computer_name"
      sudo scutil --set HostName "$computer_name"
      sudo scutil --set LocalHostName "$computer_name"
      echo "The computer name has been changed to: ${bold}$computer_name${normal}."
    else
      echo "The computer name will remain: ${bold}$current_name${normal}."
    fi
  else
    echo "Please re-enter a custom name."
  fi
else
  echo "moving on"
fi

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
	clear
  if [ -f "/private/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound" ]; then
    if grep -q "ottawa" "/private/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound"; then
      echo "***********************************************"      
      echo "uOttawa MDM Profile found!"
      echo "Add $computer_name to the Defender Group (might not be available instantly)"
    else
      echo "uOttawa MDM Profile ${bold}not${normal} found."
      echo "Do you want to install Company Portal app (which will require manual intervention)? (y/n)"
      read install_answer
      if [ "$install_answer" == "y" ]; then
        # Download and run the Company Portal installation script
        sudo curl https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/macOS/Apps/Company%20Portal/installCompanyPortal.sh | sudo bash

        # Open the Company Portal app
        open "/Applications/Company Portal.app"

        echo "${bold}The Company Portal has opened to manually enrol this Mac. Were you successful in installing the profile?"
        echo -e "(Answering 'No' will delete Microsoft identity cache in the keychain, resulting in a requirement to login again onto the Microsoft Account$){normal} (y/n)"
        read install_success

        if [ "$install_success" == "n" ]; then
          security delete-internet-password -s msoCredentialSchemeADAL
	  security delete-generic-password -l 'com.microsoft.adalcache'

          echo -e "${bold}Please test the profile enrolment again. Did it work this time?${normal} (y/n)"
          read test_success

          if [ "$test_success" == "n" ]; then
            echo -e "Open Keychain Access (/Applications/Utilities), and manually delete everything that has 'identities', 'Microsoft', and 'adal' in the name."
            echo -e "Please test the profile enrolment again. Did it work this time? (y/n)"
            read test_success_again

            if [ "$test_success_again" == "n" ]; then
              echo -e "Please contact NateTech for further assistance."
            fi
          fi
        else
          echo "***********************************************"
          echo "Once the Profile has been installed through Company portal"
          echo "Add $computer_name to the Defender Group (might not be available instantly)."
          echo "***********************************************"
        fi
      fi
    fi
  else
    echo "uOttawa MDM Profile not found."
    echo "Do you want to install Company Portal app (which will require manual intervention)? (y/n)"
    read install_answer
    if [ "$install_answer" == "y" ]; then
      # Download and run the Company Portal installation script
      sudo curl https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/macOS/Apps/Company%20Portal/installCompanyPortal.sh | sudo bash

      # Open the Company Portal app
      open "/Applications/Company Portal.app"

      echo -e "${bold}The Company Portal has opened to manually enrol this Mac. Were you successful in installing the profile?${normal} (y/n)"
      read install_success

      if [ "$install_success" == "n" ]; then
        security delete-internet-password -s msoCredentialSchemeADAL # delete the internet password
        echo -e "${bold}Please try to enroll the profile again. Did it work this time?${normal} (y/n)" # ask the user to test the profile enrollment again
        read enroll_success

  if [ "$enroll_success" == "n" ]; then
    echo -e "${bold}Open Keychain access (/Applications/Utilities), and manually delete everything that has \"identities\", \"Microsoft\" and \"adal\" in the name. Did this solve the issue?${normal} (y/n)" # prompt the user to open Keychain Access and delete specific items
    read keychain_success

    if [ "$keychain_success" == "n" ]; then
      echo -e "${bold}Please contact Nathan for further assistance.${normal}" # prompt the user to contact Nathan if the issue still persists
    fi
  fi
fi


echo "***********************************************"
echo "Do you want to add this computer $computer_name to the Domain?"
echo " "
echo 'This will run the following command: sudo dsconfigad -add uottawa.o.univ -username "$ad_user" -ou "OU=Computers,OU=$FACULTY,OU=Faculties,DC=uottawa,DC=o,DC=univ" -computer '"$computer_name"' -force'
echo "(y/n):"
read answer

if [ "$answer" == "y" ]; then

    # Get Active Directory account name and BANN code
    echo "To bind this computer to AD, in its proper container, please select your Faculty Banner code:"
    options=("1100 - Telfer" "1200 - Arts" "1400 - Education" "1500 - Medicine" "1600 - HSS" "1700 - Sciences" "1800 - Engineering" "1900 - SCS" "2000 - GradStud" "2100 - Droit Civil" "2200 - Common Law")
    select opt in "${options[@]}"; do
    case $opt in
        "1200 - Arts")
            FACULTY="Arts"
            BANNER=1200
            break
            ;;
        "2200 - Common Law")
            FACULTY="Claw"
            BANNER=2200
            break
            ;;
        "2100 - Droit Civil")            
            FACULTY="DCivil"
            BANNER=2100
            break
            ;;
        "1400 - Education")
            FACULTY="Education"
            BANNER=1400
            break
            ;;
        "1800 - Engineering")
            FACULTY="Engineering"
            BANNER=1800
            break
            ;;
        "2000 - GradStud")
            FACULTY="GradStud" 
            BANNER=2000
            break
            ;;
        "1600 - HSS")
            FACULTY="HSS"
            BANNER=1600
            break
            ;;
        "1500 - Medicine")
            FACULTY="Medicine"
            BANNER=1500
            break
            ;;
        "1700 - Sciences")            
            FACULTY="Science"
            BANNER=1700
            break
            ;;
        "1900 - SCS")
            FACULTY="SCS"
            BANNER=1900
            break
            ;;
        "1100 - Telfer")            
            FACULTY="Telfer"
            BANNER=1100
            break
            ;;
        *) echo "Invalid option selected";;
    esac
    done

    # Bind to Active Directory
    read -p "Enter your Active Directory Account Name: " ad_user
    sudo dsconfigad -add uottawa.o.univ -username "$ad_user" -ou "OU=Computers,OU=$FACULTY,OU=Faculties,DC=uottawa,DC=o,DC=univ" -computer "$computer_name" -force

    # Add computer to admin groups
echo "     "
echo 'Do you want to add your DeskSide admin group to this computer'
    echo 'It would run the following command: sudo dsconfigad -groups "'$BANNER'_GG_F_Deskside_Admin,3700_GG_F_Deskside_Admin'
    echo "(y/n):"
    read answer

    if [ "$answer" == "y" ]; then
read -t 10 #waiting 10 seconds for proper binding before issuing next command...
    sudo dsconfigad -groups "${BANNER}_GG_F_Deskside_Admin,3700_GG_F_Deskside_Admin"
echo "Ending Script - Added to the domain, adding Admin groups"

    else echo "Ending Script - Added to the domain, without adding Admin groups"
fi
else echo "Ending Script - Not joined to Domain"
fi
fi
fi
fi
