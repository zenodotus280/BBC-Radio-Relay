# BBC-Radio-Relay

Time-shifted BBC Radio for North American listeners.

## Welcome

This is a continuation of the project started (but no longer maintained) by [Stephen Marcok](https://github.com/marcokstephen/BBCRadioDelay). The core function is to receive audio directly from the BBC, store it, and then stream it back out after a configurable series of intervals: 4-8 hours as needed so that the audio gives the impression of being broadcast live. In this way you can get a BBC morning music show at 7am and not at midnight in Mountain Time. Instructions are offered at the bottom of this readme.

Stephen's project offered me the opportunity to dig deeper into scripting, maintaining web servers, version control systems, and much more. When he shut down his server and domain in 2020 I immediately set out to emulate it and run it for myself which I have done for three years. In 2021 the BBC switched their CDN and with it came a change in how the streams were named. Stephen's code no longer works and my fork and pull request have sat idle since. V1.0 in this repo represents the last working fork on the original repo. I have since added a new WebUI and have an automated installer.

If you have suggestions or have issues, please use the issues or discussion area. There are many GitHub features that I'm still learning how to use so this repo, like Stephen's code, continues to be a place of experimentation and weekend tinkering.

---

## Hardware Requirements

For all six stations across 5 time zones you will need about 1 core (more for cloud VMs), 512 MB of RAM, and 15-25 GB of disk space. Debian 12 is supported but it will run on most apt-based distros with some tweaks to the install script. I recommend running it in a VM or an LXC - creating a Docker build file is something I would like to do eventually.

## Install

If you have a VM or LXC container (or an interactive Docker container) you can simply 'wget' the install script:

`wget -O /root/BBC_RELAY_installer.sh https://raw.githubusercontent.com/zenodotus280/BBC-Radio-Relay/main/installer.sh && less /root/BBC_RELAY_installer.sh`

Do not pipe-to-bash blindly because this script will mess with your system. Run it in a VM/LXC once downloaded: `bash /root/BBC_RELAY_installer.sh`

This is a minimally interactive install script that will start:
- Icecast2 on port 8000 to make the audio streams available
- Nginx on port 80 for the HTML front-end
- Nginx on port 8080 as a reverse proxy to access port 8000

*Select "no" when asked to configure Icecast2.*

*Please read the script*. It expects to operate in an isolated environment and by default creates cronjobs that will even reboot the server every week - you've been warned!

## Configuration

At the moment you will need to explore the code yourself to make any adjustments if you want to reduce the resource usage. Reducing the number of time zones will have the most noticeable impact along with the test stream that starts after 30 seconds (disabled automatically after post-install testing). If you are using a reverse proxy to access this then you will need to edit `_station.j2` and modify one of the sources to use the correct port for the backend:
`var firstSource = location.origin + ":8080/{{ station.stn_name }}/{{ station.tz_offset }}";` assumes port 8080 but Cloudflare, for example, will not allow HTTPS traffic on that port so I have used port 8443 instead: `var secondSource = "https://bbcradiorelay.net:8443/{{ station.stn_name }}/{{ station.tz_offset }}";`. Once you modify the template with your port you would need to re-run the `generate.py` script to rebuild the individual stations (or just search-and-replace the existing ones instead of editing the `_station.j2`).

## First Run

After going to the IP address of the host you should see the Web Radio Player. It is HTML5 with some Javascript and CSS for control and styling. Initially you will see a warning message for a station that says it is using the second (or third) source. This is bbcradiorelay.net by default. It will take 8 hours to fully populate all the audio so while you wait for your own server to build up the backlog it will allow you to use the alternative backends that I host. Once the streams are up it will select the local audio first. This ensures a better first impression of how everything works and also gives the option for a naive high-availabilty setup.

## Reverse Proxy and High Availability

Currently being tested with Nginx as a local HTTP reverse proxy (to bridge the web player and backend radio player) and HAProxy as a global reverse proxy with HTTPS termination.