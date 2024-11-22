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
- mplayer is not compiled with SSL. On your Plex server, make sure Settings -> Network -> Secure connections are set to preferred.
- Currently only tested with CRT in 320x240 mode
- Change settings in mister_plex.sh to enable HDMI mode
- Please let me know if it works for HDMI
  
