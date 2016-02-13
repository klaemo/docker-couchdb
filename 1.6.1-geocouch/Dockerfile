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

FROM couchdb:1.6.1

MAINTAINER Jon Richter almereyda@allmende.io

# https://www.apache.org/dist/couchdb/KEYS
ENV GPG_KEYS \
 15DD4F3B8AACA54740EB78C7B7B7C53943ECCEE1 \
 1CFBFA43C19B6DF4A0CA3934669C02FFDF3CEBA3 \
 25BBBAC113C1BFD5AA594A4C9F96B92930380381 \
 4BFCA2B99BADC6F9F105BEC9C5E32E2D6B065BFB \
 5D680346FAA3E51B29DBCB681015F68F9DA248BC \
 7BCCEB868313DDA925DF1805ECA5BCB7BB9656B0 \
 C3F4DFAEAD621E1C94523AEEC376457E61D50B88 \
 D2B17F9DA23C0A10991AF2E3D9EE01E47852AEE4 \
 E0AF0A194D55C84E4A19A801CDB0C0F904F4EE9B
RUN set -xe \
 && for key in $GPG_KEYS; do \
   gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
 done

ENV COUCHDB_VERSION 1.6.1

WORKDIR /usr/src

RUN apt-get update && apt-get install -y git make \
 && curl -fSL http://apache.osuosl.org/couchdb/source/$COUCHDB_VERSION/apache-couchdb-$COUCHDB_VERSION.tar.gz -o couchdb.tar.gz \
 && curl -fSL https://www.apache.org/dist/couchdb/source/$COUCHDB_VERSION/apache-couchdb-$COUCHDB_VERSION.tar.gz.asc -o couchdb.tar.gz.asc \
 && gpg --verify couchdb.tar.gz.asc \
 && mkdir -p /usr/src/couchdb \
 && tar -xzf couchdb.tar.gz -C /usr/src/couchdb --strip-components=1

ENV COUCH_SRC /usr/src/couchdb/src/couchdb/
ENV GEOCOUCH_SHA 1bad2275756e2f03151d7b2706c089b3059736130612de279d879db91d4b21e7

RUN curl -L -o geocouch.tar.gz https://github.com/couchbase/geocouch/archive/couchdb1.3.x.tar.gz \
 && echo "$GEOCOUCH_SHA *geocouch.tar.gz" | sha256sum -c - \
 && mkdir geocouch \
 && tar -xzf geocouch.tar.gz -C geocouch --strip-components=1 \
 && cd geocouch \
 && make \
 && cp /usr/src/geocouch/etc/couchdb/default.d/geocouch.ini /usr/local/etc/couchdb/default.d/geocouch.ini

RUN apt-get purge -y --auto-remove git make \
 && rm -rf /usr/src/couchdb /usr/src/couchdb.tar.gz* /usr/src/geocouch.tar.gz* \
 && chown -R couchdb:couchdb /usr/src/geocouch/ebin

ENV ERL_FLAGS="+A 4 -pa /usr/src/geocouch/ebin"
