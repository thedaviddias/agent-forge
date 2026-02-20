---
name: youtube-summarizer
description: Automatically fetch YouTube transcripts, generate structured summaries, and send full transcripts to messaging platforms. Use when a request includes YouTube URLs and needs metadata, key insights, or downloadable transcripts.
version: 1.0.0
tags: [youtube, transcription, summarization, video]
---

# YouTube Summarizer Skill

Automatically fetch transcripts from YouTube videos, generate structured summaries, and deliver full transcripts to messaging platforms.

## When to Use

Activate this skill when:
- User shares a YouTube URL (youtube.com/watch, youtu.be, youtube.com/shorts)
- User asks to summarize or transcribe a YouTube video
- User requests information about a YouTube video's content

## Quick Method: Use `summarize` CLI

The `summarize` CLI already handles YouTube videos:

```bash
summarize "https://www.youtube.com/watch?v=VIDEO_ID" --youtube auto
```

This is the **preferred method** for YouTube summarization.

### With model selection
```bash
summarize "https://youtu.be/VIDEO_ID" --model google/gemini-3-flash-preview --youtube auto
```

### Length options
```bash
summarize "URL" --youtube auto --length short   # Brief summary
summarize "URL" --youtube auto --length long    # Detailed summary
summarize "URL" --youtube auto --length xl      # Very detailed
```

## Alternative: MCP YouTube Transcript Server

For more control, use the MCP server directly:

### Setup (if not installed)
```bash
cd /root/clawd
git clone https://github.com/kimtaeyoon83/mcp-server-youtube-transcript.git
cd mcp-server-youtube-transcript
npm install && npm run build
```

### Fetch Transcript
```bash
cd /root/clawd/mcp-server-youtube-transcript && node --input-type=module -e "
import { getSubtitles } from './dist/youtube-fetcher.js';
const result = await getSubtitles({ videoID: 'VIDEO_ID', lang: 'en' });
console.log(JSON.stringify(result, null, 2));
" > /tmp/yt-transcript.json
```

## URL Patterns

Extract video ID from these patterns:
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://www.youtube.com/shorts/VIDEO_ID`
- Direct video ID: `VIDEO_ID` (11 characters)

## Summary Template

When generating summaries manually, use this format:

```markdown
📹 **Video:** [title]
👤 **Channel:** [author] | 👁️ **Views:** [views] | 📅 **Published:** [date]

**🎯 Main Thesis:**
[1-2 sentence core argument/message]

**💡 Key Insights:**
- [insight 1]
- [insight 2]
- [insight 3]
- [insight 4]
- [insight 5]

**📝 Notable Points:**
- [additional point 1]
- [additional point 2]

**🔑 Takeaway:**
[Practical application or conclusion]
```

## Quality Guidelines

- **Be concise:** Summary should be scannable in 30 seconds
- **Be accurate:** Don't add information not in the transcript
- **Be structured:** Use consistent formatting
- **Adjust for length:**
  - Short videos (<5 min): Brief summary
  - Long videos (>30 min): More detailed breakdown

## Error Handling

**If transcript fetch fails:**
- Check if video has captions enabled
- Try with `lang: 'en'` fallback
- Inform user that transcript is not available

**If video ID extraction fails:**
- Ask user to provide the full YouTube URL or video ID

## Environment Variables (for MCP server)

If using APIFY fallback:
```bash
export APIFY_API_TOKEN="..."  # Optional, for YouTube fallback
```

Store in 1Password: `op://Jarvis/Apify API/credential`
