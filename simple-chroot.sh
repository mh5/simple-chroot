#!/bin/bash

# Copyright (c) 2015, M. Helmy Hemeda. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

function inc_refcount {
	local refs_file="$2.jail-data/refs"
	touch $refs_file

	local line=$(grep $1 $refs_file)

	if [ -z "$line" ]; then
		line="$1 1"
		echo $line >> $refs_file
		return
	fi  

	sed -i "\|$1|d" $refs_file

	local line_arr=($line)
	local dep=${line_arr[0]}
	local num=${line_arr[1]}

	local num=$((num+1))

	local line="$dep $num"

	echo $line >> $refs_file
}

function dec_refcount {
	local refs_file="$2.jail-data/refs"
	local line=$(grep $1 $refs_file)

	sed -i "\|$1|d" $refs_file

	local line_arr=($line)
	local dep=${line_arr[0]}
	local num=${line_arr[1]}

	local num=$((num-1))

	local line="$dep $num"

	echo $line >> $refs_file
}

function collect_deps {
	local path_to_file=$1
	local deps=$(ldd $path_to_file| grep -oh '/.* ')
	local deps="$path_to_file $deps"

	echo $deps
}

function is_installed {
	local installed_file="$2.jail-data/installed"

	if [[ ! -f  $installed_file ]]; then
		return 1
	fi

	local path_fo_file="$2$1"

	if grep -q  "$path_to_file" "$installed_file"; then
		return 0
	else
		return 1
	fi
}

function jail_install {
	local path_to_file=$1
	local cloned=$(collect_deps $path_to_file)

	for i in $cloned;
		do
			cp -v --parents $i $2
			inc_refcount $i $2
		done
}

function jail_purge {
	local path_to_file=$1
	local decrementedd=$(collect_deps $path_to_file)

	for i in $decremented;
		do
			dec_refcount $i $2
		done
}

function check_command {
	command_file="$(which $1)" || \
	    { printf "Fatal error: \`$1' command not found!\n" ;  exit 1; }
	check_file $command_file
}

function check_file {
	if [[ ! -f $1 ]]; then
		echo "Fatal error: \`$1' is not a file!"
		exit 1;
	fi
}

OPTIND=1
                              
output_dir="./jail/"
paths_to_files=()

while getopts "o:c:f:" opt; do
	case "$opt" in
		f)
			check_file $OPTARG
			paths_to_files+="$OPTARG "
		;;
		c)
			check_command $OPTARG
			paths_to_files+="$command_file "
		;;
		o)
			output_dir="$OPTARG"
		;;
	esac
done

mkdir -p $output_dir
mkdir -p "$output_dir/.jail-data"

for path_to_file in $paths_to_files; do
	jail_install $path_to_file $output_dir
done

