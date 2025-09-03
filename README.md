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


<img width="1089" height="427" alt="Снимок экрана 2025-09-03 233933" src="https://github.com/user-attachments/assets/68efad70-53f8-4a7b-8a1e-e0c17f3b5f87" />
<img width="1086" height="570" alt="Снимок экрана 2025-09-03 234320" src="https://github.com/user-attachments/assets/262c14d3-aff6-409f-ac5e-937d0a2a356b" />
