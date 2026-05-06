Домашнее задание 
PAM 

Цель:
научиться создавать пользователей и добавлять им ограничения;

Что нужно сделать?
Ограничить доступ к системе для всех пользователей, кроме группы администраторов, в выходные дни (суббота и воскресенье), за исключением праздничных дней.

Выполнение:

1. Запускаем и подключаемся к ВМ
$ vagrant up
$ vagrant ssh

2. Переключаемся в root и создаем пользователей otusadm и otus
vagrant@pam:~$ su
root@pam:~# useradd otusadm && useradd otus

3. Задаем этим пользователям пароли
root@pam:~# passwd otusadm
root@pam:~# passwd otus

4. Создаем группу admin и добавляем в нее пользователей vagrant,root и otusadm
root@pam:~# usermod otusadm -a -G admin && usermod root -a -G admin && usermod vagrant -a -G admin

5. Пробуем подключиться в ВМ по SSH
root@pam:~# ssh otus@192.168.57.10
root@pam:~# ssh otusadm@192.168.57.10

6. Проверим, что пользователи root, vagrant и otusadm есть в группе admin:
root@pam:~# cat /etc/group | grep admin
printadmin:x:994:
admin:x:1003:otusadm,root,vagrant

7. Создаем правило, по которому все пользователи, кроме тех, кто группе admin, не смогут подключаться в выходные дни.
Выбираем метод PAM аутентификации и создадим скрипт сохранив его в /usr/local/bin/login.sh:

#!/bin/bash
#Первое условие: если день недели суббота или воскресенье
if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
 #Второе условие: входит ли пользователь в группу admin
 if getent group admin | grep -qw "$PAM_USER"; then
        #Если пользователь входит в группу admin, то он может подключиться
        exit 0
      else
        #Иначе ошибка (не сможет подключиться)
        exit 1
    fi
  #Если день не выходной, то подключиться может любой пользователь
  else
    exit 0
fi

8. Добавим права на исполнение файла и укажем в файле /etc/pam.d/sshd наш скрипт и модуль pam_exec:
root@pam:~# chmod +x /usr/local/bin/login.sh
nano /etc/pam.d/sshd 

#%PAM-1.0
auth       substack     password-auth
auth       include      postlogin
auth required pam_exec.so debug /usr/local/bin/login.sh
account    required     dad
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    optional     pam_motd.so
session    include      password-auth
session    include      postlogin

9. Проверка работы настроек, устанавливаю дату на будний день и пробую подключится к машине от пользователя otus, все получается.
Затем меняю на выходной день, и убеждаюсь, что пользователь otus не может подключиться в входной день к ВМ по ssh 




   
