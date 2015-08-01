#!/bin/bash

# Copyright (c) 2015, M. Helmy Hemeda. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

function usage {
	echo "Usage: ./simple-chroot.sh    install {file_path | external_command}... |"
	echo "                             purge {file_path | external_command}..."
}

function is_installed {
	if [[ ! -f $FILE_INSTALLED ]]; then
		return 1
	fi

	local path_fo_file="$1"

	grep -q "$path_to_file" $FILE_INSTALLED
	return $?
}

function set_installed {
	local path_to_file="$1"
	touch $FILE_INSTALLED

	if ! grep -q "$path_to_file" $FILE_INSTALLED; then
		echo "$path_to_file" >> $FILE_INSTALLED
		echo "Set installation of \`$path_to_file'"
		return 0
	fi

	return 1
}

function unset_installed {
	local path_to_file="$1"

	if [[ ! -f $FILE_INSTALLED ]]; then
		return 1
	fi

	if is_installed "$path_to_file" ; then
		sed -i "\|$path_to_file|d" $FILE_INSTALLED
		echo "Unset installation of \`$path_to_file'"
		return 0
	fi

	return 1
}

function inc_refcount {
	touch $FILE_REFS

	local line="$(grep $1 $FILE_REFS)"

	if [ -z "$line" ]; then
		line="$1 1"
		echo "$line" >> $FILE_REFS
		return
	fi

	sed -i "\|$1|d" $FILE_REFS

	local line_arr=($line)
	local dep=${line_arr[0]}
	local num=${line_arr[1]}

	local num=$((num+1))

	local line="$dep $num"

	echo "$line" >> $FILE_REFS
}

function dec_refcount {
	local line="$(grep $1 $FILE_REFS)"

	sed -i "\|$1|d" $FILE_REFS

	local line_arr=($line)
	local dep=${line_arr[0]}
	local num=${line_arr[1]}

	local num=$((num-1))

	if ((num <= 0)); then
		rm -v ".$dep"
		return
	fi

	local line="$dep $num"
	echo "$line" >> $FILE_REFS
}

function collect_deps {
	local path_to_file="$1"
	local deps="$(ldd $path_to_file | grep -oh '/.* ')"
	local deps="$path_to_file $deps"

	echo "$deps"
}

function jail_install {
	local path_to_file="$1"

	if is_installed "$path_to_file" ; then
		echo "Note: \`$path_to_file' will be ignored because it is already installed!"
		return 1
	fi

	local cloned="$(collect_deps $path_to_file)"

	for i in $cloned; do
		cp -v --parents "$i" ./
		inc_refcount "$i"
	done

	set_installed "$path_to_file"
	return $?
}

function jail_purge {
	local path_to_file="$1"

	if ! is_installed "$path_to_file" ; then
		echo "Note: \`$path_to_file' is not installed to be purged!"
		return 1
	fi

	local decremented="$(collect_deps $path_to_file)"

	for i in $decremented;
		do
			dec_refcount "$i"
		done

	unset_installed "$path_to_file"
	return $?
}

function check_command {
	command_type="$(type -t $1)"

	if [[ "$command_type" == "builtin" ]] ; then
		echo "Fatal error: \`$1' is a builtin!";
		echo "Note: try installing a shell instead, e.g. bash!"
		exit 1;
	fi

	if [[ "$command_type" != "file" ]] ; then
		echo "Fatal error: \`$1' command not found!";
		exit 1;
	fi

	command_file="$(type -P $1)"

	check_file "$command_file"
}

function check_file {
	if [[ ! -f "$1" ]]; then
		echo "Fatal error: \`$1' is not a file!"
		exit 1;
	fi
}

if (( "$#" < 2 )); then
	echo Fatal error: too few arguments!
	usage
	exit 1
fi

paths_to_files=()
action=""

FILE_REFS=".jail-data/refs"
FILE_INSTALLED=".jail-data/installed"

for arg; do
	if [[ $action == "" ]]; then
		if [[ "$arg" == "install" ]] || [[ "$arg" == "purge" ]] ; then
			action="jail_$arg"
		else
			echo "Fatal error: unknown action \`$arg'!"
			usage
			exit 1
		fi
	else
		if [[ "$arg" == /* ]] ; then
			check_file "$arg"
			paths_to_files+=("$arg")
		elif [[ "$arg" == .* ]] ; then
			check_file "$arg"
			paths_to_files+=("$(realpath $arg)")
		else
			check_command "$arg"
			paths_to_files+=("$command_file")
		fi
	fi
done

output_dir="./"
mkdir -p $output_dir
cd $output_dir
mkdir -p ".jail-data"

for path in "${paths_to_files[@]}"; do
	$action "$path"
done

