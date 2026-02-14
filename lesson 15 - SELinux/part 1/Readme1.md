Сперва устанавливаем nginx и перенаправляем 80 порт на 4881

yum -y nginx
sed -i 's/:80/:4881/g' /etc/nginx/nginx.conf
sed -i 's/listen       80;/listen       4881;/' /etc/nginx/nginx.conf

При попытке запустить nginx видим ошибку:

× nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: failed (Result: exit-code) since Sat 2026-02-14 14:30:33 MSK; 3min 22s ago
    Process: 11856 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 11857 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
        CPU: 14ms

Feb 14 14:30:33 localhost.localdomain systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 14 14:30:33 localhost.localdomain nginx[11857]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 14 14:30:33 localhost.localdomain nginx[11857]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Feb 14 14:30:33 localhost.localdomain nginx[11857]: nginx: configuration file /etc/nginx/nginx.conf test failed
Feb 14 14:30:33 localhost.localdomain systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Feb 14 14:30:33 localhost.localdomain systemd[1]: nginx.service: Failed with result 'exit-code'.
Feb 14 14:30:33 localhost.localdomain systemd[1]: Failed to start The nginx HTTP and reverse proxy server.

Затем отключем firewall и проверяем:
systemctl stop firewalld
systemctl status firewalld

Также проверим режим работы SELinux (результат должен быть Enforcing):
getenforce

Решение:
#################################################################################################################################################################################
1. Разрешим работу nginx на 4881 порту с помощью переключателей setsebool
Находим и получаем время лога с ошибкой запуска nginx
LOG_TIME=$(grep "/usr/sbin/nginx" /var/log/audit/audit.log | awk '{print $2}' | grep -E -o "[0-9]*\.[0-9]{3}:[0-9]{3}")

Расшифровывем ошибку с помощью утилиты audit2why 
grep "$LOG_TIME" /var/log/audit/audit.log | audit2why
Исходя из вывода утилиты, мы видим, что нам нужно поменять параметр nis_enabled. 

Включаем параметр nis_enabled и перезагрузим nginx
setsebool -P nis_enabled on
systemctl restart nginx

Проверяем запустился ли nginx
systemctl status nginx

● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Sat 2026-02-14 14:53:34 MSK; 5s ago
    Process: 11912 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 11913 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 11914 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 11916 (nginx)
      Tasks: 5 (limit: 23098)
     Memory: 5.1M (peak: 5.7M)
        CPU: 33ms
     CGroup: /system.slice/nginx.service
             ├─11916 "nginx: master process /usr/sbin/nginx"
             ├─11917 "nginx: worker process"
             ├─11918 "nginx: worker process"
             ├─11919 "nginx: worker process"
             └─11920 "nginx: worker process"

Feb 14 14:53:34 localhost.localdomain systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 14 14:53:34 localhost.localdomain nginx[11913]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 14 14:53:34 localhost.localdomain nginx[11913]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Feb 14 14:53:34 localhost.localdomain systemd[1]: Started The nginx HTTP and reverse proxy server.

Возвращаем запрет работы nginx на порту 4881
setsebool -P nis_enabled off

Проверяем статус параметра
getsebool -a | grep nis_enabled

#################################################################################################################################################################################
2.Разрешим работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип:

Получаем имеющиеся типы, для http трафика
semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989

Добавим порт в тип http_port_t: 
semanage port -a -t http_port_t -p tcp 4881

Убеждаемся, что порт добавлен
semanage port -l | grep  http_port_t
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988

Перезапускаем nginx и проверяем, что он запустился
systemctl restart nginx
systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Sat 2026-02-14 15:02:13 MSK; 5s ago
    Process: 11959 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 11961 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 11962 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 11963 (nginx)
      Tasks: 5 (limit: 23098)
     Memory: 5.6M (peak: 6.0M)
        CPU: 42ms
     CGroup: /system.slice/nginx.service
             ├─11963 "nginx: master process /usr/sbin/nginx"
             ├─11964 "nginx: worker process"
             ├─11965 "nginx: worker process"
             ├─11966 "nginx: worker process"
             └─11967 "nginx: worker process"

Feb 14 15:02:13 localhost.localdomain systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 14 15:02:13 localhost.localdomain nginx[11961]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 14 15:02:13 localhost.localdomain nginx[11961]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Feb 14 15:02:13 localhost.localdomain systemd[1]: Started The nginx HTTP and reverse proxy server.

Удаляем нестандартный порт из имеющегося типа и проверяем, что он удалился:
semanage port -d -t http_port_t -p tcp 4881
semanage port -l | grep  http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988

Перезагружаем nginx и пробуем запустить (убеждаемся, что он не стартует)
systemctl restart nginx
systemctl status nginx
× nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: failed (Result: exit-code) since Sat 2026-02-14 15:05:29 MSK; 7s ago
   Duration: 3min 16.165s
    Process: 11982 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 11983 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
        CPU: 22ms

Feb 14 15:05:29 localhost.localdomain systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 14 15:05:29 localhost.localdomain nginx[11983]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 14 15:05:29 localhost.localdomain nginx[11983]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Feb 14 15:05:29 localhost.localdomain nginx[11983]: nginx: configuration file /etc/nginx/nginx.conf test failed
Feb 14 15:05:29 localhost.localdomain systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Feb 14 15:05:29 localhost.localdomain systemd[1]: nginx.service: Failed with result 'exit-code'.
Feb 14 15:05:29 localhost.localdomain systemd[1]: Failed to start The nginx HTTP and reverse proxy server.

#################################################################################################################################################################################
3. Разрешим работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux:

Пробуем запустить nginx и убеждаемся, что он не стартует
systemctl start nginx

С помощью утилиты audit2allow создаём модуль на основе логов SELinux разрешающий работу nginx на нестандартном порту
grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:
semodule -i nginx.pp

Применяем сформированный модуль
semodule -i nginx.pp

Попробуем снова запустить nginx:
systemctl start nginx

Проверяем, запустился или нет:
systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Sat 2026-02-14 15:11:05 MSK; 13s ago
    Process: 12010 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 12011 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 12012 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 12013 (nginx)
      Tasks: 5 (limit: 23098)
     Memory: 8.8M (peak: 9.0M)
        CPU: 42ms
     CGroup: /system.slice/nginx.service
             ├─12013 "nginx: master process /usr/sbin/nginx"
             ├─12014 "nginx: worker process"
             ├─12015 "nginx: worker process"
             ├─12016 "nginx: worker process"
             └─12017 "nginx: worker process"

Feb 14 15:11:05 localhost.localdomain systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 14 15:11:05 localhost.localdomain nginx[12011]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Feb 14 15:11:05 localhost.localdomain nginx[12011]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Feb 14 15:11:05 localhost.localdomain systemd[1]: Started The nginx HTTP and reverse proxy server.

Удалим созданный модуль: 
semodule -r nginx

