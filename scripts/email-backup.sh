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

# STATE CHANGE LOG:
# 0.0.1 (4/20/15) Initial commit.
# 0.0.3 (4/22/15) Added document verification function.
# 0.0.5 (4/23/15) Added dovecot to mbox format conversion.
# TODO: add option to delete emails from server

# DESCRIPTION:
# Developed for use by IS Technology Service Desk employees at the University of Oregon.
# Script parses a user's DuckID and creates a backup of all emails that are currently
# in their Inbox, Archive, Drafts, Sent, Junk, and Trash folders.

# Set variables
path="$HOME"
filename="TempWebmailBackup"
red="\x1B[1;31m"
green="\x1B[1;32m"
NC="\x1B[0m"


# Intro
echo "This backup utility will create a local copy of ALL your emails\n(and applicable attachments) from UO's server in .mbox format."
echo "\nBacking up your emails may be time intensive, depending on the # of emails you have."
echo "\nYou ${red}must${NC} have shell access enabled on your account to access the IMAP server:"
echo "See http://duckid.uoregon.edu >> Manage Your Duck ID >> Manage Optional Account Access\n"
read -n1 -r -s -p "Press any key to continue or q to quit." introKey
if [ "$introKey" = "q" ] || [ "$introKey" = "Q" ]; then
	echo "\n\n${red}Backup aborted.${NC} Server was not accessed.\n"; exit 0
fi

# Create local backup directory structure
mkdir -p $path/$filename/{Inbox,Archive,Drafts,Sent,Junk,Trash,temp}

# Get DuckID & verify
echo "\n"
while true; do
	read -p "Please enter your DuckID: " duckID

	# Manual loop exit (q to quit)
	if [ "$duckID" = "q" ] || [ "$duckID" = "Q" ]; then
		echo "\n${red}Backup aborted.${NC} Server was not accessed.\n"; exit 0
	fi

	# Verify no invalid characters
	if [[ $duckID =~ ^-?[0-9]+$ ]] || [[ $duckID == *"@"* ]]; then
		echo "\n${red}DuckID format is incorrect.${NC}\n"
		echo "Your DuckID is the just the first part of your UOregon email address:"
		echo "${green}puddles${NC}@uoregon.edu would have the DuckID of ${green}puddles${NC}\n"
		echo "(Enter q to quit)\n"
	else
		break
	fi	
done

# Parse UOregon Maildir (recursive & includes dot files)
rsync -chavzP --stats $duckID@shell.uoregon.edu:~/Maildir/ $path/$filename/temp/
echo ""

# Document verifier, pass in folder name
cd $path/$filename
documentCheck() {
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
	documentCheck $1 && mv ./$1/* ./$2 && echo "Organizing $2 folder..."
}
moveFiles temp/cur Inbox
moveFiles temp/.Archive/cur Archive
moveFiles temp/.Drafts/cur Drafts
moveFiles temp/.Sent/cur Sent
moveFiles temp/.Junk/cur Junk
moveFiles temp/.Trash/cur Trash

# Convert dovecot to .mbox
echo ""
mkdir ./WebmailBackup
convertEmail() {
	documentCheck $1
	if [[ $? -eq 0 ]]; then
		echo "Convering emails in $1 folder..."
		for file in ./$1/*; do
			cat $file | formail >> $1.mbox
		done
		mv $1.mbox ./WebmailBackup
	fi
}
convertEmail Inbox
convertEmail Archive
convertEmail Drafts
convertEmail Sent
convertEmail Junk
convertEmail Trash

# Clean up
echo "\nCleaning up files..."
mv ./WebmailBackup ~/Desktop/Webmail\ Backup\ $(date +"%m%d%Y")
rm -rf $path/$filename

echo "\n${green}Backup Complete.${NC} (Folder placed on Desktop)\n"
echo "For assistance with importing .mbox files into your email application, please\ncontact the Technology Service Desk at 541-346-4357 or techdesk@uoregon.edu\n"

exit 0;
