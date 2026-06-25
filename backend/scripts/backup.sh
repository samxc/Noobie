#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$ROOT_DIR/backups"
mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_DIR/noobie-$STAMP.tar.gz" -C "$ROOT_DIR" data pb_data 2>/dev/null || \
  tar -czf "$BACKUP_DIR/noobie-$STAMP.tar.gz" -C "$ROOT_DIR" data

echo "$BACKUP_DIR/noobie-$STAMP.tar.gz"
