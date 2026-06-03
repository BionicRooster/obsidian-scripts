from youtube_transcript_api import YouTubeTranscriptApi

video_id = 'aU_VuYBL2X8'
api = YouTubeTranscriptApi()

# List transcripts first
transcript_list = api.list(video_id)
for t in transcript_list:
    print(f"Lang: {t.language_code}, Generated: {t.is_generated}, Translatable: {t.is_translatable}")

# Fetch English
fetched = api.fetch(video_id)
for entry in fetched:
    start = entry.start
    mins = int(start // 60)
    secs = int(start % 60)
    print(f"{mins}:{secs:02d}\t{entry.text}")
