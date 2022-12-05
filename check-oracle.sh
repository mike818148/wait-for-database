#!/bin/bash

exit | sqlplus -l $1/$2@$3:1521/$4 as sysdba | grep Connected > /dev/null
if [[ $? == "0" ]]
then
	echo "Success"
	exit 0
fi

exit 1
