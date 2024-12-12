#!/bin/bash -ex

export _DEB_DEBUG=debug
export RAVEN_DataDir="/ravendb/data"
package=$(find /deb -iname 'ravendb_*')
source $(dirname $0)/test.sh
test_package_local "$package" || exit 1
