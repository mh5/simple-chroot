# Copyright (c) 2015, M. Helmy Hemida. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

#!/bin/bash

function add_to_jail {
	path_to_file=$1
	deps=$(ldd $path_to_file| grep -oh '/.* ')

	cloned="$path_to_file $deps"

	for i in $cloned;
		do
			cp -v --parents $i $2
		done
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
			paths_to_files+="$(which $OPTARG) " \
			  || { printf "Fatal error: \`$OPTARG' command not found!\n" ;  exit 1; }
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

