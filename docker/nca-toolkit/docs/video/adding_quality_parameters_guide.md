# Developer Guide: Adding Video Quality Parameters to Caption Endpoint

This guide provides step-by-step instructions for developers to add video quality parameters (`video_crf`, `video_preset`, `video_bitrate`) to their NCA Toolkit caption endpoint implementation.

## Overview

This guide will help you modify your NCA Toolkit codebase to support video quality parameters in the `/v1/video/caption` endpoint, giving users control over output video quality and file size.

## Prerequisites

- Access to your NCA Toolkit codebase
- Basic understanding of Python and Flask
- Familiarity with FFmpeg parameters

## Step 1: Update Route Schema

First, modify the route validation schema to accept the new parameters.

### File: `routes/v1/video/caption_video.py`

Locate the `@validate_payload` decorator and add the following parameters after the `exclude_time_ranges` definition:

```python
@validate_payload({
    "type": "object",
    "properties": {
        # ... existing properties ...
        "exclude_time_ranges": {
            # ... existing definition ...
        },
        # ADD THESE NEW PARAMETERS:
        "video_crf": {
            "type": "integer",
            "minimum": 0,
            "maximum": 51
        },
        "video_preset": {
            "type": "string",
            "enum": ["ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow"]
        },
        "video_bitrate": {"type": "string"},
        # ... rest of properties ...
    },
    "required": ["video_url"],
    "additionalProperties": False
})
```

## Step 2: Update Route Handler

Next, modify the route handler to extract and pass these parameters.

### File: `routes/v1/video/caption_video.py`

In the `caption_video_v1` function, add parameter extraction:

```python
def caption_video_v1(job_id, data):
    video_url = data['video_url']
    captions = data.get('captions')
    settings = data.get('settings', {})
    replace = data.get('replace', [])
    exclude_time_ranges = data.get('exclude_time_ranges', [])
    webhook_url = data.get('webhook_url')
    id = data.get('id')
    language = data.get('language', 'auto')
    
    # ADD THESE LINES:
    video_crf = data.get('video_crf')
    video_preset = data.get('video_preset')
    video_bitrate = data.get('video_bitrate')
```

## Step 3: Update Service Function Call

Pass the quality parameters to the service function.

### File: `routes/v1/video/caption_video.py`

Update the `generate_ass_captions_v1` function call:

```python
# CHANGE FROM:
output = generate_ass_captions_v1(video_url, captions, settings, replace, exclude_time_ranges, job_id, language)

# TO:
output = generate_ass_captions_v1(video_url, captions, settings, replace, exclude_time_ranges, job_id, language, 
                                  video_crf=video_crf, video_preset=video_preset, video_bitrate=video_bitrate)
```

## Step 4: Update Service Function Signature

Modify the service function to accept the new parameters.

### File: `services/ass_toolkit.py`

Update the function signature:

```python
# CHANGE FROM:
def generate_ass_captions_v1(video_url, captions, settings, replace, exclude_time_ranges, job_id, language='auto', PlayResX=None, PlayResY=None):

# TO:
def generate_ass_captions_v1(video_url, captions, settings, replace, exclude_time_ranges, job_id, language='auto', PlayResX=None, PlayResY=None, video_crf=None, video_preset=None, video_bitrate=None):
```

## Step 5: Update FFmpeg Rendering

Modify the FFmpeg command to use the quality parameters.

### File: `routes/v1/video/caption_video.py`

Find the FFmpeg rendering section (around line 173-180) and replace it:

```python
# REPLACE THIS:
try:
    import ffmpeg
    ffmpeg.input(video_path).output(
        output_path,
        vf=f"subtitles='{ass_path}'",
        acodec='copy'
    ).run(overwrite_output=True)

# WITH THIS:
try:
    import ffmpeg
    
    # Build output arguments
    output_args = {
        'vf': f"subtitles='{ass_path}'",
        'acodec': 'copy'
    }
    
    # Add video quality parameters if specified
    if video_bitrate:
        output_args['video_bitrate'] = video_bitrate
    else:
        # Use CRF if no bitrate specified
        output_args['crf'] = video_crf if video_crf is not None else 18
        
    if video_preset:
        output_args['preset'] = video_preset
    
    ffmpeg.input(video_path).output(
        output_path,
        **output_args
    ).run(overwrite_output=True)
```

## Step 6: Test Your Implementation

Create a test script to verify the implementation:

```python
import requests
import json

# Test with quality parameters
payload = {
    "video_url": "https://example.com/test-video.mp4",
    "video_crf": 23,
    "video_preset": "medium",
    "settings": {
        "style": "classic",
        "font_size": 48
    }
}

response = requests.post(
    "https://your-api-endpoint/v1/video/caption",
    headers={"x-api-key": "YOUR_API_KEY"},
    json=payload
)

print(f"Status: {response.status_code}")
print(f"Response: {response.json()}")
```

## Step 7: Rebuild and Deploy

After making all changes:

```bash
# If using Docker
docker build -t nca-toolkit:local .
docker stop nca-toolkit && docker rm nca-toolkit
docker run -d --name nca-toolkit --network docker_default --restart unless-stopped -p 8080:8080 --env-file .env nca-toolkit:local

# Verify container is running
docker ps | grep nca-toolkit
```

## Common Implementation Mistakes

### 1. Parameters in Wrong Location
❌ **Wrong**: Putting parameters inside `settings`
```json
{
    "settings": {
        "video_crf": 18  // This will cause validation error
    }
}
```

✅ **Correct**: Parameters at root level
```json
{
    "video_crf": 18,
    "settings": {
        "font_size": 48
    }
}
```

### 2. Missing Function Parameters
Ensure you update ALL occurrences:
- Route handler parameter extraction
- Service function call
- Service function signature
- FFmpeg rendering logic

### 3. Schema Validation Errors
If you get "Additional properties are not allowed" errors:
- Check that you added parameters to the schema
- Ensure `additionalProperties: False` comes AFTER all property definitions
- Verify parameter names match exactly

## Testing Different Quality Levels

Test your implementation with various quality settings:

```bash
# High quality
curl -X POST ... -d '{"video_crf": 18, "video_preset": "slow", ...}'

# Balanced
curl -X POST ... -d '{"video_crf": 23, "video_preset": "medium", ...}'

# Fast processing
curl -X POST ... -d '{"video_crf": 28, "video_preset": "fast", ...}'

# Fixed bitrate
curl -X POST ... -d '{"video_bitrate": "5M", "video_preset": "medium", ...}'
```

## Verification Checklist

- [ ] Schema updated with new parameters
- [ ] Route handler extracts all three parameters
- [ ] Service function signature updated
- [ ] Service function called with new parameters
- [ ] FFmpeg rendering uses quality parameters
- [ ] Default CRF (18) applied when not specified
- [ ] All parameter combinations tested
- [ ] Documentation updated

## Default Behavior

When quality parameters are not provided:
- CRF: 18 (visually lossless)
- Preset: Uses FFmpeg default (typically medium)
- Bitrate: Not set (uses CRF mode)

## Performance Considerations

- Slower presets increase processing time significantly
- Lower CRF values increase file size exponentially
- Bitrate mode provides predictable file sizes but may vary quality

## Support

If you encounter issues:
1. Check Docker logs: `docker logs nca-toolkit`
2. Verify parameter names match exactly
3. Ensure parameters are at root level of request
4. Test with minimal payload first

This implementation gives your users full control over video quality while maintaining backward compatibility with existing requests.