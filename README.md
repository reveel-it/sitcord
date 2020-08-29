# Sitcord VERSION TWO 🎸

## Installation

To install and start using Sitcord, make sure you have Discord, Swift (usually via having XCode installed), and Node.js installed.
Then just run:
```bash
$ make && make install
```

If you use the Discord PTB instead of the regular Discord macOS app, just prefix the command like so:
```bash
$ PTB=true make && make install
```

And that's it! The installer will put a new app, `Sitcord.app`, into your `~/Applications` directory. When you run this app, it'll launch Discord and the Sitcord daemon at the same time, all hooked up and ready to go.

The default Discord channel that Sitcord will use is "General". If you want to change this; specify `CHANNEL_NAME="My Cool Channel"` before `make`, similar to the PTB argument described above.


**Note about permissions:** You're going to have to re-grant permissions to Sitcord separately, even if you previously granted them to Discord; just a heads-up. Also, Sitcord will ask permission to access whatever folder you've cloned this repo into, so that it can put its log files into the `bin` directory there.


This project is the better, more reliable, actually usable successor to https://github.com/jming422/sitcord
