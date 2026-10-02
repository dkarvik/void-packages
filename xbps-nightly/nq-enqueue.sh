#!/bin/sh
# nq enqueue shim - the single command gitolite's trigger is allowed to run
# as xbps-builder.  Sets the queue dir, then enqueues the builder job.
#
# Sudoers rule:
#   gitolite ALL=(xbps-builder) NOPASSWD: \
#     /var/lib/xbps-builder/void-packages/xbps-nightly/nq-enqueue.sh

DIR="$(cd "$(dirname "$0")" && pwd)"
export NQDIR=/var/lib/xbps-builder/nq
mkdir -p "$NQDIR"
exec /usr/bin/nq "$DIR/nq-job.sh"