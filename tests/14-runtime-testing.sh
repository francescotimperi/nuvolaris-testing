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
TYPE="${1:?test type}"
TYPE="$(echo $TYPE | awk -F- '{print $1}')"

user="testactionuser"
password=$(nuv -random --str 12)

if nuv admin adduser $user $user@email.com $password --minio --redis --mongodb --postgres | grep "whiskuser.nuvolaris.org/$user created"
then echo SUCCESS CREATING $user
else echo FAIL CREATING $user; exit 1 
fi

nuv debug kube ctl CMD="wait --for=condition=ready --timeout=60s -n nuvolaris wsku/$user"

case "$TYPE" in
    (kind) 
        if NUV_LOGIN=$user NUV_PASSWORD=$password nuv -login http://localhost:80 | grep "Successfully logged in as $user."
        then echo SUCCESS LOGIN
        else echo FAIL LOGIN ; exit 1 
        fi
    ;;
    *)
        APIURL=$(nuv debug apihost | awk '/whisk API host/{print $4}')
        if NUV_LOGIN=$user NUV_PASSWORD=$password nuv -login $APIURL | grep "Successfully logged in as $user."
        then echo SUCCESS LOGIN
        else echo FAIL LOGIN ; exit 1 
        fi
    ;;    
esac

export MINIO_ACCESS_KEY=$(nuv -config MINIO_ACCESS_KEY)
export MINIO_SECRET_KEY=$(nuv -config MINIO_SECRET_KEY)
export MINIO_HOST=$(nuv -config MINIO_HOST)
export MINIO_PORT=$(nuv -config MINIO_PORT)
export MINIO_DATA_BUCKET=$(nuv -config MINIO_DATA_BUCKET)
export MINIO_STATIC_BUCKET=$(nuv -config MINIO_STATIC_BUCKET)
export REDIS_URL=$(nuv -config REDIS_URL)
export REDIS_PREFIX=$(nuv -config REDIS_PREFIX)
export MONGODB_URL=$(nuv -config MONGODB_URL)
export MONGODB_DB=$user
export POSTGRES_URL=$(nuv -config POSTGRES_URL)

PWD=$(pwd)

if nuv -wsk project deploy --manifest ${PWD}/test-runtimes/manifest.yaml | grep Success
then echo SUCCESS DEPLOY PROJECT;
else echo FAIL DEPLOY PROJECT; exit 1 
fi

if nuv -wsk action invoke javascript/hello -r| grep world 
then echo SUCCESS JS HELLO;
else echo FAIL JS HELLO; exit 1
fi

if nuv -wsk action invoke javascript/redis -r| grep hello
then echo SUCCESS JS REDIS;
else echo FAIL JS REDIS; exit 1 
fi

if nuv -wsk action invoke javascript/mongodb -r| grep hello
then echo SUCCESS JS FERRETDB;
else echo FAIL JS FERRETDB; exit 1 
fi

if nuv -wsk action invoke javascript/postgres -r| grep 'Nuvolaris Postgres is up and running!'
then echo SUCCESS JS POSTGRES; 
else echo FAIL JS POSTGRES; exit 1 
fi

if nuv -wsk action invoke javascript/minio -r| grep "$user-data"
then echo SUCCESS JS MINIO; 
else echo FAIL JS MINIO; exit 1 
fi

if nuv -wsk action invoke python/hello -r| grep world 
then echo SUCCESS PYTHON HELLO;
else echo FAIL PYTHON HELLO; exit 1
fi

if nuv -wsk action invoke python/redis -r| grep world
then echo SUCCESS PYTHON REDIS;
else echo FAIL PYTHON REDIS; exit 1
fi

if nuv -wsk action invoke python/mongodb -r| grep world
then echo SUCCESS PYTHON FERRETDB;
else echo FAIL PYTHON FERRETDB; exit 1
fi

if nuv -wsk action invoke python/postgres -r| grep 'Nuvolaris Postgres is up and running!'
then echo SUCCESS PYTHON POSTGRES;
else echo FAIL PYTHON POSTGRES; exit 1
fi

if nuv -wsk action invoke python/minio -r| grep "$user-data"
then echo SUCCESS PYTHON MINIO; exit 0
else echo FAIL PYTHON MINIO; exit 1
fi
