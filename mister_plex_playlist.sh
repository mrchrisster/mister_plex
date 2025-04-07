#!/bin/bash

# Source MiSTer_SAM_on.sh for samvideo functions
if [[ -f "/media/fat/Scripts/MiSTer_SAM_on.sh" ]]; then
    source /media/fat/Scripts/MiSTer_SAM_on.sh --source-only
    if [ "$(ps aux | grep -ice "[M]iSTer_SAM_on")" -ne 0 ]; then
        /media/fat/Scripts/MiSTer_SAM_on.sh stop
    fi
else
    echo "Error: MiSTer SAM not installed."
    exit 1
fi

#### VARIABLES ####
sv_inimod="yes"    # Update MiSTer.ini with CRT values. Set to no to leave MiSTer.ini untouched.
samvideo_output="CRT"
samvideo_crtmode320="video_mode=320,27,20,53,240,1,3,15,6500"
VIDEO_RES="320x240"
# Set permanent Base IP and URL Token from URL "http://BASE_IP/playlists/all/?X-Plex-Token=URL_Token"
BASE_IP=""
URL_TOKEN=""
# Set permanent connection type. Uncomment and set "l" for local or "r" for remote.
# For local servers, BASE_IP will be saved permanently.
# CONNECTION_CHOICE=""

# LEAVE AS IS
TEMP_FILE="/tmp/playlist.xml"
samvideo_source="youtube" 

