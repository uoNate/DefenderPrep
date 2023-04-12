# DefenderPrep

**Mac_Defender.sh** is a script made to simplify the process of getting a Mac ready to enroll in Defender

### Computer Name:
This script changes the computer name to either XXXX-SERIALNUM or whatever of your preference. Choice offered : Basic/Custom
- Basic: you'll be prompted to enter 4 digits for your banner unit code. Entering **2101** for instance changes the Mac Name to **2101-SERIALNUM** and limits it to 15 characters
- Custom: it'll prompt the serial for easy access, so enter anything you want, like 1805-CV-ABC1234
  - *In the future, we could implement all the naming conventions into the script.*

### Time server and Sophos (automatic):
- Changes the time server to time.uottawa.ca
- Checks for Sophos and silently removes it if present.

### Drive encryption:
Since Intune must get the key to decrypt the drive, FileVault must be turned off, so Intune can re-enable it automatically and fetch the key while doing so.
- The script will prompt if you want to deactivate FileVault (disk encryption) if turned on.
  - /!\ Requires entering the admin password one more time
  
### Check whether the uOttawa MDM profile is installed, if not, installs Company Portal (manual operation follows).
  - checks for the presence of the profile file, and wheter it has the word ottawa in it or not. if either fails, installs Company portal.
    - it uses an external script made by Microsoft, located here: https://github.com/microsoft/shell-intune-samples/blob/master/macOS/Apps/Company%20Portal/installCompanyPortal.sh
    - the script checks and install multiple things: Microsoft auto-update, Company portal, Rosetta 2 if not already installed.

## If you only plan on preparing a Mac for Intune, you're done with the **Mac_Defender.sh** script, check for serial number in Intune and add it to your group.

### Active Directory binding    
If you want to go further and add the computer to the domain, the script **Mac_provisionning.sh** provides the same as above, but also offers to create the object in AD, bind the computer to it, and add two DeskSide_Admin groups to the machine:
  - XXXX_GG_F_Deskside_Admin (XXXX being selected after you say Yes to the prompt to add to domain)
  - [3700_GG_F_Deskside_Admin]([url](https://github.com/uoNate/DefenderPrep/blob/8359374a26bd926947546f5a53bc06938cb0fe04/Mac_provisioning.sh#L233)) in case of emergencies. This can be removed before you run the script by deleting _**,3700_GG_F_Deskside_Admin**_

The Computer object is left in your root, under Faculties/FACULTY_NAME/Computers. You'll need to move it to another subfolder manually if required.


This script only tackles Faculty AD OUs, a future version, if enough interest, would incorporate all the different AD Banner groups.
_Cavieat: the computer name is created in lowercase in AD, haven't found a way to set it all uppercase, despite the Mac Name and binding name all being uppercase._


# Troubleshooting and usage
launch the script by dragging it onto the Terminal window, or on the Terminal icon (located /Applications/Utilities)
or locate the script and run it ./Mac_Defender.sh

if you get "unauthorized" message, the script has been blacklisted by the system (normal for unsigned processes), paste the following code into terminal, drag the script in the window and press return
```
xattr -d com.apple.quarantine
```
If the script cannot be ran, mark it as executable by pasting this command into terminal, drag the script in the window and press return
```
chmod +x 
```
