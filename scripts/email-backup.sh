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

# DESCRIPTION:
# Resetting a user's password in OS X can be completed by booting into the
# recovery partition (10.7+) and submitting the command "resetpassword" via
# terminal. After doing so, the user's login keychain will be locked. This
# script will delete the locked login keychain, flush the keychain cache,
# and create a new default login keychain.

path="$HOME/Desktop"
filename="WebmailBackup"

# Create local backup directory structure
mkdir -p $path/$filename/{Inbox,Archive,Drafts,Sent,Junk,Trash,temp}

# SSH w/ DuckID
# TODO remove before release, script will be launched within ssh'd acct.
read -p "Please enter your DuckID: " duckID
#ssh $duckID@shell.uoregon.edu

# Parse UOregon Maildir (recursive & includes dot files)
rsync -chavzP --stats $duckID@shell.uoregon.edu:~/Maildir/ $path/$filename/temp



# Document verifier, pass in folder name
documentCheck() {
	if [ "$(ls -A ./$1)" ]; then
		return 1	# found documents in folder
	else
		return 0	# did not find documents in folder
	fi
}



# Organize backup into local folders:
# TODO check if files exist in directory before moving
cd $path/$filename/temp
moveFiles() {
	if documentCheck $1; then
		mv .$1/cur/* ./$1
		echo "Organizing $1 folder."
	fi
}

mv ./temp/.$1/cur/* ./$1

mv ./temp/cur/* ./Inbox # Inbox has different file structure
moveFiles Archive
moveFiles Drafts
moveFiles Sent
moveFiles Junk
moveFiles Trash

# TODO recursively remove all dovecot files

# Convert emails to .txt if they exist in directory
# TODO convert emails to .eml?
convertCheck() {
	if [ "$(ls -A ./$1)" ]; then
		echo "Converting $1 emails to .txt format."
		textutil -convert txt ./$1/*
	fi
}
convertCheck Inbox
convertCheck Archive
convertCheck Drafts
convertCheck Sent
convertCheck Junk
convertCheck Trash

# Clean up
cleanUpCheck() {
	if [ "$(ls -A ./$1)" ]; then
		echo "Cleaning up $1 folder."
		find ./$1 -type f -not -name '*txt' | xargs rm
	fi

}
cleanUpCheck Inbox
cleanUpCheck Archive
cleanUpCheck Drafts
cleanUpCheck Sent
cleanUpCheck Junk
cleanUpCheck Trash
rm -rf ./temp

echo -e "\nBackup Complete.\n"

exit
