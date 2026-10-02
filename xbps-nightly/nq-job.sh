#!/bin/sh
# nq job: run the xbps-nightly builder; log via syslog.
#
# Enqueued by gitolite's post-receive trigger and by the xbps-builder
# crontab.  nq runs this as the queue owner (xbps-builder), one at a time.
# stdout/stderr go to logger(1) rather than nq's per-job .log so everything
# lands in syslog like the rest of the box.

DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/xbps-nightly" 2>&1 | logger -t xbps-nightly