#!/bin/bash

##JSS Credentials Here
username=""
password=""
jssURL=""

#Writes log to desktop - log is also read in terminal after completion
runtime=`date '+%Y%m%d_%H%M%S'`
log=$HOME/Desktop/group_updater$runtime.txt

#Establishes home for XML file to upload
groupXML=/private/tmp/groupXML

##Gets JSS IDs for all all Mac App Store Apps.
appIDs=$(curl -H "Accept: application/xml" -skvu $username:$password -X GET $jssURL/JSSResource/macapplications | xmllint --format - | grep "<id>" | awk -F '<id>|</id>' '{print $2}')

##Loops through all Mac App Store Apps found from the JSS.
for ID in $appIDs
do
	shortname=$(curl -H "Accept: application/xml" -skvu $username:$password -X GET $jssURL/JSSResource/macapplications/id/$ID | xmllint --format - | grep "<name>" -m 1 | awk -F '<name>|</name>' '{print $2}'| cut -d " " -f 1)
	
	version=$(curl -H "Accept: application/xml" -skvu $username:$password -X GET $jssURL/JSSResource/macapplications/id/$ID | xmllint --format - | grep "<version>" | awk -F '<version>|</version>' '{print $2}')
	##Searches for a smartgroup using the nomenclature "On Current $shortname Version"
	groupID=$(curl -H "Accept: application/xml" -skvu $username:$password -X GET $jssURL/JSSResource/computergroups | xpath "computer_groups/computer_group[name='On Current $shortname Version']/id" | awk -F '<id>|</id>' '{print $2}')
	
	##Checks to confirm the existence of a smart group and moves on to next MAS App if there isn't one
	if [[ $groupID ]]; then
		currentVersion=$(curl -H "Accept: application/xml" -skvu $username:$password -X GET $jssURL/JSSResource/computergroups/id/$groupID | xpath "/computer_group/criteria/criterion[name='Application Version']/value" | awk -F '<value>|</value>' '{print $2}')
		##Checks if the MAS app version matches the current group criteria and moves on to the next MAS App if so
		if [ "$version" == "$currentVersion" ]; then
			echo "No group update needed for $shortname" >> $log
		else
			curl -H "Accept: application/xml" -skvu "$username:$password" -X GET "$jssURL/JSSResource/computergroups/id/$groupID" | sed "s/$currentVersion/$version/" > $groupXML
			curl -skvu "$username:$password" -X PUT -H "Content-Type: application/xml" -d "@$groupXML" "$jssURL/JSSResource/computergroups/id/$groupID" 
			rm -rf /private/tmp/groupXML
			echo "The group On Current $shortname Version has been updated." >> $log
		fi
	else
		echo "No group exists for $shortname" >> $log
	fi
done 

cat $log

exit 0

	
		
		
		
		
		
		
		
