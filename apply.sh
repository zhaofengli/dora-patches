#!/bin/bash

# Adapted from https://github.com/blumonks/android_device_blu_p6601

COMMAND=$(basename $0)
TREE=$(realpath ./../)
CUR=$(realpath ./)
PATCHES=$CUR/patches
PROJECTS=(
	device/sony/dora
	hardware/qcom/media
	vendor/qcom/opensource/location
	external/libnfnetlink
	external/libnetfilter_conntrack
)

BOLD=$(tput bold)
NORM=$(tput sgr0)
WARN=$(tput setaf 1)
SUCC=$(tput setaf 2)

reverse=0
failed=0
case $1 in
	"-h" | "--help")
		echo "Usage: $COMMAND [--reverse]"
		echo "Applies the commits necessary to build AOSP for dora"
		exit 0;
		;;
	*)
		echo "Applying patches..."
		;;
esac

for project in "${PROJECTS[@]}"
do
	echo "${BOLD}Entering $project${NORM}"
	pushd $TREE/$project > /dev/null

	patchdir=`echo $project | sed -e 's/\//_/g'`
	for patch in $PATCHES/$patchdir/*.patch
	do
		patchname=`basename "$patch"`
		echo -n "$patchname: "

		# Has this patch already been applied?
		patch -p1 -NR --dry-run < $patch > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
			echo "${SUCC}Already applied${NORM}"
			continue
		else
			# Can this patch be cleanly applied?
			patch -p1 -N --dry-run --silent < $patch
			if [ $? -eq 0 ]
			then
				git am $patch
				echo "${SUCC}Applied${NORM}"
			else
				echo "${WARN}Impossible to apply patch cleanly. Skipping...${NORM}"
				failed=1
			fi
		fi
	done

	echo "${BOLD}Leaving $project${NORM}"
	echo
	popd > /dev/null
done

if [ $failed = 1 ]
then
	echo "${WARN}One or more patches failed.${NORM}"
	exit 1
else
	echo "${SUCC}All good.${NORM}"
fi
