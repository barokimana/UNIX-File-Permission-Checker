#!/bin/bash

#search_exec.sh
#arguments: <user> <group> <absolute path>
#checks execute  permission for each file in [absolute path] like
#a linux system does -
#First, check <user>,  then <group> and finally 'other'.
#Output -> /project/executable_files.txt
#Format of output:
#       <file 1 details>:UN
#       <file 2 details>:GY
#       <file 3 details>:OY
main_dir="$HOME/project"


###First, ensure input validity

#check number of arguments
if [[ $# -ne 3 ]]; then
        echo "invalid number of arguments"
        echo "correct format: ./search_exec <user> <group> <absolute path>"
        exit 1
fi

#if user exists, assign username of user to variable
if [[ $(id -u "$1") ]]; then
        username=$(id -un "$1")
else
        echo "invalid username or user id"
        echo "correct format: ./search_exec <user> <group> <absolute path>"
        exit 1
fi

#if group exists, assign groupname of group to variable
if [[ $(getent group "$2") ]]; then
        groupname=$(getent group "$2" | cut -d : -f 1)
else
        echo "invalid groupname or group id"
        echo "correct format: ./search_exec <user> <group> <absolute path>"
        exit 1
fi

#check if user is member of group
if ! $(id -nG "$username" | grep -qw "$groupname"); then
        echo "user not member of group"
        echo "correct format: ./search_exec <user> <group> <absolute path>"
        exit 1
fi

#if directory path is valid, assign it to a variable
if [[ -d "$3" ]]; then
        dirpath=$3
else
        echo "directory path invalid"
        echo "correct format: ./search_exec <user> <group> <absolute path>"
        exit 1
fi

###Second, check execute permission

#create on empty output file and assign it a variable
> "$main_dir/executable_files.txt"; output="$main_dir/executable_files.txt"

#show list of files and their permission, remove first line and
#then write output to $main_dir/list.tmp
$(ls -al $dirpath | sed -n '1!p' > "$main_dir/list.tmp")

#for each file in list, check execute permission
#output result to output file with file details followed by permission
while read line; do

        #permission of file
        permission=$(echo "$line" | tr -s ' ' | cut -d ' ' -f 1)
        #file owner user
        owner_user=$(echo "$line" | tr -s ' ' | cut -d ' ' -f 3 )
        #file owner group
        owner_group=$(echo "$line" | tr -s ' ' | cut -d ' ' -f 4 )
        #file name
        file_name=$(echo "$line" | tr -s ' ' | cut -d ' ' -f 9 )

        #append file path to beginning of line
        line="$dirpath/$file_name:$line"

        #check if user is owner of file and has execute permission
        if [[ "$username" == "$owner_user" ]]; then
                #check if user has execute permission
                #if so append UY, otherwise UN and exit
                if [[ ${permission:3:1} == "x" ]]; then
                        line+=":UY"
                else
                        line+=":UN"
                fi

 

                #write result to output file and continue to next file
                echo "$line" >>$output
                continue
        fi

        #check if group is owner of file and has execute permission
        if [[ "$groupname" == "$owner_group" ]]; then
                #check if group has execute permission
                #if so append GY, otherwise GN and exit
                if [[ ${permission:6:1} == "x" ]]; then
                        line+=":GY"
                else
                        line+=":GN"
                fi

                #write result to output file and continue to next file
                $line>>$output
                continue
        fi

        #check other has execute permission
        if [[ ${permission:9:1} == "x" ]]; then
                line+=":OY"
                echo "$line" >> $output
        else
                line+=":ON"
                echo "$line" >> $output
        fi

done < "$main_dir/list.tmp"

#perform clean-up
function finish {
        rm -f "$main_dir/list.tmp"
}
trap finish EXIT
