#!/bin/bash
#hora incio y fin
hora_inicio=10:00
hora_fin=11:00


#Eliminar reglas en las tablas filter y nat
iptables -t filter -F
iptables -t nat -F

#Reiniciar los contadores en las tablas filter y nat
iptables -t filter -Z
iptables -t nat -Z

#Borro las tablas no predeterminadas (REGISTROS)
iptables -X

#creamos la cadena REGISTROS para permitir el desarrollo del firewall
iptables -N REGISTROS
#creamos el log
iptables -A REGISTROS -m limit --limit 2/min -j LOG --log-prefix "Conexiones bloqueadas: " --log-level 7
iptables -A REGISTROS -j DROP



#Politca por defecto
#Denegar todo el tráfico en las 3 cadenas de filter ( INPUT, OUTPUT y FORWARD)
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#habilitamos el forward desde la red interna
#iptables -t nat -A POSTROUTING -o wlp2s0 -s 192.168.1.0/24 -j SNAT --to-source 10.10.0.41

#Cadena INPUT
#Esta regla permite las conexiones que ya están establecidas permitiendo el track
iptables -A INPUT -m state --state RELATED,ESTABLISHED  -j ACCEPT
#permite la interfaz loopback
iptables -A INPUT -i lo -m state --state NEW,ESTABLISHED -j ACCEPT
#permite las conexiones entrantas desde el router de casa (tftp)
#iptables -A INPUT -m state --state NEW -s 10.10.0.1 -j ACCEPT
#permite que el servidor dhcp nos pueda asignar una ip
iptables -A INPUT -m state --state NEW -p udp --sport 68 --dport 67 -j ACCEPT
#acepta el ping 
iptables -A INPUT -m state --state NEW -p icmp  -j ACCEPT
#acepta conexiones al puerto ssh
iptables -A INPUT -m state --state NEW -p tcp --dport 22 -j ACCEPT
# acepta el protocolo mdns
iptables -A INPUT -m state --state NEW -p udp --sport 5353 --dport 5353 -j ACCEPT
# habilita el chromecast
iptables -A INPUT -m state --state NEW,ESTABLISHED -p udp --dport 1900 -j ACCEPT
# no tengo ni idea, investigar
iptables -A INPUT -m state --state NEW,ESTABLISHED -p tcp --dport 10000 -j ACCEPT
#descartando el tráfico ruidoso:
#descarta el trafico cuyo destino es la direccion de difusion limitada
iptables -A INPUT -m state --state NEW,ESTABLISHED -d 225.255.255.255 -j DROP
#descarta el trafico multicast
iptables -A INPUT -m state --state NEW,ESTABLISHED -d 224.0.0.0/4 -j DROP
#descarta el trafico cuyo destino es la direccion de broadcast local
iptables -A INPUT -m state --state NEW,ESTABLISHED -d 10.10.0.255 -j DROP
#volcamos en REGISTROS todo lo que se dropee de la cadena INPUT
iptables -A INPUT -j REGISTROS


#Cadena FORWARD
#iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
#iptables -A FORWARD -i enp0s8 -o wlp2s0 -m state --state NEW,ESTABLISHED -p icmp -j ACCEPT
#iptables -A FORWARD -i enp0s8 -o wlp2s0 -m state --state NEW,ESTABLISHED -p udp --dport 123 -j ACCEPT
#habilita el netbios
#iptables -A FORWARD -i enp0s8 -s 192.168.1.0/24 -d 192.168.1.0/24 -m state --state NEW,ESTABLISHED -p udp -m multiport --dports 137,138 -j ACCEPT
#iptables -A FORWARD -i enp0s8 -s 192.168.1.0/24 -d 192.168.1.0/24 -m state --state NEW,ESTABLISHED -p tcp -m multiport --dports 139,445 -j ACCEPT
#habilita el dns
#iptables -A FORWARD -i enp0s8 -o wlp2s0 -m state --state NEW,ESTABLISHED -p udp --dport 53 -j ACCEPT
#iptables -A FORWARD -i enp0s8 -o wlp2s0 -m state --state NEW,ESTABLISHED -p tcp --dport 53 -j ACCEPT
#habilita la navegacion
#iptables -A FORWARD -i enp0s8 -o wlp2s0 -m state --state NEW,ESTABLISHED -p tcp -m multiport --dports 80,443,1024:65534 -j ACCEPT
#iptables -A FORWARD -i enp0s8 -o wlp2s0 -m state --state NEW,ESTABLISHED -p udp -m multiport --dports 80,443,1024:65534 -j ACCEPT
#mandamos todos los paquetes que no encajen a REGISTROS
iptables -A FORWARD -j REGISTROS



#Cadena OUTPUT
#permite mantener conexiones ya creadas y las nuevas pero relacionadas con otra previa autorizada
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
#permite la interfaz loopback
iptables -A OUTPUT -o lo -m state --state NEW,ESTABLISHED -j ACCEPT
#permite hacer cualquier tipo de conexion al router local
#permite hacer ping
iptables -A OUTPUT -m state --state NEW,ESTABLISHED -p icmp  -j ACCEPT
#iptables -A OUTPUT -m state --state NEW,ESTABLISHED -p udp --sport 67 --dport 68 -j ACCEPT
#permite la conexion a ssh
iptables -A OUTPUT -m state --state NEW,ESTABLISHED -p tcp --dport 22 -j ACCEPT
#permite el dns
iptables -A OUTPUT -m state --state NEW,ESTABLISHED -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -m state --state NEW,ESTABLISHED -p tcp --dport 53 -j ACCEPT
#habilitamos los siguientes puertos
# 80	http
# 443	https
# 8009	chromecast
iptables -A OUTPUT -m state --state NEW,ESTABLISHED -p tcp -m multiport --dports 80,443,8009 -j ACCEPT
iptables -A OUTPUT -m state --state NEW,ESTABLISHED -p udp -m multiport --dports 80,443 -j ACCEPT
#ejemplo de control con uso horario, la hora esta en UTC (+2)
#ayuda man iptables-extensions
#iptables -A OUTPUT -m iprange --src-range 10.10.0.40-10.10.0.60 -p icmp -m time --timestart $hora_inicio --timestop $hora_fin --weekdays Mon,Tue,Wed,Thu,Fri,Sat,Sun -j ACCEPT
#permite el ntp
iptables -A OUTPUT -m state --state NEW,ESTABLISHED -p udp --dport 123 -j ACCEPT
iptables -A OUTPUT -m state --state NEW -p udp --sport 51820 --dport 51820 -j ACCEPT
iptables -A OUTPUT -m state --state NEW,ESTABLISHED -p udp --sport 5353 --dport 5353 -j ACCEPT


#permite cualquier conexion al servidor y al router
#iptables -A OUTPUT -d 10.10.0.100 -m state --state NEW -j ACCEPT
#iptables -A OUTPUT -m state --state NEW -d 10.10.0.1 -j ACCEPT
iptables -A OUTPUT -d 10.10.0.0/24 -m state --state NEW -j ACCEPT

#trata el resto de paquetes en registro
iptables -A OUTPUT -j REGISTROS
