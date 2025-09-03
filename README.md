Домашнее задание
Обновление ядра системы

Задание

Запустите ВМ c Ubuntu.
Обновите ядро ОС на новейшую стабильную версию из mainline-репозитория.
Оформите отчет в README-файле в GitHub-репозитории.




uname -r
mkdir kernel
cd kernel
wget https://kernel.ubuntu.com/mainline/v6.17-rc4/amd64/linux-headers-6.17.0-061700rc4-generic_6.17.0-061700rc4.202508312336_amd64.deb
wget https://kernel.ubuntu.com/mainline/v6.17-rc4/amd64/linux-image-unsigned-6.17.0-061700rc4-generic_6.17.0-061700rc4.202508312336_amd64.deb
wget https://kernel.ubuntu.com/mainline/v6.17-rc4/amd64/linux-modules-6.17.0-061700rc4-generic_6.17.0-061700rc4.202508312336_amd64.deb
reboot
