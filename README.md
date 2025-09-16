# WordPress Docker Setup

This project provides a Docker Compose setup for running WordPress with MySQL, plus an automated **WP-CLI bootstrap** script to install and configure the site.

---

## 📂 Project Structure

```text
.
├── bootstrap/             # Initialization scripts
│   └── wp-init.sh         # WP-CLI bootstrap script
├── docker-compose.yml     # Docker Compose configuration
├── mount/                 # Mounted local resources
│   ├── plugins/           # Plugin ZIPs to be auto-installed
│   ├── themes/            # Theme ZIPs to be auto-installed
│   ├── uploads.ini        # PHP upload config override
│   └── activationkey.php  # Example custom file
├── volumes/               # WordPress & MySQL data (git-ignored)
└── restart.sh             # Helper script to restart containers
```

---

## 🚀 Usage

### 1. Start services
```bash
docker compose up -d
```

This will start:
- **WordPress** (latest)
- **MySQL 8.4**
- **WP-CLI one-time container** (`wpcli`) which runs `bootstrap/wp-init.sh`.

### 2. Restart workflow
Use the helper script:
```bash
./restart.sh
```

This clears old containers, restarts services, and re-runs the `wpcli` init.

### 3. Auto-install plugins & themes
- Place plugin `.zip` files in `./mount/plugins/`
- Place theme `.zip` files in `./mount/themes/`

On initialization, the `wpcli` container will:
- Install WordPress core (if not installed)
- Set site title, admin user, permalink, timezone, etc.
- Install plugins defined in `.env` (`WP_PLUGINS`)
- Install all ZIPs found in `./mount/plugins/`
- Install all ZIPs found in `./mount/themes/`

### 4. Environment variables
Site configuration is controlled via `.env`. Example:

```ini
SITE_URL=http://localhost:8080
SITE_TITLE=My Awesome Site
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=changeme123
WP_ADMIN_EMAIL=admin@example.com
WP_PLUGINS=classic-editor
WP_LOCALE=zh_CN
WP_PERMALINK=/%postname%/
WP_TIMEZONE=Asia/Shanghai
```

---

## 🛠 Troubleshooting

- If you see `Could not create directory` errors, ensure the mounted `volumes/` directory is writable.  
- To verify mounted ZIPs inside `wpcli`:
  ```bash
  docker compose exec wpcli ls -l /wp-plugins
  docker compose exec wpcli ls -l /wp-themes
  ```

---

## 📑 Notes

- Data is persisted in `./volumes/wordpress` and `./volumes/database`.
- To reset WordPress core files without touching DB:
  ```bash
  rm -rf ./volumes/wordpress/*
  docker compose up -d wordpress
  ```
- `restart.sh` is tailored to your `dockcomp.sh` management script — adjust if needed.
