#!/bin/sh
# setup-server.sh - run ON THE SERVER (as root) to bootstrap the xbps-nightly
# builder.  Assumes:
#   - this checkout is already cloned to /var/lib/xbps-builder/void-packages
#     on branch personal
#   - cronie (or your cron) installed
#   - caddy installed (optional, for serving)
# This should be idempotent; safe to re-run.

set -eu

VPDIR=${VPDIR:-/var/lib/xbps-builder/void-packages}
BUILDER=${BUILDER:-xbps-builder}
BUILDER_HOME=${BUILDER_HOME:-/var/lib/xbps-builder}
CRON_TIME=${CRON_TIME:-"15 4 * * *"}
LOGFILE=/var/log/xbps-nightly.log

echo "==> creating builder user (if missing)"
id -u "$BUILDER" >/dev/null 2>&1 || useradd -r -m -d "$BUILDER_HOME" "$BUILDER"
mkdir -p "$BUILDER_HOME" && chown "$BUILDER:" "$BUILDER_HOME"
chown -R "$BUILDER:" "$VPDIR"

echo "==> build dependencies on the host"
xbps-install -Sy git xz curl ca-certificates util-linux bsdtar binutils cronie nq 2>/dev/null || true

echo "==> first build (bootstrap + build + sign). This takes a while."
su -s /bin/sh "$BUILDER" -c "$VPDIR/xbps-nightly/xbps-nightly" \
	>>"$LOGFILE" 2>&1 || echo "first build returned non-zero (see $LOGFILE)"

echo "==> install cron (enqueues via nq; jobs serialize with push triggers)"
CRONTAB=$(crontab -l 2>/dev/null || true)
case "$CRONTAB" in
	*xbps-nightly*) echo "cron already installed" ;;
	*)
		(printf '%s\n' "$CRONTAB"
		 printf '%s NQDIR=/var/lib/xbps-builder/nq /usr/bin/nq /var/lib/xbps-builder/void-packages/xbps-nightly/nq-job.sh >> %s 2>&1\n' \
		 	"$CRON_TIME" "$LOGFILE") | crontab -
		echo "cron added: $CRON_TIME"
		;;
esac

echo "==> runit service for serving via caddy (configure /etc/caddy/Caddyfile yourself)"
echo "    See xbps-nightly/hooks/ and the README for caddy and repo-keys setup."

echo "done."
echo
echo "Optional push-back: if PUSH_REMOTE is set in xbps-nightly.conf the"
echo "builder force-pushes the rebased branch after each successful run."
echo "Create /var/lib/xbps-builder/void-packages/xbps-nightly/xbps-nightly.conf like:"
echo "  PUSH_REMOTE=fortmonroe"