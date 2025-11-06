#!/bin/bash

# Bash script for building the Rayan World Finals 2025 contest PC image
# Meant to be run on a minimal install of Xubuntu 24.04 LTS (64-bit)
# Version: 1.6

# ----- TODO manually after script -----
# Disable Swap
# Set Wallpaper

set -xeuo pipefail

if [ -z "$LIVE_BUILD" ]
then
    export USER=rayan
    export HOME=/home/$USER
else
    export USER=root
    export HOME=/etc/skel
fi


# ----- Initilization -----

# Remove snap
apt -y purge snapd
apt-mark hold snapd

# Add missing repositories
add-apt-repository -y ppa:x-psoud/cbreleases
add-apt-repository -y ppa:mozillateam/ppa

# Prioritize Mozilla Team repository for Firefox
cat << EOF > /etc/apt/preferences.d/mozilla-firefox
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF

# Add repository for Visual Studio Code
apt install -y wget gpg apt-transport-https curl
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg
rm -f microsoft.gpg

cat << EOF > /etc/apt/sources.list.d/vscode.sources
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

# Add repository for Jetbrains IDEs
curl -s https://s3.eu-central-1.amazonaws.com/jetbrains-ppa/0xA6E8698A.pub.asc | gpg --dearmor > jetbrains-ppa-archive-keyring.gpg
install -D -o root -g root -m 644 jetbrains-ppa-archive-keyring.gpg /usr/share/keyrings/jetbrains-ppa-archive-keyring.gpg
rm -f jetbrains-ppa-archive-keyring.gpg

cat << EOF > /etc/apt/sources.list.d/jetbrains.sources
Types: deb
URIs: http://jetbrains-ppa.s3-website.eu-central-1.amazonaws.com
Suites: any
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/jetbrains-ppa-archive-keyring.gpg
EOF

# Update packages list
apt -y update

# Upgrade everything if needed
apt -y upgrade


# ----- Install software from Ubuntu repositories -----

# Compilers
apt -y install build-essential gcc-13 g++-13 openjdk-21-jdk openjdk-21-source kotlin

# Editors and IDEs
apt -y install codeblocks codeblocks-contrib emacs geany geany-plugins
apt -y install gedit vim-gtk3 kate code
apt -y install intellij-idea-community pycharm-community clion

# Interpreters
apt -y install pypy3 python3 python-is-python3

# Documentation
apt -y install zeal openjdk-21-doc pypy3-doc python3-doc
mkdir -p $HOME/.local/share/Zeal/Zeal/docsets/
curl -fL http://newyork.kapeli.com/feeds/C++.tgz | tar -xvz -C $HOME/.local/share/Zeal/Zeal/docsets/
curl -fL http://newyork.kapeli.com/feeds/Java.tgz | tar -xvz -C $HOME/.local/share/Zeal/Zeal/docsets/
curl -fL http://newyork.kapeli.com/feeds/Python_3.tgz | tar -xvz -C $HOME/.local/share/Zeal/Zeal/docsets/

# Debuggers
apt -y install ddd gdb valgrind

# Other Software
apt -y install firefox


# ----- Install software not found in Ubuntu repositories -----

# Visual Studio Code - extensions
su $USER -c "mkdir -p $HOME/.vscode/extensions"
su $USER -c "HOME=$HOME code --user-data-dir=$HOME/.config/Code/ --install-extension ms-vscode.cpptools"
su $USER -c "HOME=$HOME code --user-data-dir=$HOME/.config/Code/ --install-extension ms-python.python"
su $USER -c "HOME=$HOME code --user-data-dir=$HOME/.config/Code/ --install-extension redhat.java"
su $USER -c "HOME=$HOME code --user-data-dir=$HOME/.config/Code/ --install-extension vscjava.vscode-java-debug"

