2. Обеспечить работоспособность приложения при включенном selinux.

Клонируем репозиторий,ерейдём в каталог со стендом и запустим вторую ВМ
git clone https://github.com/Nickmob/vagrant_selinux_dns_problems.git
cd vagrant_selinux_dns_problems
vagrant up

Подключимся к клиенту: 
vagrant ssh client

Пробуем внести изменения в зону (результат отрицательный)
nsupdate -k /etc/named.zonetransfer.key
server 192.168.50.10
zone ddns.lab
update add www.ddns.lab. 60 A 192.168.50.15
send
update failed: SERVFAIL
quit

Для выяснения причин, необходимо посмотреть логи SELinux, используя утилиту audit2why
cat /var/log/audit/audit.log | audit2why
В результатах на клиенте не обнаруживается ошибок

Открываем второй терминал, подключаемся к серверу ns01 по ssh и проверяем логи SELinux
cat /var/log/audit/audit.log | audit2why

В логах видна ошибка в конексте безопасности (используется тип named_conf_t)

Сверим с существущей зоной и ее контекстом
ls -alZ /var/named/named.localhost
В выводе видно, что используется другой тип named_zone_t

В результате анализа, причиной неработоспособности является блокировка SELinux: процессу с контекстом named_t не разрешено создавать файлы в контексте etc_t. Это связано с тем, что путь или разрешения не соответствуют политикам безопасности SELinux.

В качестве решения выбрал использование semanage, для добавления нового правила

semanage fcontext -a -t named_zone_t '/etc/named(/.*)?'
restorecon -R /var/named

Данный способ проще, чем генерация новых политик, не требует анализа логов и создания отдельных модулей. Плюс сокращается риск ошибок и упрощается общее администрирование системы. 

