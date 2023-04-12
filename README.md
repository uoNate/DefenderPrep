# DefenderPrep

Mac_Defender.sh is a script made to simplify the process of getting a Mac ready to enroll in Defender
This script changes the computer name to either XXXX-SERIALNUM or whatever of your preference.
  Choice offered : Basic/Custom, if you select Basic, you'll be prompted to enter 4 digits for your unit banner code, entering 2101 changes the Mac Name to 2101-ABC123CDE456 and limits it to 15 characters
Automaticly does the following:
- Changes the time server to time.uottawa.ca
- Checks for Sophos and automatically and silently removes it
- Deactivates FileVault (disk encryption) so Intune can, once enrolled, re-activate it and store the key properly
  /!\ Requires entering the admin password one more time
  
Check whether the uOttawa MDM profile is installed, if not, installs Company Portal (manual operation follows).
  - checks for the presence of the configuration profile file, and inside for one that has the word ottawa in it. if either fails, installs Company portal.
    -> it uses an external script made by Microsoft, located here: https://github.com/microsoft/shell-intune-samples/blob/master/macOS/Apps/Company%20Portal/installCompanyPortal.sh
    the script checks and install multiple things: Microsoft auto-update, Company portal, Rosetta 2 if not already installed.
    
If you want to go further and add the computer to the domain, the script Mac_provisionning.sh provides the same as above, but also offers to create the object in AD, bind the computer to it, and add two DeskSide_Admin groups to the machine: yours -> XXXX_GG_F_Deskside_Admin(XXXX being selected after you say Yes to the prompt to add to domain), and the 3700_GG_F_Deskside_Admin in case of emergencies. This can be removed before you run the script, line XX

This script only tackles Faculty AD OUs, a future version, if enough interest, would incorporate all the different AD Banner groups 
The Computer object would be left in the root, under Faculties/FACULTY_NAME/Computers you'll need to move it to another subfolder manually if required.
Cavieat: the computer name is created in lowercase, haven't found a way to set it all uppercase, despite the Mac Name and binding name all being uppercase.
