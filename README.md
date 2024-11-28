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
- In a browser, browse to your Plex library. !! Make sure it is not the same computer as your Plex server (Otherwise it will create a link to localhost which Mister Plex won't understand) !!
- Pick a video file (ideally sd in 4:3 format) and click on Get Info -> [View XML](https://support.plex.tv/articles/201998867-investigate-media-information-and-formats/)
- Launch mister plex with `/media/fat/Scripts/mister_plex.sh`
- Copy the url of the xml into mister plex script

## Notes
- For CRT you might have to adjust the CRT settings in the script at the top if you get out of sync
- mplayer is not compiled with SSL. On your Plex server, make sure Settings -> Network -> Secure connections are set to preferred.
- Currently you'll get best results with CRT in 320x240 mode
- For HDMI mode, use `mister_plex_hdmi.sh`
  
## How it works
- The script launches menu core, then switches to terminal and uses mplayer with framebuffer support (thanks to wizzos compiled version) to play the videos. The script automatically tells plex it wants the videos to be transcoded to 320x240 for CRT output so the Mister can play it back.
- Anything bigger resolution wise might have performance issues due to the conversion from yuv color space to rgba. 480p works fine when the arm processor gets overclocked but might stutter every now and then 
