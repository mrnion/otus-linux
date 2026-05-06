Домашнее задание 
Сценарии iptables

Задание

1.реализовать knocking port
 centralRouter может попасть на ssh inetrRouter через knock скрипт. пример в материалах.
2. добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост.
3. запустить nginx на centralServer.
4. пробросить 80й порт на inetRouter2 8080.
5. дефолт в инет оставить через inetRouter.

Решение:

1. Развернем ВМ используя vagrant
vagrant up
2. Установим knockd на inetRouter и centralRouter
apt install knockd
3. Вносим изменения в конфиг /etc/knockd.conf на inetRouter

[options]
        UseSyslog
        Interface = eth1

[opencloseSSH]
        sequence = 10001:tcp,10002:tcp,10003:tcp
        seq_timeout   = 15
        tcpflags      = syn
        start_command = /sbin/iptables -I INPUT 1 -s %IP% -p tcp --dport 22 -j ACCEPT
        cmd_timeout   = 30
        stop_command  = /sbin/iptables -D INPUT -s %IP% -p tcp --dport ssh -j ACCEPT
        
4. Вносим изменения в файл /etc/iptables_rules.ipv4

*filter
:INPUT ACCEPT [3746:214611]
:FORWARD ACCEPT [193:14668]
:OUTPUT ACCEPT [2188:172583]
:SSH-INPUT - [0:0]
:SSH-INPUTTWO - [0:0]
:TRAFFIC - [0:0]
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -i eth1 -j TRAFFIC
-A SSH-INPUT -m recent --set --name SSH1 --mask 255.255.255.255 --rsource -j DROP
-A SSH-INPUTTWO -m recent --set --name SSH2 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -i eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A TRAFFIC -i eth1 -p tcp -m state --state NEW -m tcp --dport 22 -m recent --rcheck --seconds 30 --name SSH2 --mask 255.255.255.255 --rsource -j ACCEPT
-A TRAFFIC -i eth1 -p tcp -m state --state NEW -m tcp -m recent --remove --name SSH2 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -i eth1 -p tcp -m state --state NEW -m tcp --dport 10003 -m recent --rcheck --name SSH1 --mask 255.255.255.255 --rsource -j SSH-INPUTTWO
-A TRAFFIC -i eth1 -p tcp -m state --state NEW -m tcp -m recent --remove --name SSH1 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -i eth1 -p tcp -m state --state NEW -m tcp --dport 10002 -m recent --rcheck --name SSH0 --mask 255.255.255.255 --rsource -j SSH-INPUT
-A TRAFFIC -i eth1 -p tcp -m state --state NEW -m tcp -m recent --remove --name SSH0 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -i eth1 -p tcp -m state --state NEW -m tcp --dport 10001 -m recent --set --name SSH0 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -i eth1 -j DROP
COMMIT
*nat
:PREROUTING ACCEPT [99:8492]
:INPUT ACCEPT [1:44]
:OUTPUT ACCEPT [61:4301]
:POSTROUTING ACCEPT [21:1271]
-A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
COMMIT

5. Перезагружаем сервер и пробуем подключиться к inetRouter по ssh
root@centralRouter:~# ssh 192.168.255.1
ssh: connect to host 192.168.255.1 port 22: Connection timed out
6. Посылаем knock по указанным в настройках портам 10001,10002,10003 и повторяем попытку подключиться по ssh
root@centralRouter:~# knock 192.168.255.1 10001 10002 10003
root@centralRouter:~# ssh 192.168.255.1
root@192.168.255.1's password:

6. Устанавливаем на centralServer nginx
apt install nginx
8. Настраиваем inetRouter2
Отключаем firewall
systemtcl stop ufw
systemctl disable ufw

Включаем forwarding:
echo "net.ipv4.conf.all.forwarding = 1" >> /etc/sysctl.conf
sysctl -p

Создаем и корректируем файл /etc/iptables_rules.ipv4, содержание файла:

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -p tcp -m tcp --dport 8080 -j DNAT --to-destination 192.168.0.2:80
-A POSTROUTING -d 192.168.0.2/32 -o eth1 -p tcp -m tcp --dport 80 -j SNAT --to-source 192.168.255.14:8080
COMMIT

Создаем файл /etc/network/if-pre-up.d/iptables, содержащий следующий скрипт автоматического восстановления правил при перезапуске системы:
#!/bin/sh
/sbin/iptables-restore < /etc/iptables_rules.ipv4

Добавляем права на выполнение этого файла и перезапускаем сервер
sudo chmod +x /etc/network/if-pre-up.d/iptables

Добавляем доп.сетевой интерфейс eth2 в режиме bridge (для возможности обращения к inetRouter2 с хостовой машины) и прописываем его в конфигурационный файл /etc/netplan/00-installer-config.yml

# This is the network config written by 'subiquity'
network:
  ethernets:
    eth0:
      dhcp4: true
      dhcp6: false
    eth2:
      dhcp4: true
      dhcp6: false
  version: 2

Узнаем ip адрес интерфейса и пробуем открыть его в браузере
root@inetRouter2:~# ip a | grep eth2
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    inet 192.168.88.239/24 metric 100 brd 192.168.88.255 scope global dynamic eth2

<img width="1140" height="466" alt="nginx" src="https://github.com/user-attachments/assets/b07ed8d2-8b4f-4a6f-800c-5684e3091561" />



  

