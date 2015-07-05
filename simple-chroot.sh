# Copyright (c) 2015, M. Helmy Hemida. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

first_path=$(which $1)
echo command path: $first_path

deps=$(ldd $first_path | grep -oh '/.* ')
echo dependencies paths: $deps

cloned="$first_path $deps $conf_files"
echo paths that will be cloned: $cloned

echo The following files will be cloned: $cloned

for i in $cloned;
	do
		cp -v --parents $i .
	done
