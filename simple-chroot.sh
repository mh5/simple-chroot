#!/bin/bash

# Copyright (c) 2015, M. Helmy Hemeda. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

function is_installed {
	local installed_file=".jail-data/installed"

	if [[ ! -f $installed_file ]]; then
		return 1
	fi

	local path_fo_file="$1"

	if grep -q "$path_to_file" "$installed_file"; then
		return 0
	else
		return 1
	fi
}

function set_installed {
	local path_to_file=$1
	local installed_file=".jail-data/installed"
	touch $installed_file

	if ! grep -q "$path_to_file" "$installed_file"; then
		echo "$path_to_file" >> $installed_file
		return 0
	else
		return 1
	fi
}

function unset_installed {
	local path_to_file=$1
	local installed_file=".jail-data/installed"

	if [[ ! -f $installed_file ]]; then
		return 1
	fi

	if is_installed $path_to_file; then
		sed -i "\|$path_to_file|d" $installed_file
		return 0
	else
		return 1
	fi
}

function inc_refcount {
	local refs_file=".jail-data/refs"
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
	local refs_file=".jail-data/refs"
	local line=$(grep $1 $refs_file)

	sed -i "\|$1|d" $refs_file

	local line_arr=($line)
	local dep=${line_arr[0]}
	local num=${line_arr[1]}

	local num=$((num-1))

	if ((num <= 0)); then
		rm .$dep
		return
	fi

	local line="$dep $num"

	echo $line >> $refs_file
}

function collect_deps {
	local path_to_file=$1
	local deps=$(ldd $path_to_file | grep -oh '/.* ')
	local deps="$path_to_file $deps"

	echo $deps
}

function jail_install {
	local path_to_file=$1
	local cloned=$(collect_deps $path_to_file)

	for i in $cloned;
		do
			cp -v --parents $i ./
			inc_refcount $i
		done

	set_installed $path_to_file
}

function jail_purge {
	local path_to_file=$1
	local decremented=$(collect_deps $path_to_file)

	for i in $decremented;
		do
			dec_refcount $i
		done

	unset_installed $path_to_file
}

function check_command {
	command_file="$(which $1)" || \
	    { printf "Fatal error: \`$1' command not found!\n" ; exit 1; }
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
cd $output_dir

mkdir -p ".jail-data"

for path_to_file in $paths_to_files; do
	if is_installed $path_to_file; then
		printf "\`$path_to_file' is already installed and will be ignored.\n"
	else
		jail_install $path_to_file
	fi
done

