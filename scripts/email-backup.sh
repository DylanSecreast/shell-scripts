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
# 0.0.1 (4/20/15) Initial commit
# TODO: add option to delete emails from server

# DESCRIPTION:
# Developed for use by IS Technology Service Desk employees at the University of Oregon.
# Script parses a user's DuckID and creates a backup of all emails that are currently
# in their Inbox, Archive, Drafts, Sent, Junk, and Trash folders.

path="$HOME"
filename="TempWebmailBackup"

# Create local backup directory structure
mkdir -p $path/$filename/{Inbox,Archive,Drafts,Sent,Junk,Trash,temp}

# Get DuckID
read -p "Please enter your DuckID: " duckID

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
	documentCheck $1 && mv ./$1/* ./$2 && echo "Organizing $2 folder."
}
moveFiles temp/cur Inbox
moveFiles temp/.Archive/cur Archive
moveFiles temp/.Drafts/cur Drafts
moveFiles temp/.Sent/cur Sent
moveFiles temp/.Junk/cur Junk
moveFiles temp/.Trash/cur Trash

# Convert emails to .txt if they exist in directory
# TODO convert emails to .eml?
convertEmail() {
	documentCheck $1 && textutil -convert txt ./$1/* && echo "Converting emails in $1 folder."
}
convertEmail Inbox
convertEmail Archive
convertEmail Drafts
convertEmail Sent
convertEmail Junk
convertEmail Trash

# Clean up
cleanUp() {
	find ./$1 -type f -not -name '*txt' | xargs rm && echo "Cleaning up $1 folder."
}
cleanUp Inbox
cleanUp Archive
cleanUp Drafts
cleanUp Sent
cleanUp Junk
cleanUp Trash

# Zip backup, place on desktop, delete temp folder
zip -r WebmailBackup.zip $path/$filename/
mv ./WebmailBackup.zip ~/Desktop
rm -rf $path/$filename


echo "\nBackup Complete.\n"

exit
