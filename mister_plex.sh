#!/bin/bash

if [[ -f "/media/fat/Scripts/MiSTer_SAM_on.sh" ]]; then
	source /media/fat/Scripts/MiSTer_SAM_on.sh --sourceonly
	if [ "$(ps aux | grep -ice "[M]iSTer_SAM_on")" -ne 0 ]; then
		/media/fat/Scripts/MiSTer_SAM_on.sh stop
	fi
else
    echo "Error: MiSTer SAM not installed."
    exit 1
fi

#### VARIABLES ####

# CRT DEFAULTS
samvideo_output="CRT" 
samvideo_source="youtube" #leave as is, needed for crtmode320
samvideo_crtmode320="video_mode=320,-16,32,32,240,1,3,13,5670" #change if your display isn't syncing
#samvideo_crtmode320="video_mode=320,16,20,64,240,1,3,15,6800" #alt
VIDEO_RES="320x240" # Plex transcoding resolution.

# HDMI DEFAULTS
#samvideo_output="HDMI"
#sv_aspectfix_vmode="yes"
#VIDEO_RES="640x480" # Plex transcoding resolution. 


volume="1" #try between 1-20



if [ ! -f "${mrsampath}"/mplayer ]; then
	if [ -f "${mrsampath}"/mplayer.zip ]; then
		unzip -ojq "${mrsampath}"/mplayer.zip -d "${mrsampath}"
	else
		get_samvideo
	fi
fi


# Prompt user for Plex URL
echo "Please paste the full Plex URL (from 'Get XML' option):"
read -r PLEX_URL

# Validate the URL
if [[ ! "$PLEX_URL" =~ ^https?:// ]]; then
    echo "Error: Invalid URL. Please provide a valid Plex URL."
    exit 1
fi



# Function to extract value from URL using `sed`
extract_value() {
    echo "$1" | sed -n "s/.*[?&]$2=\([^&]*\).*/\1/p"
}

# Extract metadata ID and token using `sed`
METADATA_ID=$(echo "$PLEX_URL" | sed -n 's#.*/metadata/\([0-9]\+\).*#\1#p')
URL_TOKEN=$(extract_value "$PLEX_URL" "X-Plex-Token")

# Verify metadata ID and token
if [[ -z "$METADATA_ID" ]]; then
    echo "Error: Unable to extract metadata ID from the URL."
    exit 1
fi

if [[ -z "$URL_TOKEN" ]]; then
    echo "Error: Unable to extract Plex token from the URL."
    exit 1
fi

echo "Updating video_mode in MiSTer.ini..."

misterini_mod
echo "MiSTer.ini updated successfully with video_mode: $VIDEO_MODE"

# Generate MPlayer command
TRANSCODE_URL="http://$(echo "$PLEX_URL" | cut -d'/' -f3)/video/:/transcode/universal/start.m3u8?X-Plex-Platform=Chrome&copyts=1&mediaIndex=0&offset=0&path=%2Flibrary%2Fmetadata%2F$METADATA_ID&videoResolution=$VIDEO_RES&maxVideoBitrate=1000&X-Plex-Token=$URL_TOKEN&directStream=0&directPlay=0"

echo "Generated Transcode URL:"
echo "$TRANSCODE_URL"
# Hide login prompt
echo -e '\033[2J' > /dev/tty1
# Hide blinking cursor
echo 0 > /sys/class/graphics/fbcon/cursor_blink
echo -e '\033[?17;0;0c' > /dev/tty1 


echo "Preparing mplayer"
echo load_core /media/fat/menu.rbf > /dev/MiSTer_cmd
sleep "${samvideo_displaywait}"
${mrsampath}/mbc raw_seq :43
echo "Ctrl +c to cancel playback"

nice -n -20 env LD_LIBRARY_PATH=${mrsampath} ${mrsampath}/mplayer -noaspect -sws 0 -cache 8192 -vf scale,format=bgra -af volume=${volume}:1  "$TRANSCODE_URL"
