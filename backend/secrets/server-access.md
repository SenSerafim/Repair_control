# Server access credentials (NOT in git — backend/secrets/ is gitignored)

## Production server

- Host: `193.181.209.219`
- OS: Ubuntu 24.04 (Linux 6.8 kernel)
- Disk: 14GB / (≈1.5GB free at idle — следить!)

## SSH

```bash
ssh admin@193.181.209.219
# password: 9GcXhja8uChW
# user `admin` is in sudoers
```

Для скриптов (CI / автоматизация) — лучше переехать на ключ:
```bash
ssh-copy-id admin@193.181.209.219
```

## Repo location on server

`/home/admin/repair-control` — клон `https://github.com/SenSerafim/Repair_control.git`
(публичный, с него собирается GHCR-образ).

## Деплой одной командой

```bash
ssh admin@193.181.209.219 'cd /home/admin/repair-control && bash backend/scripts/server-update.sh'
```

Полный playbook — `backend/DEPLOY.md`.

## Где секреты приложения

`/home/admin/repair-control/backend/.env.staging` (chmod 600, owner admin).
Содержит JWT-секреты, Selectel S3 keys, FCM creds, SMS API key.
