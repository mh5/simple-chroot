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

OPTIND=1
                              
output_dir="./jail"
paths_to_files=()

while getopts "o:v:f:" opt; do
	case "$opt" in        
		f)
			paths_to_files+="$OPTARG "
		;;
		v)
			paths_to_files+="$(which $OPTARG) "
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

