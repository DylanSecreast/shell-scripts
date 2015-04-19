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
# 0.0.1 (4/19/15) Initial commit

# DESCRIPTION:
# Resetting a user's password in OS X can be completed by booting into the recovery partition and submitting the command "resetpassword" via terminal. After doing so, the user's login keychain will be locked. This script will delete the locked login keychain, flush the keychain cache, and create a new default login keychain.


# Set variables
red='\x1B[1;31m'
green='\x1B[1;32m'
NC='\x1B[0m' # No color

echo ""

# Get & verify new password
while true; do
	read -s -p "Enter newly created password: " password
	echo ""

	# Manual loop exit (q to quit)
	if [ "$password" = "q" ] || [ "$password" = "Q" ]; then
		echo "${red}Script aborted${NC}" ; exit 0
	fi

	# Verify matching passwords
	read -s -p "Verify password: " verifyPassword
	if [ "$password" = "$verifyPassword" ]; then
		echo "\n"
		echo "${green}Verified password!${NC}"
		break
	else
		echo "\n${red}Passwords did not match (q to quit)${NC}" ; continue
	fi
done

# Navigate to /Users keychain folder
cd /Library/Keychains/

# Delete locked login keychain
security delete-keychain ./login.keychain
echo "\n[Deleted locked login keychain]"

# Create new login keychain
security create-keychain -p ${password} ./login.keychain 
echo "[Created new login keychain]"
security login-keychain -d user -s ./login.keychain
echo "[Set default login keychain]"

# Clear keychain cache
cacheFolder=$(find . -mindepth 1 -maxdepth 1 -type d)
rm -rf ${cacheFolder}
echo "[Keychain cache cleared]"

# Script complete
echo "\n${green}Script Completed!${NC}\n"
echo "After restarting your computer and logging in you will\nbe required to enter your new password and/or iCloud password due\nto clearing your keychain cache."
echo "\nPlease restart your computer (Cmd+Ctrl+Power Button)." 
