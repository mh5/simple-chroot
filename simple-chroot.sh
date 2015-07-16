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

function add_to_jail {
	local path_to_file=$1
	local deps=$(ldd $path_to_file| grep -oh '/.* ')
	
	local cloned="$path_to_file $deps"

	for i in $cloned;
		do
			cp -v --parents $i $2
			inc_refcount $i $2
		done
}

function remove_from_jail {
	# not implemented yet
	return
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
	add_to_jail $path_to_file $output_dir
done

