# BBC-Radio-Relay

Time-shifted BBC Radio for North American listeners.

## Testing Branch Notes
This contains the latest changes and is what I use when trying new features and troubleshooting issues. Consider it "alpha". The main git repo should be considered "beta" and the version releases are stable.

## Welcome

This is a continuation of the project started (but no longer maintained) by [Stephen Marcok](https://github.com/marcokstephen/BBCRadioDelay). The core function is to receive audio directly from the BBC, store it, and then stream it back out after a configurable series of intervals: 4-8 hours as needed so that the audio gives the impression of being broadcast live. In this way you can get a BBC morning music show at 7am and not at midnight in Mountain Time. Instructions are offered at the bottom of this readme.

Stephen's project offered me the opportunity to dig deeper into scripting, maintaining web servers, version control systems, and much more. When he shut down his server and domain in 2020 I immediately set out to emulate it and run it for myself which I have done for three years. In 2021 the BBC switched their CDN and with it came a change in how the streams were named. Stephen's code no longer works and my fork and pull request have sat idle since. V1.0 in this repo represents the last working fork on the original repo. I have completed the first install script and intend to create a more generic web radio relay using this project as a working example. I have been working with the scripts off and on for several years and expect to keep doing so. You can see try [V1.0](https://bbcradiorelay.net/) for yourself - v1.1 with its fancy web player will soon arrive on those servers!

If you have suggestions or have issues, please use the issues or discussion area. There are many GitHub features that I'm still learning how to use so this repo, like Stephen's code, continues to be a place of experimentation and weekend tinkering.

---

## Hardware Requirements

For all six stations across 5 time zones you will need about 1 core (more for cloud VMs), 512 MB of RAM, and 15-25 GB of disk space. Tested successfully in Debian-based VMs, LXCs (privileged), and bare metal on X86_64 and armv7 and armv8 architectures.

## Install

If you have a VM or LXC container (or an interactive Docker container) you can simply 'pipe-to-bash' the install script:
`wget https://raw.githubusercontent.com/zenodotus280/BBC-Radio-Relay/main/installer.sh | bash`

This is a minimally interactive install script that will start:
- Icecast2 on port 8000 to make the audio streams available
- Nginx on port 80 for the HTML front-end
- Nginx on port 8080 as a reverse proxy to access port 8000

*Select "no" when asked to configure Icecast2.*

*Please read the script*. It expects to operate in an isolated environment and by default creates cronjobs that will even reboot the server every week - you've been warned!

## Configuration

At the moment you will need to explore the code yourself to make any adjustments if you want to reduce the resource usage. Reducing the number of time zones will have the most noticeable impact along with the test stream that starts after 30 seconds.
