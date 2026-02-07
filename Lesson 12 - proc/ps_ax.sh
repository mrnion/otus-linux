#!/bin/bash

echo "PID TTY STAT TIME CMD"

for pid in /proc/[0-9]*; do
pid_num=$(basename $pid)

# Читаем статус процесса
if [ -f "$pid/stat" ]; then
stat_line=$(cat "$pid/stat")
# Извлекаем имя процесса (поле 2 в скобках)
cmd=$(echo "$stat_line" | awk '{print $2}' | tr -d '()')

# Статус (поле 3)
state=$(echo "$stat_line" | awk '{print $3}')

# Время CPU (поле 14 + 15)
utime=$(echo "$stat_line" | awk '{print $14}')
stime=$(echo "$stat_line" | awk '{print $15}')
total_time=$((utime + stime))

# TTY (поле 7)
tty=$(echo "$stat_line" | awk '{print $7}')
if [ "$tty" = "0" ]; then tty="?"; else tty="tty$(($tty - 2048))"; fi

echo "$pid_num $tty $state $total_time $cmd"
fi
done
