# Copyright (c) 2015, M. Helmy Hemida. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

#!/bin/bash

function add_to_jail {
	first_path=$(which $1)
	deps=$(ldd $first_path | grep -oh '/.* ')

	cloned="$first_path $deps"

	for i in $cloned;
		do
			cp -v --parents $i .
		done
}

add_to_jail $1

