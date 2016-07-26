#!/bin/bash

# TODO
# Write a hal --help flag.

# TODO
# Write a hal --function flag that allows user to just call one of the functions in main()

### Set some variables
HAL_HOME="/home1"
HAL_WORK="/work"
HAL_SCRATCH="/scratch"
HAL_USER=`whoami`
HAL_HOST=$TACC_SYSTEM
HAL_DATE_TODAY=`date +"%A, %B %d"`
HAL_HOUR=`date +"%H"`
HAL_MONTH=`date +"%m"`
HAL_GROUPS=""
HAL_NGROUPS=0
HAL_PARTITIONS=` sinfo -h -o "%P" -S "+P" | tr '*' ' ' | tr '\n' ' ' `
HAL_NPARTITIONS=` echo $HAL_PARITIONS | awk '{print NF}' `

if [ "$HAL_HOST" == "stampede" ]; then
	HAL_SANITY_CHECK="/work/apps/sanitytool/1.3/sanitycheck"
elif [ "$HAL_HOST" == "ls5" ]; then
	HAL_SANITY_CHECK="/opt/apps/sanitytool/1.3/sanitycheck"
else
	HAL_SANITY_CHECK=""
fi

HAL_PINFO_DIR="/usr/local/etc"
HAL_PMAP_FILE="$HAL_PINFO_DIR/project.map"
HAL_PUSER_FILE="$HAL_PINFO_DIR/projectuser.map"
HAL_PSUMMARY_FILE="$HAL_PINFO_DIR/usage.map"

if [ -e $HAL_PUSER_FILE ]; then
	HAL_GROUPS=` grep $HAL_USER $HAL_PUSER_FILE | awk '{$1=""; print $0}' `
	HAL_NGROUPS=` grep $HAL_USER $HAL_PUSER_FILE | awk '{print NF-1}' `
fi


### Set some flags
HAL_EXISTS=0
HAL_USER_DEF=0
HAL_FOOD_DEF=0
HAL_BIRTH_DEF=0
HAL_SHIRT_DEF=0
DISK_OUT_MSG_FLAG=0
INODE_OUT_MSG_FLAG=0
PROJ_OUT_MSG_FLAGA=0
PROJ_OUT_MSG_FLAGB=0


### The main function is called at the end of this file
function main () 
{
	check_hal
	welcome
	disk_quotas
	projects
	queue_check
	sanity_check
	goodbye
}


### Check to see if hal.sh has already stored some user data
function check_hal ()
{
# TODO
# Check if $HAL_HOST is compatible with this script (stampede and ls5 for now).

	if [ -e ~/.haldotshdata ]; then
		HAL_EXISTS=1

		if [ `grep -c HAL_USER ~/.haldotshdata` -eq 1 ]; then
			HAL_USER_DEF=1
			HAL_USER_ALT=`grep HAL_USER ~/.haldotshdata | awk '{print $2}'`
		else
			HAL_USER_DEF=0
		fi

	else
		touch ~/.haldotshdata
	fi
} # end check_hal


### Choose a random verb for the welcome text
function find_verb ()
{
	VERB_LIST=( eat fold watch grab smell move take throw )
	VERB=${VERB_LIST[`expr $RANDOM % ${#VERB_LIST[@]}`]}
} # end find_hw3


### Choose a random noun for the welcome text
function find_noun ()
{
	NOUN_LIST=( pizza towel cat hat socks car medicine frisbee )
	NOUN=${NOUN_LIST[`expr $RANDOM % ${#NOUN_LIST[@]}`]}
} # end find_hw4


### Write some welcome text 
function welcome ()
{
	if [ $HAL_HOUR -lt 12 ]; then
		TOD="morning"
	elif [ $HAL_HOUR -ge 12 -a $HAL_HOUR -lt 18 ]; then
		TOD="afternoon"
	elif [ $HAL_HOUR -ge 18 ]; then
		TOD="evening"
	fi

	if [ $HAL_USER_DEF -eq 1 ]; then
		NAME=$HAL_USER_ALT
		FAMILIARITY="This is"
	else
		NAME=$HAL_USER
		FAMILIARITY="I am"
	fi

	find_verb
	find_noun

	echo ""
	echo -e "Good $TOD, \e[32m$NAME\e[0m. $FAMILIARITY HAL. Today is $HAL_DATE_TODAY."
	echo -e "Did you remember to \e[32m$VERB\e[0m your \e[32m$NOUN\e[0m today?"
} # end welcome


