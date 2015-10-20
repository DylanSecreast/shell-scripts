#!/bin/sh

# Copyright 2015 Dylan Secreast [.com]

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# DESCRIPTION:
# Developed for use by IS Technology Service Desk employees at the University of Oregon.
# Script parses UO's IMAP servers & creates a local backup of all emails that are currently
# in their Inbox, Archive, Drafts, Sent, Junk, and Trash folders in .mbox format. In addition,
# offers the option to delete all emails in a user designated folder.

# STATE CHANGE LOG:
# 0.1 (4/20/15) Initial commit. -DS
# 0.2 (4/22/15) Added document verification function. -DS
# 0.4 (4/23/15) Added dovecot to mbox format conversion and SSH detection. -DS
# 0.5 (8/26/15) Added purge folder verification. -DS
# 0.6 (9/3/15)  Added option to purge multiple folders. -DS
# 1.0 (9/16/15) Deployed script to role account "bbogus" for use by IS-TSD Staff. -DS

# Set variables
path="$HOME"
filename="WebmailBackup"
red="\x1B[1;31m"
green="\x1B[1;32m"
NC="\x1B[0m"
#folderCounter="0"
folderToDelete=""

purgeInbox=""
purgeArchive=""
purgeDrafts=""
purgeSent=""
purgeJunk=""
purgeTrash=""


# Detect SSH connection
detectSSH() {
	if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
		echo "<< Current SSH connection detected >>\n"
		return 0	# Detected current SSH connection
	else
		echo "\n\n<< No current SSH connection detected >>\n"
		return 1	# No current SSH connection detected
	fi
}

# Get DuckID & verify
echo ""
getDuckID() {
	while true; do
		echo ""
		read -p "Please enter your DuckID: " duckID

		# Manual loop exit (q to quit)
		if [ "$duckID" = "q" ] || [ "$duckID" = "Q" ]; then
			echo "\n<< ${red}Backup aborted${NC} - Server was not accessed >>\n"
			selfDestruct
		fi

		# Verify no invalid characters
		if [[ $duckID =~ ^-?[0-9]+$ ]] || [[ $duckID == *"@"* ]]; then
			echo "\n<< ${red}DuckID format is incorrect${NC} >>\n"
			echo "Your DuckID is the just the first part of your UOregon email address:"
			echo "${green}puddles${NC}@uoregon.edu would have the DuckID of ${green}puddles${NC}\n"
			echo "(Enter q to quit)\n"
		else
			break
		fi
	done
}

# Document verifier, pass in folder name
documentCheck() {
	cd $path/$filename
	if [ "$(ls -A ./$1)" ]; then
		return 0	# found documents in folder
	else
		return 1	# did not find documents in folder
	fi
}

