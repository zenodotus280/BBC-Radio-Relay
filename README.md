# BBC-Radio-Relay

Time-shifted BBC Radio for North American listeners.

## Welcome

This is a continuation of the project started (but no longer maintained) by [Stephen Marcok](https://github.com/marcokstephen/BBCRadioDelay). The core function is to receive audio directly from the BBC, store it, and then stream it back out after a configurable series of intervals: 4-8 hours as needed so that the audio gives the impression of being broadcast live. In this way you can get a BBC mornign music show at 7am and not at midnight in Mountain Time. Instructions are offered at the bottom of this readme.

Stephen's project offered me the opportunity to dig deeper into scripting, maintaining web servers, version control systems, and much more. When he shut down his server and domain in 2020 I immediately set out to emulate it and run it for myself which I have done for two years. Last year the BBC switched their CDN and with it came a change in how the streams were named. Stephen's code no longer works and my fork and pull request have sat idle since. I am working on a small rewrite with the intention of making deployment of the scripts and code easier for others. I will start with a basic Bash script before moving on to Docker and LXC containers. Eventually a nice front-end with tabbed time zones and HTML5 audio players would be nice along with Android and iOS instructions for popular radio apps. I have been working with the scripts off and on for several years and expect to keep doing so: I currently run a dual-instance setup that has boosted uptime from 90-95% to >99.999 using basic DNS hand-overs. A public facing domain name is in the works.

If you have suggestions or have issues, please use the issues or discussion area. There are many GitHub features that I'm still learning how to use so this repo, like Stephen's code, continues to be a place of experimentation and weekend tinkering.

---

## Hardware Requirements

For all six stations across 5 time zones you will need about 1 core (more for cloud VMs), 512 MB of RAM, and 15-25 GB of disk space. Tested successfully in Debian-based VMs, LXCs (privileged), and bare metal on X86_64 and armv7 and armv8 architectures.

## Install

If you have a VM or LXC container (or an interactive Docker container) you can simply 'pipe-to-bash' the install script:
`wget https://github.com/zenodotus280/BBC-Radio-Relay/archive/refs/tags/v1.1.0.zip | bash`

This is a minimally interactive install script that will start the Icecast2 back-end on port 8000 and the static front-end using Python on port 80. There are only two choices to make in this version: Select "no" when asked to configure Icecast2 and "yes" at the end of the install script to test that the Python server has the correct permissions to run on a privlileged port (common error with Proxmox LXCs).

*Please read the script*. It expects to operate in an isolated environment and by default creates cronjobs that will even reboot the server every week - you've been warned!

## Configuration

At the moment you will need to explore the code yourself to make any adjustments if you want to reduce the resource usage. Reducing the number of time zones will have the most noticeable impact along with the test stream that starts after 30 seconds.