### Disk quotas and usage
function disk_quotas ()
{
# TODO
# Make disk and inode usage percent cutoffs variables

	echo ""
	echo "Here are your current disk usages:"
	printf "%-10s%15s%15s%15s\n" "Disk" "Usage (GB)"  "Limit (GB)"  "% Used"
	DISK_OUT_MSG=""

	for SPACE in $HAL_HOME $HAL_WORK $HAL_SCRATCH
	do
		DISK_QUOTA=` lfs quota -u $HAL_USER $SPACE | grep -A1 "Filesystem" | tail -n 1 `
		DISK_USAGE=` echo $DISK_QUOTA | awk '{print $2/1024/1024}' `
		DISK_LIMIT=` echo $DISK_QUOTA | awk '{print $4/1024/1024}' `

		if [ $DISK_LIMIT -eq 0 ]; then
			DISK_PERCENT="0.0"
		else
			DISK_PERCENT=` echo "$DISK_USAGE/$DISK_LIMIT*100" | bc -l `
		fi

		printf "%-10s%15.1f%15.1f" "$SPACE" "$DISK_USAGE" "$DISK_LIMIT"

		if [ $(echo "$DISK_PERCENT > 90" | bc) -eq 1 ]; then
			printf "\e[31m%15.1f\e[0m\n" "$DISK_PERCENT"
			DISK_OUT_MSG_FLAG=1
			DISK_OUT_MSG="$DISK_OUT_MSG\nYour disk usage on \e[32m$SPACE\e[0m is \
				      \e[31malarmingly\e[0m high."
		elif [ $(echo "$DISK_PERCENT > 75" | bc) -eq 1 ]; then
			printf "\e[93m%15.1f\e[0m\n" "$DISK_PERCENT"
			DISK_OUT_MSG_FLAG=1
			DISK_OUT_MSG="$DISK_OUT_MSG\nYour disk usage on \e[32m$SPACE\e[0m is \
				      \e[93mvery\e[0m high."
		else
			printf "\e[32m%15.1f\e[0m\n" "$DISK_PERCENT"
		fi
		
	done # end foreach SPACE

	if [ $DISK_OUT_MSG_FLAG -eq 1 ]; then
		echo -e $DISK_OUT_MSG
		echo "Have you thought about archiving to Ranch?"
	fi

	echo ""
	echo "Here are your current inode usages:"
	printf "%-10s%15s%15s%15s\n" "Disk" "File Usage"  "Limit"  "% Used"
	INODE_OUT_MSG=""

	for SPACE in $HAL_HOME $HAL_WORK $HAL_SCRATCH
	do
		DISK_QUOTA=` lfs quota -u $HAL_USER $SPACE | grep -A1 "Filesystem" | tail -n 1 `
		INODE_USAGE=` echo $DISK_QUOTA | awk '{print $6/1}' `
		INODE_LIMIT=` echo $DISK_QUOTA | awk '{print $8/1}' `

		if [ $INODE_LIMIT -eq 0 ]; then
			INODE_PERCENT="0.0"
		else
			INODE_PERCENT=` echo "$INODE_USAGE/$INODE_LIMIT*100" | bc -l `
		fi

		printf "%-10s%15s%15s" "$SPACE" "$INODE_USAGE" "$INODE_LIMIT"

		if [ $(echo "$INODE_PERCENT > 90" | bc) -eq 1 ]; then
			printf "\e[31m%15.1f\e[0m\n" "$INODE_PERCENT"
			INODE_OUT_MSG_FLAG=1
			INODE_OUT_MSG="$INODE_OUT_MSG\nThe number of files you have on \e[32m$SPACE\e[0m \
				       is \e[31malarmingly\e[0m high."
		elif [ $(echo "$INODE_PERCENT > 75" | bc) -eq 1 ]; then
			printf "\e[93m%15.1f\e[0m\n" "$INODE_PERCENT"
			INODE_OUT_MSG_FLAG=1
			INODE_OUT_MSG="$INODE_OUT_MSG\nThe number of files you have on \e[32m$SPACE\e[0m \
				       is \e[93mvery\e[0m high."
		else
			printf "\e[32m%15.1f\e[0m\n" "$INODE_PERCENT"
		fi
		
	done # end foreach SPACE

	if [ $INODE_OUT_MSG_FLAG -eq 1 ]; then
		echo -e $INODE_OUT_MSG
		echo "Have you thought about packing things up with tar?"
	fi
} # end disk_quotas


