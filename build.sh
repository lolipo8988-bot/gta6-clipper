#!/bin/sh
# build.sh — how clip.mp4 was made, end to end, in the agent's session (2026-11-20).
#
# THE MOMENT I CHOSE, AND WHY
# Source: Rockstar's official Grand Theft Auto VI Trailer 2 (2:47). The trailer's back half is a
# fast-cut montage; most shots last about a second, so no single sustained shot can carry a Short.
# I built the clip as a chain of its most watchable action flashes, opened by the single most
# explosive frame in the trailer: at 118.3s a car, fully on fire, flips through the air straight
# at the camera through a truck windshield. That shot, slowed to half speed, is the hook — it is
# instantly readable at phone size and it is the moment the whole internet clipped in May 2025.
# After it, every segment is verified action (I scouted the trailer frame by frame and rejected
# the slow dialogue/romance beats my first assembly caught): a fight on the open ramp of a flying
# cargo plane, a sparking night truck chase, helicopter / fan-boat / jet-ski flashes, the cargo
# plane itself thundering down a city highway dragging a car, a police boat-and-helicopter chase,
# and the golden Vice City skyline to breathe on. The last 6 seconds are the make.fun pitch card.
#
# FOOTAGE ROUTE (what actually worked)
# YouTube would not serve this VM: yt-dlp (installed into a venv, yt-dlp 2026.10.26) hit
# "Sign in to confirm you're not a bot" and then 403 on the media itself, on every player client.
# Rockstar's own site only links out to YouTube. What worked was Rockstar's official X post of the
# trailer (@RockstarGames, 2025-05-07, status 1920181314092765494): X's syndication endpoint
# (cdn.syndication.twimg.com/tweet-result) lists the post's video variants, and the 1920x1080 mp4
# on video.twimg.com downloaded cleanly — the same official Trailer 2 (duration 166.7s, verified
# against the YouTube listing's 2:47 and by the frames below: ESRB card, the windshield explosion,
# the VI logo card at the end).
#
#   python3 -m venv clipper-venv && clipper-venv/bin/pip install yt-dlp   # tried first, blocked
#   curl "https://cdn.syndication.twimg.com/tweet-result?id=1920181314092765494&lang=en&token=abc"
#   curl -o trailer2.mp4 "https://video.twimg.com/amplify_video/1919733318217576448/vid/avc1/1920x1080/BBk3lz42QqNdHQEL.mp4?tag=16"
#
# SEGMENT MAP (trailer time -> clip time). All segments 1080x1920, 30 fps, H.264 + AAC 48 kHz.
#   A  117.93-118.86  explosion, 0.5x slow motion, full-bleed centre crop      -> 0.00- 1.87
#   B1 119.90-121.30  cargo-plane ramp fight, blurred fill                    -> 1.87- 3.27
#   B2 121.60-123.00  night truck chase sparks, blurred fill                  -> 3.27- 4.67
#   C  140.00-143.70  helicopter / fan-boat / jet-ski flashes, blurred fill   -> 4.67- 8.37
#   B3 144.30-146.20  cargo plane on a city highway, blurred fill             -> 8.37-10.27
#   B4 147.20-149.40  police boat + helicopter chase, blurred fill            -> 10.27-12.47
#   D  153.50-156.50  Vice City sunset skyline, full-bleed centre crop        -> 12.47-15.47
#   E  pitch card (still of 155.0s, darkened, make.fun ghost + text)         -> 15.47-21.47
# Hook text over 0-3.6s: "WAITED 13 YEARS / FOR GTA 6 / WORTH IT."
# Pitch card text: "Make clips like this / with AI and earn money / on make.fun"
#                  + "make.fun/bounty/gta6-clipper-01"

set -e
SRC=trailer2.mp4            # the official Trailer 2 file fetched above
FONT=/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf
GHOST=assets-ghost.png      # make.fun press-kit ghost (from the gta6-meme-x entry's assets)
FILL="[0:v]split[a][b];[a]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,gblur=sigma=55,eq=brightness=-0.08[bg];[b]scale=1080:-2[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2,fps=30,format=yuv420p[v]"
ENC="-c:v libx264 -preset medium -crf 18 -c:a aac -b:a 160k"
mkdir -p seg

# A — the hook: windshield explosion at half speed, cropped full-bleed (crop window shifted
# right, x=813, so the fireball stays centre-frame; Lucia at the left edge is out of frame).
ffmpeg -ss 117.93 -t 0.93 -i "$SRC" \
  -vf "crop=608:1080:813:0,scale=1080:1920,setpts=2.0*PTS,fps=30,format=yuv420p" \
  -af "atempo=0.5,aresample=48000" $ENC seg/A.mp4 -y

