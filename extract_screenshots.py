"""
Extract screenshots from a video at specified timestamps using ffmpeg.
Names files as screenshot_HH_MM_SS.jpg.
Also copies screenshots to the Obsidian images folder.
"""

import subprocess
import os
import shutil

# Path to ffmpeg
FFMPEG = r"C:\Users\awt\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.0.1-full_build\bin\ffmpeg.exe"

# Input video
VIDEO = r"C:\Users\awt\AppData\Local\Temp\ytdl\video.mp4"

# Output directory for screenshots
OUT_DIR = r"C:\Users\awt\AppData\Local\Temp\ytdl\screenshots"
os.makedirs(OUT_DIR, exist_ok=True)

# Obsidian images folder
OBS_DIR = r"D:\Obsidian\Main\00 - Images"

# Scene change timestamps in seconds (from ffmpeg scene detection)
TIMESTAMPS = [
    51.9,     # 0:51
    299.4,    # 4:59
    338.5,    # 5:38
    343.3,    # 5:43
    346.6,    # 5:46
    348.2,    # 5:48
    350.0,    # 5:50
    352.0,    # 5:52
    477.5,    # 7:57
    766.7,    # 12:46
    794.7,    # 13:14
    801.4,    # 13:21
    827.2,    # 13:47
    973.1,    # 16:13
    1185.9,   # 19:45
    1759.9,   # 29:19
    1859.6,   # 30:59
    2088.2,   # 34:48
    2509.2,   # 41:49
    2978.4,   # 49:38
    3042.1,   # 50:42
    3058.3,   # 50:58
    3061.5,   # 51:01
]

results = []

for ts in TIMESTAMPS:
    # Convert float seconds to H, M, S
    total_sec = int(ts)
    h = total_sec // 3600
    m = (total_sec % 3600) // 60
    s = total_sec % 60
    fname = f"tuesday_talks_{h:02d}_{m:02d}_{s:02d}.jpg"
    out_path = os.path.join(OUT_DIR, fname)

    cmd = [
        FFMPEG, "-y",
        "-ss", str(ts),
        "-i", VIDEO,
        "-frames:v", "1",
        "-q:v", "2",
        out_path
    ]
    result = subprocess.run(cmd, capture_output=True)
    if result.returncode == 0 and os.path.exists(out_path):
        size = os.path.getsize(out_path)
        # Copy to Obsidian images folder
        obs_path = os.path.join(OBS_DIR, fname)
        shutil.copy2(out_path, obs_path)
        results.append((ts, h, m, s, fname, size))
        print(f"  OK  [{h:02d}:{m:02d}:{s:02d}] {fname} ({size:,} bytes)")
    else:
        print(f"  ERR [{h:02d}:{m:02d}:{s:02d}] -- {result.stderr.decode()[-100:]}")

print(f"\nExtracted {len(results)} screenshots")
print("\nObsidian embed codes:")
for ts, h, m, s, fname, size in results:
    print(f"  ![[{fname}]]  @ {h:02d}:{m:02d}:{s:02d}")
