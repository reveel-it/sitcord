# Sitcord VERSION TWO 🎸

You need these environment variables, don't care how you get 'em:

- DISCORD_DEBUG_PORT
- DISCORD_SERVER_NAME

This one is optional and defaults to "General":

- DISCORD_CHANNEL_NAME

## Enabling Discord Debugging

You can use any available port for Discord's debug listener, but whichever one you choose, be sure to set it as `DISCORD_DEBUG_PORT` in your environment.

### macOS

If you installed Discord regularly, you should be able to launch Discord from your terminal and pass in arguments like this:

```
/Applications/Discord.app/Contents/MacOS/Discord --remote-debugging-port=123123
```

If you use the Discord PTB, the path is only slightly different:

```
/Applications/Discord\ PTB.app/Contents/MacOS/Discord\ PTB --remote-debugging-port=123123
```

Now, it isn't super convenient to launch Discord from terminal every time, especially not if you need to leave the terminal running. So, I recommend creating an Automator Application and giving it one action, Run Shell Script, with a line like this:

```
/Applications/Discord.app/Contents/MacOS/Discord --remote-debugging-port=123123 > /tmp/discord.log 2> /tmp/discord.err &
```

That will route Discord's logs and errors to files in your `/tmp` directory, which can be convenient, and it'll background the process so your Automator script doesn't have to leave a little spinny gear in your menu bar.

### Windows/Linux

Sorry, I haven't gotten around to testing this method on other OSes yet, but since the Discord client is an Electron app pretty much everywhere, the process should be basically the same:

1. Locate the Discord binary on your computer
1. Figure out how to pass it command line arguments
1. Give it the `--remote-debugging-port` argument with a port of your choice
