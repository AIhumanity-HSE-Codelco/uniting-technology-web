# DEBBIE-002 — Session Log 2026-06-06

## Server: 164.92.221.55 (AMS3)
- OS: Ubuntu 24.04 LTS
- Node.js v22.22.2
- PM2 v7.0.1
- Nginx 1.24.0
- MariaDB active

## Processes (PM2)
- uniting-tech-api :3000 (API + Telegram Bot)
- dashboard :3001
- agent :3002
- preview :4000

## Files
- Site: /var/www/uniting-tech/public/
- API: /var/www/uniting-tech/api/server.js
- DB: /var/www/uniting-tech/api/database.db
- Backup: /var/www/uniting-tech/backups/

## Credentials
- SSH: root@164.92.221.55 / Uniting26HQ
- SFTP one.com: ce4qjq5sm_ssh@ssh.ce4qjq5sm.service.one
- Telegram Token: stored in /var/www/uniting-tech/api/.env
- Telegram Chat ID: 6794573391
- GitHub: AIhumanity-HSE-Codelco

## DNS
- uniting-tech.com → 164.92.221.55 (propagating)
- www.uniting-tech.com → 164.92.221.55 (propagating)

## API Endpoints
- POST /api/contact → saves lead + Telegram notification
- POST /api/track → visit tracking
- POST /api/newsletter → newsletter signup

## Telegram Bot Commands
- /start — activate
- /stats — leads & visits
- /pm2 — process status
- /deploy — update site from GitHub
- /logs — view logs
- /report — full report
