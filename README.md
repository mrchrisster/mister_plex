# MiSTer Plex
![Get Info](https://github.com/mrchrisster/mister_plex/blob/main/media/view%20xml.png)


## What is it?
**MiSTer Plex can play video files from your Plex library.**  
Easy way to play videos on your MiSTer through Plex. All you need is SSH access

## Installation
  
- Copy mister_plex.sh to `/media/fat/Scripts`.
- Make sure you have [ssh](https://boogermann.github.io/Bible_MiSTer/getting-started/network/network-access/) access to your MiSTer.
- Make sure you have Super Attract Mode installed since we're using SAM's video function
- Update Super Attract to latest version with `/media/fat/Scripts/MiSTer_SAM_on.sh update`
- In a browser, browse to your Plex library, pick a video file (ideally sd in 4:3 format) and click on Get Info -> [View XML](https://support.plex.tv/articles/201998867-investigate-media-information-and-formats/)
- Launch mister plex with `/media/fat/Scripts/mister_plex.sh`
- Copy the url of the xml into mister plex script

## Notes
- For CRT you might have to adjust the CRT settings in the script at the top if you get out of sync
- The script launches menu core, thrn switches to terminal and uses mplayer with framebuffer support (thanks to wizzos compiled version) to play the videos. The script automatically tells plex it wants the videos to be transcoded to 320x240 so the Mister can play it back. anything at 480p might experience performance issues due to the MiSTers slow arm processor
- mplayer is not compiled with SSL. On your Plex server, make sure Settings -> Network -> Secure connections are set to preferred.
- Currently you'll get best results with CRT in 320x240 mode
- For HDMI mode, use `mister_plex_hdmi.sh`
  
