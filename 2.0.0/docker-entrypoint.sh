#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

set -e

if [ "$1" = '/opt/couchdb/bin/couchdb' ]; then
	# we need to set the permissions here because docker mounts volumes as root
	chown -R couchdb:couchdb /opt/couchdb

	chmod -R 0770 /opt/couchdb/data

	chmod 664 /opt/couchdb/etc/*.ini
	chmod 775 /opt/couchdb/etc/*.d

	if [ ! -z "$NODENAME" ] && ! grep "couchdb@" /opt/couchdb/etc/vm.args; then
		echo "-name couchdb@$NODENAME" >> /opt/couchdb/etc/vm.args
	fi

	if [ "$COUCHDB_USER" ] && [ "$COUCHDB_PASSWORD" ]; then
		# Create admin
		printf "[admins]\n%s = %s\n" "$COUCHDB_USER" "$COUCHDB_PASSWORD" > /opt/couchdb/etc/local.d/docker.ini
		chown couchdb:couchdb /opt/couchdb/etc/local.d/docker.ini
	fi

	# if we don't find an [admins] section followed by a non-comment, display a warning
	if ! grep -Pzoqr '\[admins\]\n[^;]\w+' /opt/couchdb/etc/local.d/*.ini; then
		# The - option suppresses leading tabs but *not* spaces. :)
		cat >&2 <<-'EOWARN'
			****************************************************
			WARNING: CouchDB is running in Admin Party mode.
			         This will allow anyone with access to the
			         CouchDB port to access your database. In
			         Docker's default configuration, this is
			         effectively any other container on the same
			         system.
			         Use "-e COUCHDB_USER=admin -e COUCHDB_PASSWORD=password"
			         to set it in "docker run".
			****************************************************
		EOWARN
	fi


	# ============= Initialize DB =======================
	chown -R couchdb:couchdb /docker-entrypoint-initdb.d

	"$@" &
	pid="$!"
	echo "CouchDB starting... with pid $pid"
	URL="http://127.0.0.1:5984"
	for i in {30..0}; do
		echo 'CouchDB init process in progress...'
		if [ $(curl --write-out %{http_code} --silent --output /dev/null "$URL") -eq "200" ]; then
		  break
		fi
		sleep 1
	done
	if [ "$i" = 0 ]; then
		echo >&2 'CouchDB init process failed.'
		exit 1
	fi

	### Load data
	INIT_DB_PATH="/docker-entrypoint-initdb.d"
	for f in $INIT_DB_PATH/* $INIT_DB_PATH/**/* ; do
	  # parse to get db name and design doc name
	  while IFS='/' read -ra pathArr; do
	    # get DB name
	    DB="${pathArr[2]}"
	    # set name of design doc
	    DESIGN_NAME="$(echo ${pathArr[3]} | sed 's/.json//')"
	  done <<< "$f"
	  # if $name is not blank, make the curl call
	  if [ ! -z "$DESIGN_NAME" -a "$DESIGN_NAME" != " " ]; then
	    echo "---- Adding design: $DESIGN_NAME to DB: $DB using file: $f"
			curl --data "@$f" -X PUT $URL/$DB/_design/$DESIGN_NAME
	  else
	    # if name is blank, i'm at the folder which is the DB name.  Create the DB
			echo "==== Creating DB: $DB"
	    curl -X PUT $URL/$DB
	  fi
	done;

	echo "Adding basic DBs for node setup"
	curl -X PUT http://127.0.0.1:5984/_users
	curl -X PUT http://127.0.0.1:5984/_replicator
	curl -X PUT http://127.0.0.1:5984/_global_changes


	echo "Stopping CouchDB..."
	while kill "$pid"; do
  	sleep 0.5
		echo "Stopping CouchDB..."
  done

	echo
	echo 'CouchDB data init process done. Ready for start up.'
	echo


	exec gosu couchdb "$@"
fi


exec "$@"
