# Monitor Test Project

Этот проект реализует мониторинг процесса `test` в Linux-системе с использованием Bash и systemd.

## 📋 Функциональность

- Проверяет наличие процесса `test` каждую минуту.
- Если процесс работает — делает HTTPS-запрос на `https://test.com/monitoring/test/api`.
- Если процесс был перезапущен — пишет в лог `/var/log/monitoring.log`.
- Если API недоступен — пишет в лог об ошибке.

## Установка (рекомендуемые шаги)

> Выполняйте команды от root или через sudo.

1. Создать системного пользователя для мониторинга (чтобы не запускать скрипт от root):
```bash
sudo useradd -r -s /usr/sbin/nologin monitoring || true
```

2. Создать директории и скопировать файлы:
```bash
sudo mkdir -p /usr/local/bin
sudo mkdir -p /etc/systemd/system
sudo mkdir -p /etc/logrotate.d
sudo mkdir -p /var/log
sudo mkdir -p /var/run
sudo cp usr/local/bin/monitor_test.sh /usr/local/bin/
sudo cp etc/systemd/system/monitor-test.service /etc/systemd/system/
sudo cp etc/systemd/system/monitor-test.timer /etc/systemd/system/
sudo cp etc/logrotate.d/monitoring /etc/logrotate.d/monitoring
sudo touch /var/log/monitoring.log
sudo chown monitoring:monitoring /var/log/monitoring.log
sudo chmod 0640 /var/log/monitoring.log
```

3. Настроить права на state-файл (путь /var/run — может очищаться при reboot):
```bash
sudo touch /var/run/monitor_test.state
sudo chown monitoring:monitoring /var/run/monitor_test.state
sudo chmod 0644 /var/run/monitor_test.state
```

4. Перезагрузить systemd и включить таймер:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now monitor-test.timer
```

5. Проверить статус таймера и юнита:
```bash
systemctl status monitor-test.timer
systemctl list-timers --all | grep monitor-test
journalctl -u monitor-test.service
tail -n 100 /var/log/monitoring.log
```

## Безопасность и замечания
- Скрипт не должен запускаться от `root`. Создайте пользователя `monitoring` и назначьте ему владение над логом.
- Лог-файл ротацируется `logrotate` (файл `/etc/logrotate.d/monitoring` включён).
- Учтите, что `/var/run` (или `/run`) очищается при перезагрузке — можно создать systemd tmpfile-юнит или в сервисе создать state-файл при запуске.
- Скрипт использует `curl` для проверки API; убедитесь, что пакет установлен.

## Структура проекта
```
.
├── usr
│   └── local
│       └── bin
│           └── monitor_test.sh
├── etc
│   └── systemd
│       └── system
│           ├── monitor-test.service
│           └── monitor-test.timer
├── etc
│   └── logrotate.d
│       └── monitoring
├── var
│   └── log
│       └── monitoring.log (создаётся автоматически)
└── README.md
```

