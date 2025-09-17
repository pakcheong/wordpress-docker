#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
WP_PATH="/var/www/html"
HOST_PORT="${WORDPRESS_DB_HOST:-db:3306}"
DB_HOST="${HOST_PORT%:*}"
DB_PORT="${HOST_PORT#*:}"

log() { printf '%s\n' "[wpcli] $*"; }

# --- Wait for DB TCP port ---
log "Waiting for TCP ${DB_HOST}:${DB_PORT} ..."
for i in {1..120}; do
  if (echo > "/dev/tcp/${DB_HOST}/${DB_PORT}") >/dev/null 2>&1; then
    break
  fi
  sleep 1
  if [ $i -eq 120 ]; then
    log "DB port not reachable after 120s."
    exit 1
  fi
done

# --- Wait for WordPress files (core unpacked by the runtime image) ---
log "Waiting for WordPress files ..."
until [ -f "${WP_PATH}/wp-includes/version.php" ]; do
  sleep 1
done

cd "$WP_PATH"

# --- Ensure wp-config.php exists (do not attempt to connect yet) ---
if [ ! -f wp-config.php ]; then
  log "Generating wp-config.php ..."
  wp config create \
    --dbname="${WORDPRESS_DB_NAME}" \
    --dbuser="${WORDPRESS_DB_USER}" \
    --dbpass="${WORDPRESS_DB_PASSWORD}" \
    --dbhost="${WORDPRESS_DB_HOST}" \
    --skip-check --force
  log "Generated 'wp-config.php'."
fi

# --- Verify DB connectivity via PHP (no external mysql client required) ---
# log "Verifying DB connectivity via PHP mysqli ..."
# for i in {1..60}; do
#   if wp eval '
#     $hostPort = explode(":", DB_HOST, 2);
#     $host = $hostPort[0];
#     $port = isset($hostPort[1]) && strlen($hostPort[1]) ? intval($hostPort[1]) : 3306;
#     $mysqli = mysqli_init();
#     if (! $mysqli) { exit(1); }
#     mysqli_options($mysqli, MYSQLI_OPT_CONNECT_TIMEOUT, 5);
#     $ok = @mysqli_real_connect($mysqli, $host, DB_USER, DB_PASSWORD, DB_NAME, $port);
#     if ($ok) { echo "ok\n"; } else { exit(1); }
#   ' >/dev/null 2>&1; then
#     break
#   fi
#   sleep 2
#   if [ $i -eq 60 ]; then
#     log "DB not ready for PHP mysqli after 120s."
#     exit 1
#   fi
# done

# --- Install core if needed ---
if wp core is-installed >/dev/null 2>&1; then
  log "WordPress already installed. Skipping core install."
else
  log "Installing WordPress core ..."
  wp core install \
    --url="${SITE_URL}" \
    --title="${SITE_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email
fi

# --- Language (optional) ---
if [ -n "${WP_LOCALE:-}" ]; then
  log "Configuring language: ${WP_LOCALE}"
  wp language core install "${WP_LOCALE}" || true
  wp site switch-language "${WP_LOCALE}" || true
fi

# --- Permalinks (optional) ---
if [ -n "${WP_PERMALINK:-}" ]; then
  log "Setting permalink structure: ${WP_PERMALINK}"
  wp option update permalink_structure "${WP_PERMALINK}"
  wp rewrite flush --hard
fi

# --- Timezone (optional) ---
if [ -n "${WP_TIMEZONE:-}" ]; then
  log "Setting timezone: ${WP_TIMEZONE}"
  wp option update timezone_string "${WP_TIMEZONE}"
fi

# --- Plugins (optional, comma-separated slugs) ---
if [ -n "${WP_PLUGINS:-}" ]; then
  IFS=',' read -ra PLUGS <<< "${WP_PLUGINS}"
  for p in "${PLUGS[@]}"; do
    SLUG="$(echo "$p" | xargs)"
    if [ -n "$SLUG" ]; then
      log "Installing & activating plugin: ${SLUG}"
      wp plugin install "$SLUG" --activate || true
    fi
  done
fi

# --- Local plugin zips ---
if [ -d /wp-plugins ]; then
  for z in /wp-plugins/*.zip; do
    [ -e "$z" ] || continue
    base="$(basename "$z")"
    first_char="${base:0:1}"
    if [ "$first_char" = "_" ]; then
      log "Skipping plugin (starts with _): $base"
      continue
    fi
    log "Installing plugin from $z"
    wp plugin install "$z" --activate || true
  done
fi

# --- Local theme zips ---
if [ -d /wp-themes ]; then
  for z in /wp-themes/*.zip; do
    [ -e "$z" ] || continue
    base="$(basename "$z")"
    first_char="${base:0:1}"
    if [ "$first_char" = "_" ]; then
      log "Skipping theme (starts with _): $base"
      continue
    fi
    log "Installing theme from $z"
    wp theme install "$z" --activate || true
  done
fi

# for some unknown reason, repairing is needed before updating following
# wp db repair

# --- Sync site URLs (useful behind reverse proxy) ---
if [ -n "${SITE_URL:-}" ]; then
  log "Ensuring home/siteurl = ${SITE_URL}"
  wp option update home "${SITE_URL}" || true
  wp option update siteurl "${SITE_URL}" || true
fi

log "Done."