# Organize backup into local folders:
moveFiles() {
	# $1 = folder to check
	# $2 = move destination
	documentCheck $1
	if [[ $? -eq 0 ]]; then
		echo "<< Organizing $2 folder >>"
		mv $path/$filename/$1/* $path/$filename/$2
	else
		echo "<< No emails found in $2 folder >>"
	fi
}

# Convert dovecot to .mbox
echo ""
convertEmail() {
	cd $path/$filename
	documentCheck $1
	if [[ $? -eq 0 ]]; then
		echo "<< Converting emails in $1 folder - Please wait... >>"
		for file in $path/$filename/$1/*; do
			cat $file | formail >> $1.mbox
		done
	fi
}

# Parse server, copy Maildir to local machine
backupMaildir() {
	# Create local file structure
	mkdir -p $path/$filename/{Inbox,Drafts,Sent,Junk,Trash,temp}
	# Get & verify DuckID
	getDuckID
	# Non-SSH server parse
	echo "\n<< Enter DuckID password to begin backup >>"
	rsync -chavzP --stats $duckID@shell.uoregon.edu:~/Maildir/ $path/$filename/temp/

	processBackup
}

processBackup() {
	# Organize local backup
	moveFiles temp/cur Inbox
	moveFiles temp/.Drafts/cur Drafts
	moveFiles temp/.Sent/cur Sent
	moveFiles temp/.Junk/cur Junk
	moveFiles temp/.Trash/cur Trash
	# Convert local dovecot to mbox`
	convertEmail Inbox
	convertEmail Drafts
	convertEmail Sent
	convertEmail Junk
	convertEmail Trash
	# Clean up
	echo "<< Cleaning up files >>"
	rm -rf $path/$filename/{Inbox,Drafts,Sent,Junk,Trash,temp}
	echo "<< Moving backup folder to local Desktop >>"
	mv $path/$filename ~/Desktop/Webmail\ Backup\ $(date +"%m-%d-%Y")
}

# Deletes user selected email folder(s)
deleteFolder() {
	while true; do
		cd ~/Desktop/Webmail\ Backup\ $(date +"%m-%d-%Y")/
		folderCounter="0"

		echo "\nWould you like to delete any emails?"
		read -n1 -r -s -p "(y) to continue, (n) to exit: " continueDelete
		if [ "$continueDelete" != "y" ]; then
			echo "\n\n<< Folder delete option ended >>"
			echo "For directions on how to upload your backup files into an email client,"
			echo "please contact the Technology Service Desk at (541) 346-HELP (4357).\n"
			selfDestruct
		fi

		echo "\n\nYou currently have emails in the following folders:"
		if [ -f "./Inbox.mbox" ]; then
			folderCounter=$[$folderCounter +1]
			purgeInbox=$folderCounter
			echo "("$folderCounter") Inbox"
		fi

		if [ -f "./Drafts.mbox" ]; then
			folderCounter=$[$folderCounter +1]
			purgeDrafts=$folderCounter
			echo "("$folderCounter") Drafts"
		fi

		if [ -f "./Sent.mbox" ]; then
			folderCounter=$[$folderCounter +1]
			purgeSent=$folderCounter
			echo "("$folderCounter") Sent"
		fi

		if [ -f "./Junk.mbox" ]; then
			folderCounter=$[$folderCounter +1]
			purgeJunk=$folderCounter
			echo "("$folderCounter") Junk"
		fi

		if [ -f "./Trash.mbox" ]; then
			folderCounter=$[$folderCounter +1]
			purgeTrash=$folderCounter
			echo "("$folderCounter") Trash"
		fi

		read -n1 -r -s -p "Enter the applicable # of the folder you wish to purge: " selectedToPurge;
		if [ "$selectedToPurge" = "q" ] || [ "$selectedToPurge" = "Q" ]; then
			echo "\n\n<< ${red}Purge aborted${NC} - No emails were deleted >>\n"
			selfDestruct
		elif [ "$selectedToPurge" == "$purgeInbox" ]; then
			folderToDelete="Inbox"
		elif [ "$selectedToPurge" == "$purgeArchive" ]; then
			folderToDelete="Archive"
		elif [ "$selectedToPurge" == "$purgeDrafts" ]; then
			folderToDelete="Drafts"
		elif [ "$selectedToPurge" == "$purgeSent" ]; then
			folderToDelete="Sent"
		elif [ "$selectedToPurge" == "$purgeJunk" ]; then
			folderToDelete="Junk"
		elif [ "$selectedToPurge" == "$purgeTrash" ]; then
			folderToDelete="Trash"
		else
			echo "\n\n${red}<< Not a valid folder selection (1-$folderCounter) >>${NC}\n"
			deleteFolder
		fi

	    echo "\n\nAre you sure you want to delete ${red}ALL${NC} emails in $folderToDelete folder"?
	    read -p "Enter folder name ("$folderToDelete") to confirm purge: " confirmDelete

	    # verify & delete
	    if [ "$confirmDelete" == "$folderToDelete" ]; then
			echo "\n<< Please enter DuckID password to delete $folderToDelete folder >>"
	      	ssh $duckID@shell.uoregon.edu "rm ~/Maildir/.$folderToDelete/cur/*"
	      	echo "\n\n${green}<< Successfully deleted $folderToDelete folder >>${NC}\n"
	    else
	      	echo "\n<< ${red}Invalid verification${NC} - (q to quit) >>"
	  	fi

	done
}

# Self-delete script & exit
selfDestruct() {
	echo "\n${green}<< Script Complete >>${NC}\n";
	# Self-delete
	cd ~/Desktop
	rm $0
	exit 0
}


########################
#####     MAIN     #####
########################

clear
echo "This backup utility will create a local copy of ALL your emails\n(and applicable attachments) from UO's server in .mbox format."
echo "\nBacking up your emails may be time intensive, depending on the # of emails you have."
echo "\nYou ${red}must${NC} have shell access enabled on your account to access the IMAP server:"
echo "See http://duckid.uoregon.edu > Manage Your Duck ID > Manage Optional Account Access\n"
read -n1 -r -s -p "<< Press any key to continue (q to quit) >>" introKey
if [ "$introKey" = "q" ] || [ "$introKey" = "Q" ]; then
	echo "\n\n<< ${red}Backup aborted${NC} - Server was not accessed >>\n"
	selfDestruct
else
	backupMaildir
	deleteFolder
fi

selfDestruct
