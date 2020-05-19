#!/bin/bash

# Turn on strict mode (quit on errors)
set -euo pipefail

function hide_output {
	# Hides the output of a command unless the command fails and returns non-zero

	# Get a temporary file.
	OUTPUT=$(tempfile)

	# Execute command, redirecting stderr/stdout to the temporary file. Since we
	# check the return code ourselves, disable 'set -e' temporarily.
	set +e
	$@ &> $OUTPUT
	E=$?
	set -e

	# If the command failed, show the output that was captured in the temporary file.
	if [ $E != 0 ]; then
		# Something failed.
		echo
		echo ER IS HET VOLGENDE MISGEGAAN: $@
		echo -----------------------------------------
		cat $OUTPUT
		echo -----------------------------------------
		exit $E
	fi

	# Remove temporary file.
	rm -f $OUTPUT
}

function apt_get_quiet {
	# Run apt-get non-interactively and in quiet mode
	DEBIAN_FRONTEND=noninteractive hide_output apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@"
}

function apt_install {
	# Install a bunch of packages. We used to report which packages were already
	# installed and which needed installing, before just running an 'apt-get
	# install' for all of the packages.  Calling `dpkg` on each package is slow,
	# and doesn't affect what we actually do, except in the messages, so let's
	# not do that anymore.
	PACKAGES=$@
	apt_get_quiet install $PACKAGES
}

function get_publicip_from_web_service {
	# Determine the machine's public IP address
	curl -4 --fail --silent --max-time 5 ifconfig.co 2>/dev/null || /bin/true
}

# Are we running as root?
if [[ $EUID -ne 0 ]]; then
	echo "Dit script moet als met root-privileges gestart worden. Roep het als volgt opnieuw aan:"
	echo
	echo "sudo $0"
	echo
	exit 1
fi

# Check that we are running on Ubuntu 18.04 LTS (or 18.04.xx).
if [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/18\.04\.[0-9]/18.04/' `" != "Ubuntu 18.04 LTS" ]; then
	echo "Deze Jamulus server installatie is specifiek bedoeld voor Ubuntu 18.04. Op dit systeem draait echter:"
	echo
	lsb_release -d | sed 's/.*:\s*//'
	echo
	exit 1
fi

# Check that we have enough memory.
TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{print $2}')
if [ $TOTAL_PHYSICAL_MEM -lt 750000 ]; then
	TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{printf "%.1f", $2/1000**2}')
	echo "Jamulus server heeft tenminste 1 GB geheugen (RAM) nodig om goed te functioneren."
	echo "Deze machine heeft $TOTAL_PHYSICAL_MEM GB geheugen."
	exit
fi

# Set everything to UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8
export NCURSES_NO_UTF8_ACS=1

# Update system packages
echo $(date +'%H:%M:%S') - Updaten van de aanwezige systeemsoftware ...
hide_output apt-get update
apt_get_quiet upgrade
apt_get_quiet autoremove

echo -n $(date +'%H:%M:%S') - Installeren van software benodigd voor Jamulus server ...
for PACKAGE in build-essential qt5-qmake qtdeclarative5-dev libjack-jackd2-dev qt5-default netfilter-persistent git coreutils unattended-upgrades; do
	echo -n '.'
	apt_install ${PACKAGE}
done
echo

# Zorg dat de nieuwste systeemsoftware dagelijks automatisch ge-update wordt
cat > /etc/apt/apt.conf.d/02periodic <<EOF;
APT::Periodic::MaxAge "7";
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Verbose "0";
EOF

# Haal de broncode van Jamulus op (wordt in directory ‘jamulus’ gezet)
cd ${HOME}
echo $(date +'%H:%M:%S') - Broncode van Jamulus downloaden ...
if [ -d "jamulus" ]; then
    rm -fr jamulus
fi
hide_output git clone https://github.com/corrados/jamulus.git
curl -s https://raw.githubusercontent.com/jerogee/jamulus-server-deploy-ubuntu/master/setup/jamulus.service > jamulus.service

# Ga naar de directory met de broncode
cd ${HOME}/jamulus

# Compileer de software
echo $(date +'%H:%M:%S') - Jamulus compileren [dit duurt ongeveer 2 minuten] ...
hide_output qmake "CONFIG+=nosound" Jamulus.pro
hide_output make clean
hide_output make

# Kopieer het compileerde programma naar een centrale locatie, en verzeker dat het kan worden uitgevoerd
echo $(date +'%H:%M:%S') - Jamulus installeren ...
sudo cp Jamulus /usr/local/bin
sudo chmod a+x /usr/local/bin/Jamulus

# Maak het een service
echo $(date +'%H:%M:%S') - Jamulus als service instellen die automatisch (her)start ...
hide_output sudo adduser --system --no-create-home jamulus
cd ${HOME}
sudo cp jamulus.service /etc/systemd/system/jamulus.service
hide_output sudo chmod 644 /etc/systemd/system/jamulus.service
hide_output sudo systemctl start jamulus
hide_output sudo systemctl enable jamulus

# Open poort 22124 voor Jamulus
echo $(date +'%H:%M:%S') - Poort 22124 openzetten zodat Jamulus server bereikbaar wordt ...
sudo iptables -A INPUT -p udp -m udp --dport 22124 -j ACCEPT
sudo iptables -A OUTPUT -p udp -m udp --dport 22124 -j ACCEPT
sudo netfilter-persistent save

echo $(date +'%H:%M:%S') - Installatiebestanden opruimen
rm -fr ${HOME}/jamulus
rm -f ${HOME}/jamulus.service

# Gereed.
echo
echo "-----------------------------------------------"
echo
echo Je Jamulus server is nu gebruiksklaar !
echo
echo Op het volgende IP-adres kan deze server bereikt worden:
get_publicip_from_web_service
echo