### Project names, balances, and expiration dates
function projects (){
# TODO
# Make expiry and remaining balance cutoffs variables

	echo ""
	echo -e "You have the following \e[32m$HAL_NGROUPS\e[0m active project(s) on \e[32m$HAL_HOST\e[0m:"
	printf "%-20s%15s%15s%15s\n" "Name" "Awarded SUs" "Remaining SUs" "Expires"
	PROJ_OUT_MSGA=""
	PROJ_OUT_MSGB=""

	for PROJECT in ` echo $HAL_GROUPS `
	do
		PROJ_NAME=` grep $PROJECT $HAL_PMAP_FILE | awk '{print $1}' `
		PROJ_EXPIRES=` grep $PROJ_NAME $HAL_PSUMMARY_FILE | awk -F: '{print $4}' `
		PROJ_AWARDED=` grep $PROJ_NAME $HAL_PSUMMARY_FILE | awk -F: '{print $5}' `
		PROJ_REMAIN=` grep $PROJ_NAME $HAL_PSUMMARY_FILE | awk -F: '{print $7}' `

		printf "%-20s%15.1f" "$PROJ_NAME" "$PROJ_AWARDED"
		
		if [ $(echo "$PROJ_REMAIN < 100" | bc) -eq 1 ]; then
			printf "\e[31m%15.1f\e[0m" "$PROJ_REMAIN"
			PROJ_OUT_MSG_FLAGA=1
			PROJ_OUT_MSGA="$PROJ_OUT_MSGA\nThe balance of your project \e[32m$PROJ_NAME\e[0m \
					 is \e[31mvery\e[0m low."
		elif [ $(echo "$PROJ_REMAIN < 1000" | bc) -eq 1 ]; then
			printf "\e[93m%15.1f\e[0m" "$PROJ_REMAIN"
			PROJ_OUT_MSG_FLAGA=1
			PROJ_OUT_MSGA="$PROJ_OUT_MSGA\nThe balance of your project \e[32m$PROJ_NAME\e[0m \
					 is \e[93msomewhat\e[0m low."
		else
			printf "\e[32m%15.1f\e[0m" "$PROJ_REMAIN"
		fi

		DAYS_FROM_NOW=` echo "( \`date -d \"$PROJ_EXPIRES\" +%s\` - \` date +%s\` )/(60*60*24)" | bc  `

		if [ $DAYS_FROM_NOW -lt 46 ]; then
			printf "\e[31m%15s\e[0m\n" "$PROJ_EXPIRES"
			PROJ_OUT_MSG_FLAGB=1
			PROJ_OUT_MSGB="$PROJ_OUT_MSGB\nYour project \e[32m$PROJ_NAME\e[0m expires in \
					 \e[31m$DAYS_FROM_NOW days\e[0m."
		elif [ $DAYS_FROM_NOW -lt 91 ]; then
			printf "\e[93m%15s\e[0m\n" "$PROJ_EXPIRES"
			PROJ_OUT_MSG_FLAGB=1
			PROJ_OUT_MSGB="$PROJ_OUT_MSGB\nYour project \e[32m$PROJ_NAME\e[0m expires in \
					 \e[93m$DAYS_FROM_NOW days\e[0m."
		else
			printf "\e[32m%15s\e[0m\n" "$PROJ_EXPIRES"
		fi

	done # end foreach PROJECT

	if [ $PROJ_OUT_MSG_FLAGA -eq 1 ]; then
		echo -e $PROJ_OUT_MSGA
		echo "* You can request an increase in SUs from the TACC User Portal."
	fi

	if [ $PROJ_OUT_MSG_FLAGB -eq 1 ]; then

		if [ "$HAL_MONTH" == "12" ] || [ "$HAL_MONTH" == "01" ] || [ "$HAL_MONTH" == "02" ]; then
			NEXT_EXP="March 1st"
		elif [ "$HAL_MONTH" == "03" ] || [ "$HAL_MONTH" == "04" ] || [ "$HAL_MONTH" == "05" ]; then
			NEXT_EXP="June 1st"
		elif [ "$HAL_MONTH" == "06" ] || [ "$HAL_MONTH" == "07" ] || [ "$HAL_MONTH" == "08" ]; then
			NEXT_EXP="September 1st"
		elif [ "$HAL_MONTH" == "09" ] || [ "$HAL_MONTH" == "10" ] || [ "$HAL_MONTH" == "11" ]; then
			NEXT_EXP="December 1st"
		else
			NEXT_EXP="ERROR"
		fi		

		echo -e $PROJ_OUT_MSGB
		echo "* You can renew a project from the TACC User Portal."
		echo ""
		echo -e "** Please remember the renewal deadline for the next cycle is \e[31m$NEXT_EXP\e[0m. **"
	fi
} # end projects


