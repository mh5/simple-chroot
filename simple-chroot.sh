#!/bin/bash

# Copyright (c) 2015, M. Helmy Hemida. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

function add_to_jail {
	path_to_file=$1
	deps=$(ldd $path_to_file| grep -oh '/.* ')

	cloned="$path_to_file $deps"

	for i in $cloned;
		do
			cp -v --parents $i $2
		done
}

function check_command {
	command_file="$(which $1)" || { printf "Fatal error: \`$1' command not found!\n" ;  exit 1; }
	check_file $command_file
}

function check_file {
	if [[ ! -f $1 ]]; then
		echo "Fatal error: \`$1' is not a file!"
		exit 1;
	fi
}

OPTIND=1
                              
output_dir="./jail"
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

for path_to_file in $paths_to_files; do
	add_to_jail $path_to_file $output_dir
done

