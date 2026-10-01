# Автозапуск SpiderSoft через systemd

SpiderSoft запускается и управляется через systemd-unit `spidersoft.service`.

Unit управляет production-стеком Docker Compose и запускает сервисы с профилями `core` и `monitoring`.

## Основные команды

```bash
sudo systemctl start spidersoft.service
sudo systemctl stop spidersoft.service
sudo systemctl restart spidersoft.service
systemctl status spidersoft.service
```

Проверка состояния:

```bash
systemctl is-active spidersoft.service
docker compose -p spidersoft ps
```

## Автозапуск

Unit включён в автозапуск:

```bash
sudo systemctl enable spidersoft.service
```

При загрузке системы порядок запуска:

```text
Система
  ↓
Сеть
  ↓
Docker
  ↓
spidersoft.service
  ↓
Docker Compose
  ↓
SpiderSoft containers
```

SpiderSoft запускается после `docker.service` и `network-online.target`.

## Конфигурация

Unit расположен в:

```text
/etc/systemd/system/spidersoft.service
```

Рабочий каталог Compose:

```text
/opt/spidersoft/docker
```

Для запуска используется:

```bash
docker compose -p spidersoft --profile core --profile monitoring up -d
```

Для остановки:

```bash
docker compose -p spidersoft down
```

## Диагностика

Статус unit:

```bash
systemctl status spidersoft.service
```

Журнал:

```bash
journalctl -u spidersoft.service
```

Логи контейнеров:

```bash
docker compose -p spidersoft logs
```

После изменения unit-файла необходимо перечитать конфигурацию systemd:

```bash
sudo systemctl daemon-reload
```