# Eclipse 2025-09 and CDT plugins
curl -fL https://eclipse.mirror.rafal.ca/technology/epp/downloads/release/2025-09/R/eclipse-java-2025-09-R-linux-gtk-x86_64.tar.gz | tar -xvz -C /opt/
/opt/eclipse/eclipse -application org.eclipse.equinox.p2.director -noSplash -repository https://download.eclipse.org/releases/2025-09 \
-installIUs \
org.eclipse.cdt.feature.group,\
org.eclipse.cdt.build.crossgcc.feature.group,\
org.eclipse.cdt.launch.remote,\
org.eclipse.cdt.gnu.multicorevisualizer.feature.group,\
org.eclipse.cdt.testsrunner.feature.feature.group,\
org.eclipse.cdt.visualizer.feature.group,\
org.eclipse.cdt.debug.ui.memory.feature.group,\
org.eclipse.cdt.autotools.core,\
org.eclipse.cdt.autotools.feature.group,\
org.eclipse.linuxtools.valgrind.feature.group,\
org.eclipse.linuxtools.profiling.feature.group,\
org.eclipse.remote.core,\
org.eclipse.remote.feature.group
ln -s /opt/eclipse/eclipse /usr/bin/eclipse

# Activate Clion
mkdir -p $HOME/.config/JetBrains/CLion2025.2/
(
    printf '\xFF\xFF'
    echo -en "<certificate-key>\nEVFXPJNEWB-eyJsaWNlbnNlSWQiOiJFVkZYUEpORVdCIiwibGljZW5zZWVOYW1lIjoiSW50ZXJuYXRpb25hbCBDb2xsZWdpYXRlIFByb2dyYW1taW5nIENvbnRlc3QiLCJsaWNlbnNlZVR5cGUiOiJDT01NRVJDSUFMIiwiYXNzaWduZWVOYW1lIjoiIiwiYXNzaWduZWVFbWFpbCI6IiIsImxpY2Vuc2VSZXN0cmljdGlvbiI6IkV2YWx1YXRpb24gcHVycG9zZSBvbmx5IiwiY2hlY2tDb25jdXJyZW50VXNlIjpmYWxzZSwicHJvZHVjdHMiOlt7ImNvZGUiOiJDTCIsInBhaWRVcFRvIjoiMjAyNi0wOC0wOSIsImV4dGVuZGVkIjpmYWxzZX0seyJjb2RlIjoiUFNJIiwicGFpZFVwVG8iOiIyMDI2LTA4LTA5IiwiZXh0ZW5kZWQiOnRydWV9LHsiY29kZSI6IlBSUiIsInBhaWRVcFRvIjoiMjAyNi0wOC0wOSIsImV4dGVuZGVkIjp0cnVlfSx7ImNvZGUiOiJQQ1dNUCIsInBhaWRVcFRvIjoiMjAyNi0wOC0wOSIsImV4dGVuZGVkIjp0cnVlfV0sIm1ldGFkYXRhIjoiMDMyMDI1MDgxNUNTQU4wMDAwMDhYMDFPU0NWIiwiaGFzaCI6IlRSSUFMOjkwNDk3MzA4OCIsImdyYWNlUGVyaW9kRGF5cyI6MywiYXV0b1Byb2xvbmdhdGVkIjpmYWxzZSwiaXNBdXRvUHJvbG9uZ2F0ZWQiOmZhbHNlLCJ0cmlhbCI6dHJ1ZSwiYWlBbGxvd2VkIjp0cnVlfQ==-IAfSHXZQFw/Z743mx6drVL1wOx+zihCBAE+fQYGSmHziG4MBeUG0ZNkcPhSePi+0lcjMCNd3Ad7fzPzA4Dd4hTCxNDAJAD/swepPHdPDwEyp9OBmXQsliGF5aiHH3fZO2L4yXqvV+XnTAcVa0mLV3BoK/sLxa4/aY3W2PaI/HHf/SOe1xXOIdNxL145ajjE/2U38IakiEODSDflAZw644xKIPiY4TwS+qkEVDDM01JY4OdTXoWCku6L/ZdFTLm0ps0UT/cUFyA8wPG0zRPpFwVs+p6OlBlOUYOzl9uNHTR8/wLwXhFKvX5kyE5m5veCGmA9oYlPtFZtfksrdXgDPvg==-MIIETDCCAjSgAwIBAgIBETANBgkqhkiG9w0BAQsFADAYMRYwFAYDVQQDDA1KZXRQcm9maWxlIENBMB4XDTI0MDkyMDEyMTEyN1oXDTI2MDkyMjEyMTEyN1owHzEdMBsGA1UEAwwUcHJvZDJ5LWZyb20tMjAyNDA5MjAwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7SH/XcUoMwkDi8JJPzXWWHWFdOZdrP2Dqkz2W8iUi650cwz2vdPEd0tMzosLAj7ifkFEHUyiuEcL//q9d9Op7ZsV23lpPXX8tFMLFwugoQ9D8jDLT/XP9pp/YukWkKF5jpNbaCvsVQkDdYkArBkYvhH3aN4v9BkEsXahfgLLOPe4IG2FDJNf9R4to9V1vt+m2UVJB0zV4a/sVMKUZLgqKmKKKOKoLrE3OjBlZlb+Q0z2N5dsW0hDEVRFGmBUAbHN/mp44MMMvEIFKfoLIGpgic92P2O6uFh75PI7mcultL6yuR48ajErx8CjjQEGOSnoq/8hD+yVE+6GW2gJa2CPvAgMBAAGjgZkwgZYwCQYDVR0TBAIwADAdBgNVHQ4EFgQUb5NERj05GyNerQ/Mjm9XH8HXtLIwSAYDVR0jBEEwP4AUo562SGdCEjZBvW3gubSgUouX8bOhHKQaMBgxFjAUBgNVBAMMDUpldFByb2ZpbGUgQ0GCCQDSbLGDsoN54TATBgNVHSUEDDAKBggrBgEFBQcDATALBgNVHQ8EBAMCBaAwDQYJKoZIhvcNAQELBQADggIBALq6VfVUjmPI3N/w0RYoPGFYUieCfRO0zVvD1VYHDWsN3F9buVsdudhxEsUb8t7qZPkDKTOB6DB+apgt2ZdKwok8S0pwifwLfjHAhO3b+LUQaz/VmKQW8gTOS5kTVcpM0BY7UPF8cRBqxMsdUfm5ejYk93lBRPBAqntznDY+DNc9aXOldFiACyutB1/AIh7ikUYPbpEIPZirPdAahroVvfp2tr4BHgCrk9z0dVi0tk8AHE5t7Vk4OOaQRJzy3lST4Vv6Mc0+0z8lNa+Sc3SVL8CrRtnTAs7YpD4fpI5AFDtchNrgFalX+BZ9GLu4FDsshVI4neqV5Jd5zwWPnwRuKLxsCO/PB6wiBKzdapQBG+P9z74dQ0junol+tqxd7vUV/MFsR3VwVMTndyapIS+fMoe+ZR5g+y44R8C7fXyVE/geg+JXQKvRwS0C5UpnS5FcGk+61b0e4U7pwO20RlwhEFHLSaP61p2TaVGo/TQtT/fWmrtV+HegAv9P3X3Se+xIVtJzQsk8QrB/w52IB3FKiAKl/KRn1egbMIs4uoNAkqNZ9Ih2P1NpiQnONFmkiAgeynJ+0FPykKdJQbV3Mx44jkaHIif4aFReTsYX1WUBNu/QerZRjn4FVSHRaZPSR5Oi82Wz0Nj7IY9ocTpLnXFrqkb/Kt3S6B9s2Kol3Lr1ElYA" \
    | iconv -f UTF-8 -t UCS2 -
) > $HOME/.config/JetBrains/CLion2025.2/clion.key


# ----- Create desktop entries -----

cat << EOF > /usr/share/applications/eclipse.desktop
[Desktop Entry]
Type=Application
Name=Eclipse
Comment=Eclipse Integrated Development Environment
Icon=/opt/eclipse/icon.xpm
Exec=eclipse
Terminal=false
Categories=Development;IDE;Java;
EOF


# ----- Copy wallpaper -----
cp files/wallpaper.png /opt/wallpaper.png


# ----- Cleanup -----
apt -y autoremove
apt -y clean
rm -rf /tmp/*