# ----- First run: Token entry and connection type -----
if [[ -z "$URL_TOKEN" ]]; then
    echo "Please paste the full Plex XML URL:"
    read -r PLEX_URL

    # Validate the URL
    if [[ ! "$PLEX_URL" =~ ^https?:// ]]; then
        echo "Error: Invalid URL. Please provide a valid Plex URL."
        exit 1
    fi

    # Extract temporary BASE_IP and URL_TOKEN from the provided URL.
    TEMP_BASE_IP=$(echo "$PLEX_URL" | sed -n 's#https\?://\([^/]*\)/.*#\1#p')
    TEMP_TOKEN=$(echo "$PLEX_URL" | sed -n 's/.*[?&]X-Plex-Token=\([^&]*\).*/\1/p')

    if [[ -z "$TEMP_BASE_IP" || -z "$TEMP_TOKEN" ]]; then
        echo "Error: Could not extract base IP or token."
        exit 1
    fi

    # Ask if the user wants to save the TOKEN permanently.
    echo "Would you like to save the extracted TOKEN permanently to this script? (y/n)"
    read -r save_token_choice

    if [[ "$save_token_choice" =~ ^[Yy] ]]; then
        script_file="$0"
        sed -i 's|^URL_TOKEN=".*"|URL_TOKEN="'"$TEMP_TOKEN"'"|' "$script_file"
        echo "Saved TOKEN to the script."
    fi
    # Set token for current run.
    URL_TOKEN="$TEMP_TOKEN"

    # Ask if the Plex server is local or remote.
    echo "Is your Plex server local or remote? (l/r):"
    read -r connection_choice

    if [[ "$connection_choice" =~ ^[Ll] ]]; then
        # Local: save connection type and BASE_IP permanently.
        script_file="$0"
        sed -i 's|^# CONNECTION_CHOICE=".*"|CONNECTION_CHOICE="l"|' "$script_file"
        sed -i 's|^BASE_IP=".*"|BASE_IP="'"$TEMP_BASE_IP"'"|' "$script_file"
        echo "Saved connection type as local and saved BASE_IP to the script."
        CONNECTION_CHOICE="l"
        BASE_IP="$TEMP_BASE_IP"
    elif [[ "$connection_choice" =~ ^[Rr] ]]; then
        # Remote: save connection type only. BASE_IP will be determined each run.
        script_file="$0"
        sed -i 's|^# CONNECTION_CHOICE=".*"|CONNECTION_CHOICE="r"|' "$script_file"
        echo "Saved connection type as remote. BASE_IP will be determined each run."
        CONNECTION_CHOICE="r"
    else
        echo "Invalid selection. Exiting."
        exit 1
    fi
fi

# ----- Subsequent runs or remote mode: Determine BASE_IP if needed -----
# If a token is saved and the connection type is remote, fetch BASE_IP from Plex.
if [[ -n "$URL_TOKEN" && "${CONNECTION_CHOICE}" == "r" ]]; then
    echo "Using remote connection. Querying Plex API for current BASE_IP..."
    BASE_URI=$(curl -k -L -H "X-Plex-Token: $URL_TOKEN" "https://plex.tv/api/resources?includeHttps=1&includeRelay=1" | \
               xmllint --xpath 'string(//Connection[@local="0" and not(@relay)]/@uri)' -)
    BASE_IP=$(echo "$BASE_URI" | sed -e 's#https\?://##' -e 's#/.*##')
    if [[ -z "$BASE_IP" ]]; then
        echo "Error: Could not extract BASE_IP from the Plex API response."
        exit 1
    fi
fi

# Build playlist query URL
PLAYLISTS_URL="http://${BASE_IP}/playlists/all/?X-Plex-Token=${URL_TOKEN}"

# Fetch and parse playlists
echo "Fetching playlists..."
PLAYLIST_XML=$(curl -s "$PLAYLISTS_URL")

mapfile -t TITLES < <(echo "$PLAYLIST_XML" | xmllint --xpath '//Playlist[@playlistType="video"]/@title' - 2>/dev/null | sed -E 's/ ?title="/\n/g' | sed '/^$/d' | sed 's/"$//')
mapfile -t KEYS < <(echo "$PLAYLIST_XML" | xmllint --xpath '//Playlist[@playlistType="video"]/@ratingKey' - 2>/dev/null | sed -E 's/ ?ratingKey="/\n/g' | sed '/^$/d' | sed 's/"$//')

if [[ ${#TITLES[@]} -eq 0 ]]; then
    echo "No video playlists found!"
    exit 1
fi

# Show selection list
echo
echo "Available Video Playlists:"
for i in "${!TITLES[@]}"; do
    printf "%2d) %s\n" "$((i+1))" "${TITLES[$i]}"
done
echo
read -p "Select a playlist number: " CHOICE

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > ${#TITLES[@]} )); then
    echo "Invalid selection."
    exit 1
fi

# Get selected key
INDEX=$((CHOICE - 1))
SELECTED_KEY="${KEYS[$INDEX]}"
echo "You selected: ${TITLES[$INDEX]}"
echo "Fetching playlist with ratingKey: $SELECTED_KEY"

# Ensure mplayer is available via samvideo
if [ ! -f "${mrsampath}/mplayer" ]; then
    if [ -f "${mrsampath}/mplayer.zip" ]; then
        unzip -ojq "${mrsampath}/mplayer.zip" -d "${mrsampath}"
    else
        get_samvideo
    fi
fi

# Fetch playlist items
PLAYLIST_ITEMS_URL="http://${BASE_IP}/playlists/${SELECTED_KEY}/items?X-Plex-Token=${URL_TOKEN}"
curl -k "$PLAYLIST_ITEMS_URL" -o "$TEMP_FILE"

METADATA_IDS=$(grep -o 'key="/library/metadata/[0-9]\+"' "$TEMP_FILE" | sed 's/key="\/library\/metadata\/\([0-9]\+\)"/\1/')

if [ -z "$METADATA_IDS" ]; then
    echo "Error: No items found in playlist!"
    cat "$TEMP_FILE"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Update video mode
echo "Updating video_mode in MiSTer.ini..."
misterini_mod
echo "MiSTer.ini updated successfully with video_mode: $VIDEO_MODE"

# Play all items
echo "Starting playlist playback..."
while IFS= read -r METADATA_ID; do
    TRANSCODE_URL="http://${BASE_IP}/video/:/transcode/universal/start.m3u8?X-Plex-Platform=Chrome&X-Plex-Client-Identifier=MiSTerPlex&session=mister-plex-session&mediaIndex=0&offset=0&path=/library/metadata/$METADATA_ID&videoResolution=$VIDEO_RES&maxVideoBitrate=1000&X-Plex-Token=$URL_TOKEN&directStream=0&directPlay=0"

    echo "Playing item: $METADATA_ID"
    echo -e '\033[2J' > /dev/tty1
    echo 0 > /sys/class/graphics/fbcon/cursor_blink
    echo -e '\033[?17;0;0c' > /dev/tty1

    echo "Preparing mplayer via samvideo"
    echo load_core /media/fat/menu.rbf > /dev/MiSTer_cmd
    sleep "${samvideo_displaywait}"
    ${mrsampath}/mbc raw_seq :43
    echo "Ctrl +c to cancel playback"

    curl -k -L -H "User-Agent: MPlayer" -H "Accept: */*" "$TRANSCODE_URL" | nice -n -20 env LD_LIBRARY_PATH=${mrsampath} ${mrsampath}/mplayer -fs -af volnorm -

    sleep 2
done <<< "$METADATA_IDS"

echo "Playlist complete!"
rm -f "$TEMP_FILE"
