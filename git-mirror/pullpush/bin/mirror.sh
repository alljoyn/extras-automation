#!/bin/bash

# # 
#    Copyright (c) 2016 Open Connectivity Foundation and AllJoyn Open
#    Source Project Contributors and others.
#    
#    All rights reserved. This program and the accompanying materials are
#    made available under the terms of the Apache License, Version 2.0
#    which accompanies this distribution, and is available at
#    http://www.apache.org/licenses/LICENSE-2.0


set +x +e
date +%j%H > logs/mirror.now
if test "$(< logs/mirror.start)" != "$(< logs/mirror.now)"
then
	set -x +e
	date
	mv logs/mirror.now logs/mirror.start
	echo logs/mirror.log
	t=$( wc -l < logs/mirror.log )
	if test "$t" -gt 200
	then
    		head -100 logs/mirror.log
    		echo "... snip ..."
    		tail -100 logs/mirror.log
	else
    		cat logs/mirror.log
	fi

	find logs/* -type f -name '*.log' ! -name 'mirror.log' -exec tail -100 {} \; -exec rm -f {} \;
        > logs/mirror.log
fi

nohup python bin/mirror.py $( find gits -type d -name '*.git' -print -prune ) >> logs/mirror.log 2>&1 &