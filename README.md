Jamulus Server deployment for Ubuntu
====================================

Jamulus stelt muzikanten in staat om real-time samen te spelen via het internet.
Dit installatie-script maakt van een verse Ubuntu 18.04 LTS machine een volledig werkende [Jamulus server](https://sourceforge.net/projects/llcon/).

Installatie
-----------

Vanaf de command line van de Ubuntu-machine, typ of copy/paste de volgend commando-regel:

```console
curl -s https://raw.githubusercontent.com/jerogee/jamulus-server-deploy-ubuntu/master/setup/deploy_nl.sh | sudo bash
```

Een succesvolle installatie ziet er ongeveer het volgende uit:

```console
root@jam:~$ curl -s https://raw.githubusercontent.com/jerogee/jamulus-server-deploy-ubuntu/master/setup/deploy_nl.sh | sudo bash
22:33:15 - Updaten van de aanwezige systeemsoftware ...
22:33:36 - Installeren van software benodigd voor Jamulus server ............
22:33:46 - Broncode van Jamulus downloaden ...
22:33:49 - Jamulus compileren [dit duurt ongeveer 2 minuten] ...
22:36:32 - Jamulus installeren ...
22:36:32 - Jamulus als service instellen die automatisch herstart ...
22:36:33 - Poort 22124 openzetten zodat Jamulus server bereikbaar wordt ...
run-parts: executing /usr/share/netfilter-persistent/plugins.d/15-ip4tables save
run-parts: executing /usr/share/netfilter-persistent/plugins.d/25-ip6tables save
22:36:33 - Installatiebestanden opruimen

-----------------------------------------------

Je Jamulus server is nu gebruiksklaar !

Op het volgende IP-adres kan deze server bereikt worden:
188.166.36.41
```
