# Copyright (c) 2015, M. Helmy Hemida. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

#!/bin/bash

function add_to_jail {
	first_path=$1
	deps=$(ldd $first_path | grep -oh '/.* ')

	cloned="$first_path $deps"

	for i in $cloned;
		do
			cp -v --parents $i $2
		done
}

OPTIND=1                      
                              
output_dir="./jail"
while getopts "o:v:f:" opt; do
	case "$opt" in        
		f)
			add_to_jail $OPTARG "$output_dir"
		;;
		v)
			add_to_jail $(which "$OPTARG") "$output_dir"
		;;
		o)
			output_dir="$OPTARG"
			mkdir $output_dir
		;;
	esac
done

