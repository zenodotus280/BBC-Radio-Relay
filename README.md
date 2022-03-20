# BBC-Radio-Relay
Time-shifted BBC Radio for North American listeners.

## Welcome!
 
This is a continuation of the project started (but no longer maintained) by [Stephen Marcok](https://github.com/marcokstephen/BBCRadioDelay). His project offered me the opportunity to dig deeper into scripting, maintaining web servers, version control systems, and much more. When he shut down his server and domain in 2020 I immediately set out to emulate it and run it for myself which I have done for two years. Last year the BBC switched their CDN and with it came a change in how the streams were named. Marco's code no longer works and my fork and pull request have sat idle since. I am working on a small rewrite with the intention of making deployment of the scripts and code easier for others. I will start with a basic Bash script before moving on to Docker and LXC containers. Eventually a nice front-end with tabbed time zones and HTML5 audio players would be nice along with Android and iOS instructions for popular radio apps. I have been working with the scripts off and on for several years and expect to keep doing so: I currently run a dual-instance setup that has boosted uptime from 90-95% to >99.999 using basic DNS hand-overs. A public facing domain name is in the works.

If you have suggestions or have issues, please use the issues or discussion area. There are many GitHub features that I'm still learning how to use so this repo, like Marco's code, continues to be a place of experimentation and weekend tinkering.
