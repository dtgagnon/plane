#!/usr/bin/env bash
set -e

PLANE_HOME="${PLANE_HOME:-$HOME/.plane}"

function show_usage() {
  echo "Plane - Project Management Tool"
  echo ""
  echo "Usage: plane [command]"
  echo ""
  echo "Commands:"
  echo "  api      Start the Plane API server"
  echo "  worker   Start the Celery worker"
  echo "  beat     Start the Celery beat scheduler"
  echo "  migrate  Run database migrations"
  echo "  web      Start the main web interface"
  echo "  space    Start the workspace interface"
  echo "  admin    Start the admin interface"
  echo "  live     Start the realtime interface"
  echo "  setup    Initialize Plane configuration"
  echo "  help     Show this help message"
  echo ""
}

if [ $# -eq 0 ] || [ "$1" == "help" ]; then
  show_usage
  exit 0
fi

# Setup command creates initial configuration if it doesn't exist
if [ "$1" == "setup" ]; then
  if [ -d "$PLANE_HOME" ]; then
    echo "Configuration directory already exists at $PLANE_HOME"
    echo "To reconfigure, remove this directory first."
    exit 1
  fi
  
  echo "Creating Plane configuration in $PLANE_HOME..."
  mkdir -p "$PLANE_HOME"
  cp -r @basePkg@/share/plane/config/* "$PLANE_HOME/"
  echo "Configuration created. Edit files in $PLANE_HOME before starting services."
  exit 0
fi

# For all other commands, launch the appropriate binary
case "$1" in
  api|worker|beat|migrate|web|space|admin|live)
    exec "@basePkg@/bin/$1" "${@:2}"
    ;;
  *)
    echo "Unknown command: $1"
    show_usage
    exit 1
    ;;
esac
