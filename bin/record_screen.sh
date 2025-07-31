#!/usr/bin/env bash

# ================================
# record_screen.sh
# Records the entire screen with ffmpeg
# Saves to ~/screen_cap_DATE.mp4
# ================================

if [ -d "$HOME/Videos" ]; then
    OUTPUT_DIR="$HOME/Videos"
else
    OUTPUT_DIR="$HOME"
fi
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
VIDEO_FILE="$OUTPUT_DIR/screen_cap_$TIMESTAMP.mp4"
GIF_FILE="$OUTPUT_DIR/screen_cap_$TIMESTAMP.gif"

# Screen resolution detection
SCREEN_RES=$(xdpyinfo | grep 'dimensions:' | awk '{print $2}')
DISPLAY_NUM=${DISPLAY:-:0.0}

# Frame rate
FRAMERATE=30

echo "Recording screen at $SCREEN_RES..."
echo "Press Ctrl+C to stop."

# Record the screen
ffmpeg -video_size "$SCREEN_RES" \
       -framerate "$FRAMERATE" \
       -f x11grab \
       -i "$DISPLAY_NUM" \
       -codec:v libx264 -preset ultrafast -crf 18 \
       "$VIDEO_FILE"

echo "Video saved to: $VIDEO_FILE"

# # Optional GIF creation
# read -p "Convert recording to GIF? (y/N): " make_gif
# if [[ "$make_gif" =~ ^[Yy]$ ]]; then
    # echo "Creating high-quality GIF (this may take a moment)..."
#
    # # Palette for better GIF colors
    # ffmpeg -i "$VIDEO_FILE" -vf "fps=10,scale=800:-1:flags=lanczos,palettegen" -y /tmp/palette.png
    # ffmpeg -i "$VIDEO_FILE" -i /tmp/palette.png -filter_complex "fps=10,scale=800:-1:flags=lanczos[x];[x][1:v]paletteuse" -y "$GIF_FILE"
#
    # rm /tmp/palette.png
    # echo "GIF saved to: $GIF_FILE"
# fi
#
# echo "Done."
