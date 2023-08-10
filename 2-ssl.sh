#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# TYPE="$(nuv debug detect)"
TYPE="${1:?test type}"
EMAIL=msciabarra@apache.org

if $TYPE == "kind"; then
	echo SKIPPING
	exit 1
fi

rn=$(nuv -random --str 5)

if $TYPE == "osh"; then
	# configure
	nuv config apihost api.$rn.apps.nuvolaris.osh.n9s.cc --tls $EMAIL
	nuv update apply

else
	nuv config reset
	task aws:config

	# configure
	nuv config apihost nuvolaris.$rn.$TYPE.n9s.cc --tls $EMAIL
	nuv update apply
fi

# check we have https
if nuv debug status | grep "apihost: https://"; then
	echo SUCCESS
	exit 0
else
	echo FAIL
	exit 1
fi
