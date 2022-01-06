#!/bin/sh
#
# xray        Startup script for xray
#
# chkconfig: - 24 76
# processname: xray
# pidfile: /var/run/xray.pid
# description: xray proxy services
#

### BEGIN INIT INFO
# Provides:          xray
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: xray proxy services
# Description:       xray proxy services
### END INIT INFO

DESC=xray
NAME=xray
DAEMON=/opt/xray/xray
PIDFILE=/var/run/$NAME.pid
LOCKFILE=/var/lock/subsys/$NAME
SCRIPTNAME=/etc/init.d/$NAME
RETVAL=0

DAEMON_OPTS="-config /opt/xray/config.json"

# Exit if the package is not installed
[ -x $DAEMON ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Source function library.
. /etc/rc.d/init.d/functions

start() {
  local pids=$(pgrep -f $DAEMON)
  if [ -n "$pids" ]; then
    echo "$NAME (pid $pids) is already running"
    RETVAL=0
    return 0
  fi

  echo -n $"Starting $NAME: "

  mkdir -p /var/log/xray
  $DAEMON $DAEMON_OPTS 1>/dev/null 2>&1 &
  echo $! > $PIDFILE

  sleep 2
  pgrep -f $DAEMON >/dev/null 2>&1
  RETVAL=$?
  if [ $RETVAL -eq 0 ]; then
    success; echo
    touch $LOCKFILE
  else
    failure; echo
  fi
  return $RETVAL
}

stop() {
  local pids=$(pgrep -f $DAEMON)
  if [ -z "$pids" ]; then
    echo "$NAME is not running"
    RETVAL=0
    return 0
  fi

  echo -n $"Stopping $NAME: "
  killproc -p ${PIDFILE} ${NAME}
  RETVAL=$?
  echo
  [ $RETVAL = 0 ] && rm -f ${LOCKFILE} ${PIDFILE}
}

reload() {
  echo -n $"Reloading $NAME: "
  killproc -p ${PIDFILE} ${NAME} -HUP
  RETVAL=$?
  echo
}

rh_status() {
  status -p ${PIDFILE} ${DAEMON}
}

# See how we were called.
case "$1" in
  start)
    rh_status >/dev/null 2>&1 && exit 0
    start
    ;;
  stop)
    stop
    ;;
  status)
    rh_status
    RETVAL=$?
    ;;
  restart)
    stop
    start
    ;;
  reload)
    reload
  ;;
  *)
    echo "Usage: $SCRIPTNAME {start|stop|status|reload|restart}" >&2
    RETVAL=2
  ;;
esac
exit $RETVAL