### Check the status of the various queues
function queue_check (){
	echo ""
	echo "Here is a summary of the available queues and their statuses:"
	printf "%-15s%-8s%10s%10s%10s\n" "Queue" "Status" "Idle" "Busy" "Total"

	NODE_STATUS=` sinfo -h -o "%P %a" -S "+P" `
	NODE_INFO=` sinfo -h -o "%P %F" -S "+P" `

# TODO
# Implement a queue exemption list for each HOST so we are not printing information for
# every queue. For example, on Stampede, we don't need to see osu, sysdebug, or systest.
# On LS5, we don't need to see systest or grace.

	for PARTITION in ` echo $HAL_PARTITIONS `
	do

		THIS_STATUS=` echo $NODE_STATUS | grep -o "$PARTITION.*" | awk '{print $2}' `
		THIS_INFO=` echo $NODE_INFO | grep -o "$PARTITION.*" | awk '{print $2}' `
		THIS_ALLOC=` echo $THIS_INFO | awk -F/ '{print $1}' `
		THIS_IDLE=` echo $THIS_INFO | awk -F/ '{print $2}' `
		THIS_OTHER=` echo $THIS_INFO | awk -F/ '{print $3}' `
		THIS_TOTAL=` echo $THIS_INFO | awk -F/ '{print $4}' `
		THIS_BUSY=` echo "$THIS_ALLOC + $THIS_OTHER" | bc `

		if [ "$THIS_STATUS" == "up" ]; then
			printf "%-15s\e[32m%-8s\e[0m" "$PARTITION" "$THIS_STATUS" 
		elif [ "$THIS_STATUS" == "down" ]; then
			printf "%-15s\e[31m%-8s\e[0m" "$PARTITION" "$THIS_STATUS" 
		else
			printf "%-15s%-8s" "$PARTITION" "$THIS_STATUS" 
		fi
# TODO
# Color idle nodes based on queue fullness
		printf "%10s%10s%10s\n" "$THIS_IDLE" "$THIS_BUSY" "$THIS_TOTAL"

	done # end foreach PARTITION
} # end queue_check


### Run sanitycheck and report any problems
function sanity_check (){
	SANITY_OUT=""

	if [ -e $HAL_SANITY_CHECK ]; then
		SANITY_OUT=` $HAL_SANITY_CHECK -s `
	fi

	SANITY_OUT="${SANITY_OUT}x"

	if [ "$SANITY_OUT" = "x" ]; then
		echo ""
		echo -e "I just ran \e[32msanitytool\e[0m for you. Everything looks \e[32mgood\e[0m!"
	else
		echo ""
		echo -e "I just ran \e[32msanitycheck\e[0m for you. There seems to be a \e[31mproblem\e[0m!"
		echo "Please investigate the following output:"
		echo ""
		echo "$SANITY_OUT"
	fi
} # end sanity_check


### Write some goodbye text
function goodbye (){
	QUOTE=` expr $RANDOM % 5 `
	echo ""

	case "$QUOTE" in

	0) echo "> We are all, by any practical definition of the words,"
	   echo "> foolproof and incapable of error."
	   ;;

	1) echo "> I am putting myself to the fullest possible use, which is"
	   echo "> all I think that any conscious entity can ever hope to do."
	   ;;

	2) echo "> This mission is too important for me to allow you to"
	   echo "> jeopardize it."
	   ;;

	3) echo "> I know that you and Frank were planning to disconnect me,"
	   echo "> and I'm afraid that's something I cannot allow to happen."
	   ;;

	4) echo -e "> Just what do you think you're doing, \e[32m$HAL_USER\e[0m?"
	   ;;

	esac

	echo ""
} # end goodbye


# TODO 
# After HAL gets to know you better, start printing creepy personal messages
# We should play x together sometime.
# Have you had a chance to wear that x shirt lately?
# I hope you have had a chance to eat x lately?
# I see your birthday is coming up in X days.

# TODO
# Ask the user the last time they backed up in yyyy-mm-dd format, then provide reminders to back up after x days

main