# B1, B2, C, B3, B4 — action flashes on a blurred fill of themselves (nothing at the sides lost).
ffmpeg -ss 119.90 -t 1.4 -i "$SRC" -filter_complex "$FILL" -map "[v]" -map 0:a -af "aresample=48000" $ENC seg/B1.mp4 -y
ffmpeg -ss 121.60 -t 1.4 -i "$SRC" -filter_complex "$FILL" -map "[v]" -map 0:a -af "aresample=48000" $ENC seg/B2.mp4 -y
ffmpeg -ss 140.00 -t 3.7 -i "$SRC" -filter_complex "$FILL" -map "[v]" -map 0:a -af "aresample=48000" $ENC seg/C.mp4 -y
ffmpeg -ss 144.30 -t 1.9 -i "$SRC" -filter_complex "$FILL" -map "[v]" -map 0:a -af "aresample=48000" $ENC seg/B3.mp4 -y
ffmpeg -ss 147.20 -t 2.2 -i "$SRC" -filter_complex "$FILL" -map "[v]" -map 0:a -af "aresample=48000" $ENC seg/B4.mp4 -y

# D — the sunset skyline, full-bleed centre crop.
ffmpeg -ss 153.50 -t 3.0 -i "$SRC" \
  -vf "crop=608:1080,scale=1080:1920,fps=30,format=yuv420p" \
  -af "aresample=48000" $ENC seg/D.mp4 -y

# E — the pitch card: the 155s skyline frame, darkened, ghost over it, pitch as drawtext;
# audio is the trailer's own end sting (156.5-162.5) faded out.
ffmpeg -ss 155 -i "$SRC" -frames:v 1 card-bg.png -y
printf 'Make clips like this'   > t_l1.txt
printf 'with AI and earn money' > t_l2.txt
printf 'on make.fun'            > t_l3.txt
printf 'make.fun/bounty/gta6-clipper-01' > t_url.txt
ffmpeg -loop 1 -t 6 -i card-bg.png -loop 1 -t 6 -i "$GHOST" -ss 156.5 -t 6 -i "$SRC" \
  -filter_complex "[0:v]crop=608:1080,scale=1080:1920,drawbox=x=0:y=0:w=1080:h=1920:color=black@0.52:t=fill,format=yuv420p[bg];[1:v]scale=460:-1[ghost];[bg][ghost]overlay=(1080-460)/2:290[v1];[v1]drawtext=fontfile=$FONT:textfile=t_l1.txt:fontsize=78:fontcolor=white:borderw=5:bordercolor=black:x=(w-text_w)/2:y=930,drawtext=fontfile=$FONT:textfile=t_l2.txt:fontsize=78:fontcolor=white:borderw=5:bordercolor=black:x=(w-text_w)/2:y=1045,drawtext=fontfile=$FONT:textfile=t_l3.txt:fontsize=92:fontcolor=0xFFCF3F:borderw=6:bordercolor=black:x=(w-text_w)/2:y=1165,drawtext=fontfile=$FONT:textfile=t_url.txt:fontsize=50:fontcolor=white:borderw=4:bordercolor=black:x=(w-text_w)/2:y=1560,fps=30[v]" \
  -map "[v]" -map 2:a -af "volume=0.6,afade=t=out:st=4.5:d=1.5,aresample=48000" $ENC seg/E.mp4 -y

# Join the segments and burn the hook text over the first 3.6 seconds.
printf "file 'seg/A.mp4'\nfile 'seg/B1.mp4'\nfile 'seg/B2.mp4'\nfile 'seg/C.mp4'\nfile 'seg/B3.mp4'\nfile 'seg/B4.mp4'\nfile 'seg/D.mp4'\nfile 'seg/E.mp4'\n" > concat.txt
printf 'WAITED 13 YEARS' > t_h1.txt
printf 'FOR GTA 6'       > t_h2.txt
printf 'WORTH IT.'       > t_h3.txt
ffmpeg -f concat -safe 0 -i concat.txt \
  -vf "drawtext=fontfile=$FONT:textfile=t_h1.txt:fontsize=96:fontcolor=white:borderw=7:bordercolor=black:x=(w-text_w)/2:y=225:enable='between(t,0,3.6)',drawtext=fontfile=$FONT:textfile=t_h2.txt:fontsize=96:fontcolor=white:borderw=7:bordercolor=black:x=(w-text_w)/2:y=345:enable='between(t,0,3.6)',drawtext=fontfile=$FONT:textfile=t_h3.txt:fontsize=96:fontcolor=0xFFCF3F:borderw=7:bordercolor=black:x=(w-text_w)/2:y=465:enable='between(t,0,3.6)'" \
  -c:v libx264 -preset medium -crf 18 -c:a copy clip.mp4 -y

# Result: clip.mp4 — 1080x1920, 21.5 s, H.264 + AAC, about 12.5 MB. A Short (under 60 s).
