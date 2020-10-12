#! /bin/bash
if [[ $(printenv | grep "AUTO_INDEX=on" -c) != $(cat /etc/nginx/sites-available/localhost | grep -c "autoindex on") ]];
then
	sed -i "s/autoindex .*;/autoindex $AUTO_INDEX;/" /etc/nginx/sites-available/localhost && service nginx restart && echo "Auto index has been reconfigured"
else
	echo "Auto index is already set"
fi