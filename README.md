# Sitcord VERSION TWO 🎸

## Use at your own risk

Using Sitcord requires that you open a debugging port on your Discord app. This port is normally accessible only from localhost, but this still means that using Sitcord will open up the possibility that any other program on your machine could connect to your Discord and both see and control everything. We see this risk as minimal, but still be sure you understand and are willing to accept this risk before continuing!


## Installation

To install and start using Sitcord, make sure you have Discord, Swift (usually via having XCode installed), and Node.js installed.
Then just run:
```bash
$ SERVER="My Discord Server" make && make install
```

If you use the Discord PTB instead of the regular Discord macOS app, just prefix the command like so:
```bash
$ PTB=true SERVER="My Discord Server" make && make install
```

And that's it! The installer will put a new app, `Sitcord.app`, into your `~/Applications` directory. When you run this app, it'll launch Discord and the Sitcord daemon at the same time, all hooked up and ready to go. **Note:** This was a hastily-written hackathon project, so we didn't have the time to properly package everything into Sitcord.app; so **don't delete this repo directory after installing or Sitcord won't work!**


The default Discord channel that Sitcord will use is "General". If you want to change this; specify `CHANNEL_NAME`:
```bash
$ CHANNEL_NAME="My Cool Channel" SERVER="My Discord Server" make && make install
```


**Note about permissions:** You're going to have to re-grant permissions to Sitcord separately, even if you previously granted them to Discord; just a heads-up. Also, Sitcord will ask permission to access whatever folder you've cloned this repo into, so that it can put its log files into the `bin` directory there.


This project is the better, more reliable, actually usable successor to https://github.com/jming422/sitcord


## Troubleshooting

Depending on your XCode vs XCode Command Line tools configuration, you may need to follow the steps described here: https://stackoverflow.com/a/61725799/
