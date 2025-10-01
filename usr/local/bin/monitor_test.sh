#!/usr/bin/env bash
# monitor_test.sh
# Скрипт мониторинга процесса 'test'
# Пишет в /var/log/monitoring.log и хранит текущий PID в /var/run/monitor_test.state

set -euo pipefail

LOG_FILE="/var/log/monitoring.log"
STATE_FILE="/var/run/monitor_test.state"
API_URL="https://test.com/monitoring/test/api"

# Функция для записи в лог с временной меткой
log() {
    local level="$1"
    local msg="$2"
    # Формируем запись: [YYYY-MM-DD HH:MM:SS] LEVEL: сообщение
    printf '[%s] %s: %s\n' "$(date '+%F %T')" "$level" "$msg" >> "$LOG_FILE"
}

# Получаем PID процесса 'test' (точное имя процесса)
# Если процессов несколько, берём первый (pgrep по имени возвращает все PID)
current_pid=""
if pgrep -x test >/dev/null 2>&1; then
    # Берём первый PID из pgrep
    current_pid="$(pgrep -x test | head -n1)"
else
    current_pid=""
fi

# Считываем предыдущий PID, если файл существует
previous_pid=""
if [[ -f "$STATE_FILE" ]]; then
    previous_pid="$(cat "$STATE_FILE" 2>/dev/null || true)"
fi

# Если текущий PID пустой — процесса нет
if [[ -z "$current_pid" ]]; then
    # Если ранее процесс был запущен (есть previous_pid) — логируем остановку
    if [[ -n "$previous_pid" ]]; then
        log "WARN" "Процесс 'test' остановился (previous PID: ${previous_pid})."
        # Удалим state-файл — чтобы при следующем старте зафиксировать перезапуск
        rm -f "$STATE_FILE" || true
    fi
    # В любом случае проверяем API — чтобы зафиксировать недоступность, если нужно
    if ! curl --fail --silent --show-error --max-time 5 "$API_URL" > /dev/null 2>&1; then
        log "ERROR" "API недоступен при отсутствии процесса 'test'."
    fi
    exit 0
fi

# Если предыдущий PID отличается от текущего — процесс перезапущен
if [[ -n "$previous_pid" && "$previous_pid" != "$current_pid" ]]; then
    log "INFO" "Процесс 'test' перезапущен (old PID: ${previous_pid}, new PID: ${current_pid})."
fi

# Сохраняем текущий PID в state-файл
# Используем временный файл и atomic mv, чтобы избежать частичных записей
tmp_state="$(mktemp)"
printf '%s' "$current_pid" > "$tmp_state"
mv "$tmp_state" "$STATE_FILE"
chmod 0644 "$STATE_FILE" || true

# Если процесс работает — делаем HTTPS-запрос к API и логируем ошибки
if ! curl --fail --silent --show-error --max-time 5 "$API_URL" > /dev/null 2>&1; then
    log "ERROR" "API недоступен при запущенном процессе 'test' (PID: ${current_pid})."
else
    # Можно логировать успешную проверку по желанию — закомментировано, чтобы не засорять лог
    # log "INFO" "API доступен (PID: ${current_pid})."
    true
fi

exit 0
