# Video Captioning Endpoint (v1)

## 1. Overview

The `/v1/video/caption` endpoint is part of the Video API and is responsible for adding captions to a video file. It accepts a video URL, caption text, and various styling options for the captions. The endpoint utilizes the `process_captioning_v1` service to generate a captioned video file, which is then uploaded to cloud storage, and the cloud URL is returned in the response.

## 2. Endpoint

**URL:** `/v1/video/caption`
**Method:** `POST`

## 3. Request

### Headers

- `x-api-key`: Required. The API key for authentication.

### Body Parameters

The request body must be a JSON object with the following properties:

- `video_url` (string, required): The URL of the video file to be captioned.
- `captions` (string, optional): Can be one of the following:
  - Raw caption text to be added to the video
  - URL to an SRT subtitle file
  - URL to an ASS subtitle file
  - If not provided, the system will automatically generate captions by transcribing the audio from the video
- `settings` (object, optional): An object containing various styling options for the captions. See the schema below for available options.
- `replace` (array, optional): An array of objects with `find` and `replace` properties, specifying text replacements to be made in the captions.
- `webhook_url` (string, optional): A URL to receive a webhook notification when the captioning process is complete.
- `id` (string, optional): An identifier for the request.
- `language` (string, optional): The language code for the captions (e.g., "en", "fr"). Defaults to "auto".
- `exclude_time_ranges` (array, optional): List of time ranges to skip when adding captions. Each item must be an object with:
  - `start`: (string, required) The start time of the excluded range, as a string timecode in `hh:mm:ss.ms` format (e.g., `00:01:23.456`).
  - `end`: (string, required) The end time, as a string timecode in `hh:mm:ss.ms` format, which must be strictly greater than `start`.
  If either value is not a valid timecode string, or if `end` is not greater than `start`, the request will return an error.

#### Settings Schema

```json
{
    "type": "object",
    "properties": {
        "line_color": {"type": "string"},
        "word_color": {"type": "string"},
        "outline_color": {"type": "string"},
        "all_caps": {"type": "boolean"},
        "max_words_per_line": {"type": "integer"},
        "x": {"type": "integer"},
        "y": {"type": "integer"},
        "position": {
            "type": "string",
            "enum": [
                "bottom_left", "bottom_center", "bottom_right",
                "middle_left", "middle_center", "middle_right",
                "top_left", "top_center", "top_right"
            ]
        },
        "alignment": {
            "type": "string",
            "enum": ["left", "center", "right"]
        },
        "font_family": {"type": "string"},
        "font_size": {"type": "integer"},
        "bold": {"type": "boolean"},
        "italic": {"type": "boolean"},
        "underline": {"type": "boolean"},
        "strikeout": {"type": "boolean"},
        "style": {
            "type": "string",
            "enum": [
                "classic",     // Regular captioning with all text displayed at once
                "karaoke",     // Highlights words sequentially in a karaoke style
                "highlight",   // Shows full text but highlights the current word
                "underline",   // Shows full text but underlines the current word
                "word_by_word" // Shows one word at a time
            ]
        },
        "outline_width": {"type": "integer"},
        "spacing": {"type": "integer"},
        "angle": {"type": "integer"},
        "shadow_offset": {"type": "integer"}
    },
    "additionalProperties": false
}
```

### Video Quality Parameter Guidelines

The caption endpoint supports advanced video quality parameters that give you fine control over the output video quality and file size. These parameters are crucial for optimizing your videos for different use cases.

#### Quick Quality Presets by Use Case

**For YouTube/Professional Content:**
```json
{
    "video_crf": 18,
    "video_preset": "slow"
}
```

**For Quick Previews/Drafts:**
```json
{
    "video_crf": 28,
    "video_preset": "faster"
}
```

**For File Size Constraints:**
```json
{
    "video_bitrate": "5M",
    "video_preset": "medium"
}
```

#### Critical: Parameter Placement

⚠️ **CRITICAL**: Quality parameters MUST be at the root level of your request body.

✅ **CORRECT** - Parameters at root level:
```json
{
    "video_url": "https://example.com/video.mp4",
    "video_crf": 18,              // ✅ CORRECT - At root
    "video_preset": "slow",       // ✅ CORRECT - At root
    "settings": {                 // Caption styling settings
        "font_size": 72,
        "style": "highlight"
    }
}
```

❌ **WRONG** - Never put quality parameters inside settings:
```json
{
    "video_url": "https://example.com/video.mp4",
    "settings": {
        "font_size": 72,
        "video_crf": 18,          // ❌ WRONG - Will cause error!
        "video_preset": "slow"    // ❌ WRONG - Will cause error!
    }
}
```

This will result in an error: `"Invalid payload: Additional properties are not allowed ('video_crf', 'video_preset' were unexpected)"`

### Example Requests

#### Example 1: Basic Automatic Captioning
```json
{
    "video_url": "https://example.com/video.mp4"
}
```
This minimal request will automatically transcribe the video and add white captions at the bottom center.

#### Example 2: Custom Text with Styling
```json
{
    "video_url": "https://example.com/video.mp4",
    "captions": "This is a sample caption text.",
    "settings": {
        "style": "classic",
        "line_color": "#FFFFFF",
        "outline_color": "#000000",
        "position": "bottom_center",
        "alignment": "center",
        "font_family": "Arial",
        "font_size": 24,
        "bold": true
    }
}
```

#### Example 3: High Quality Production with Captions
```json
{
    "video_url": "https://example.com/video.mp4",
    "video_crf": 18,
    "video_preset": "slow",
    "settings": {
        "style": "highlight",
        "font_family": "The Bold Font",
        "font_size": 72,
        "line_color": "#00FFD1",
        "word_color": "#FFC700",
        "outline_color": "#080818",
        "position": "bottom_center",
        "alignment": "center"
    },
    "webhook_url": "https://yourwebhook.com/endpoint"
}
```

#### Example 4: Balanced Quality and Speed
```json
{
    "video_url": "https://example.com/video.mp4",
    "video_crf": 23,
    "video_preset": "medium",
    "settings": {
        "style": "classic",
        "font_size": 48,
        "position": "bottom_center"
    }
}
```

#### Example 5: Fixed Bitrate for Streaming
```json
{
    "video_url": "https://example.com/video.mp4",
    "video_bitrate": "6M",
    "video_preset": "fast",
    "settings": {
        "style": "karaoke",
        "font_size": 60,
        "line_color": "#FFFFFF",
        "word_color": "#FFFF00"
    }
}
```

#### Example 6: Karaoke-Style Captions with Advanced Options
```json
{
    "video_url": "https://example.com/video.mp4",
    "settings": {
        "line_color": "#FFFFFF",
        "word_color": "#FFFF00",
        "outline_color": "#000000",
        "all_caps": false,
        "max_words_per_line": 10,
        "position": "bottom_center",
        "alignment": "center",
        "font_family": "Arial",
        "font_size": 24,
        "bold": false,
        "italic": false,
        "style": "karaoke",
        "outline_width": 2,
        "shadow_offset": 2
    },
    "replace": [
        {
            "find": "um",
            "replace": ""
        },
        {
            "find": "like",
            "replace": ""
        }
    ],
    "webhook_url": "https://example.com/webhook",
    "id": "request-123",
    "language": "en"
}
```

#### Example 4: Using an External Subtitle File
```json
{
    "video_url": "https://example.com/video.mp4",
    "captions": "https://example.com/subtitles.srt",
    "settings": {
        "line_color": "#FFFFFF",
        "outline_color": "#000000",
        "position": "bottom_center",
        "font_family": "Arial",
        "font_size": 24
    }
}
```

#### Example 5: Excluding Time Ranges from Captioning
```json
{
    "video_url": "https://example.com/video.mp4",
    "settings": {
        "style": "classic",
        "line_color": "#FFFFFF",
        "outline_color": "#000000",
        "position": "bottom_center",
        "font_family": "Arial",
        "font_size": 24
    },
    "exclude_time_ranges": [
        { "start": "00:00:10.000", "end": "00:00:20.000" },
        { "start": "00:00:30.000", "end": "00:00:40.000" }
    ]
}
```

#### CURL Example with Quality Parameters

```bash
curl -X POST https://your-api-endpoint.com/v1/video/caption \
  -H "x-api-key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "video_url": "https://example.com/video.mp4",
    "video_crf": 18,
    "video_preset": "slow",
    "settings": {
        "line_color": "#FFFFFF",
        "word_color": "#FFFF00",
        "outline_color": "#000000",
        "all_caps": false,
        "max_words_per_line": 10,
        "position": "bottom_center",
        "alignment": "center",
        "font_family": "Arial",
        "font_size": 24,
        "style": "karaoke",
        "outline_width": 2
    },
    "replace": [
        {
            "find": "um",
            "replace": ""
        }
    ],
    "id": "custom-request-id"
}'
```

#### n8n Integration Example

When using n8n HTTP Request node:
1. Set Method: POST
2. Set URL: `https://your-api-endpoint.com/v1/video/caption`
3. Add Header: `x-api-key: YOUR_API_KEY`
4. Set Body Content Type: JSON
5. Use this expression if your data is nested:
   ```
   {{ $json.captionApiPayload }}
   ```

Ensure your payload structure has quality parameters at the root level.

## 4. Response

### Success Response

The response will be a JSON object with the following properties:

- `code` (integer): The HTTP status code (200 for success).
- `id` (string): The request identifier, if provided in the request.
- `job_id` (string): A unique identifier for the job.
- `response` (string): The cloud URL of the captioned video file.
- `message` (string): A success message.
- `pid` (integer): The process ID of the worker that processed the request.
- `queue_id` (integer): The ID of the queue used for processing the request.
- `run_time` (float): The time taken to process the request (in seconds).
- `queue_time` (float): The time the request spent in the queue (in seconds).
- `total_time` (float): The total time taken for the request (in seconds).
- `queue_length` (integer): The current length of the processing queue.
- `build_number` (string): The build number of the application.

Example:

```json
{
    "code": 200,
    "id": "request-123",
    "job_id": "d290f1ee-6c54-4b01-90e6-d701748f0851",
    "response": "https://cloud.example.com/captioned-video.mp4",
    "message": "success",
    "pid": 12345,
    "queue_id": 140682639937472,
    "run_time": 5.234,
    "queue_time": 0.012,
    "total_time": 5.246,
    "queue_length": 0,
    "build_number": "1.0.0"
}
```

### Error Responses

#### Missing or Invalid Parameters

**Status Code:** 400 Bad Request

```json
{
    "code": 400,
    "id": "request-123",
    "job_id": "d290f1ee-6c54-4b01-90e6-d701748f0851",
    "message": "Missing or invalid parameters",
    "pid": 12345,
    "queue_id": 140682639937472,
    "queue_length": 0,
    "build_number": "1.0.0"
}
```

#### Font Error

**Status Code:** 400 Bad Request

```json
{
    "code": 400,
    "error": "The requested font 'InvalidFont' is not available. Please choose from the available fonts.",
    "available_fonts": ["Arial", "Times New Roman", "Courier New", ...],
    "pid": 12345,
    "queue_id": 140682639937472,
    "queue_length": 0,
    "build_number": "1.0.0"
}
```

#### Internal Server Error

**Status Code:** 500 Internal Server Error

```json
{
    "code": 500,
    "id": "request-123",
    "job_id": "d290f1ee-6c54-4b01-90e6-d701748f0851",
    "error": "An unexpected error occurred during the captioning process.",
    "pid": 12345,
    "queue_id": 140682639937472,
    "queue_length": 0,
    "build_number": "1.0.0"
}
```

## 5. Error Handling

The endpoint handles the following common errors:

- **Missing or Invalid Parameters**: If any required parameters are missing or invalid, a 400 Bad Request error is returned with a descriptive error message.
- **Font Error**: If the requested font is not available, a 400 Bad Request error is returned with a list of available fonts.
- **Internal Server Error**: If an unexpected error occurs during the captioning process, a 500 Internal Server Error is returned with an error message.

Additionally, the main application context (`app.py`) includes error handling for queue overload. If the maximum queue length (`MAX_QUEUE_LENGTH`) is set and the queue size reaches that limit, a 429 Too Many Requests error is returned with a descriptive message.

## 6. Usage Notes

- The `video_url` parameter must be a valid URL pointing to a video file (MP4, MOV, etc.).
- The `captions` parameter is optional and can be used in multiple ways:
  - If not provided, the endpoint will automatically transcribe the audio and generate captions
  - If provided as plain text, the text will be used as captions for the entire video
  - If provided as a URL to an SRT or ASS subtitle file, the system will use that file for captioning
  - For SRT files, only 'classic' style is supported
  - For ASS files, the original styling will be preserved
- The `settings` parameter allows for customization of the caption appearance and behavior:
  - `style` determines how captions are displayed, with options including:
    - `classic`: Regular captioning with all text displayed at once
    - `karaoke`: Highlights words sequentially in a karaoke style as they're spoken
    - `highlight`: Shows the full caption text but highlights each word as it's spoken
    - `underline`: Shows the full caption text but underlines each word as it's spoken
    - `word_by_word`: Shows only one word at a time
  - `position` can be used to place captions in one of nine positions on the screen
  - `alignment` determines text alignment within the position (left, center, right)
  - `font_family` can be any available system font
  - Color options can be set using hex codes (e.g., "#FFFFFF" for white)
- The `replace` parameter can be used to perform text replacements in the captions (useful for correcting words or censoring content).
- The `webhook_url` parameter is optional and can be used to receive a notification when the captioning process is complete.
- The `id` parameter is optional and can be used to identify the request in webhook responses.
- The `language` parameter is optional and can be used to specify the language of the captions for transcription. If not provided, the language will be automatically detected.
- The `exclude_time_ranges` parameter can be used to specify time ranges to be excluded from captioning.

## 7. Common Issues

- Providing an invalid or inaccessible `video_url`.
- Requesting an unavailable font in the `settings` object.
- Exceeding the maximum queue length, resulting in a 429 Too Many Requests error.
- **Quality Parameter Errors**:
  - "Additional properties are not allowed" - Quality parameters must be at root level, not inside `settings`
  - Poor video quality - Lower the CRF value (try 18-20) or use a slower preset
  - Processing takes too long - Use a faster preset or increase CRF slightly (23-25)

### Troubleshooting Video Quality

#### "Additional properties are not allowed" Error
```json
// Error response:
{
    "message": "Invalid payload: Additional properties are not allowed ('video_crf', 'video_preset' were unexpected)"
}
```
**Solution**: Ensure quality parameters are at the root level of your request, not nested inside `settings` or any other object.

#### Quality Looks Poor
- Lower the CRF value (try 18-20 for high quality)
- Use a slower preset (`slow` or `slower`)
- Consider using bitrate for consistency

#### Processing Takes Too Long
- Use a faster preset (`faster` or `fast`)
- Increase CRF slightly (23-25)
- Consider processing shorter clips or in batches

#### File Size Too Large
- Increase CRF value (25-30)
- Use `video_bitrate` to cap file size
- Use a faster preset

## 8. Best Practices

- Validate the `video_url` parameter before sending the request to ensure it points to a valid and accessible video file.
- Use the `webhook_url` parameter to receive notifications about the captioning process, rather than polling the API for updates.
- Provide descriptive and meaningful `id` values to easily identify requests in logs and responses.
- Use the `replace` parameter judiciously to avoid unintended text replacements in the captions.
- Consider caching the captioned video files for frequently requested videos to improve performance and reduce processing time.

### Video Quality Best Practices

1. **Start with defaults** - Only add quality parameters when needed. The default (CRF 18, medium preset) works well for most use cases.
2. **Test with short clips** - Find optimal settings with 30-60 second test videos before processing full-length content.
3. **Monitor file sizes** - Balance quality vs storage costs. Track output sizes for different parameter combinations.
4. **Use appropriate presets**:
   - Production/Archive: CRF 18, slow preset
   - Web delivery: CRF 23, medium preset
   - Quick preview: CRF 28, fast preset
5. **Log your settings** - Track what works for different content types to build your own presets.

### Example Integration Workflow

1. Receive video for captioning
2. Determine quality requirements:
   - Final production? → CRF 18, slow preset
   - Quick review? → CRF 25, fast preset
   - Size limit? → Use bitrate
3. Build request with parameters at root level
4. Send request with webhook URL
5. Handle webhook response
6. Deliver captioned video

### When to Use Each Parameter

**Use CRF when:**
- You want consistent quality across different scenes
- File size can vary
- Quality is the primary concern

**Use Bitrate when:**
- You need predictable file sizes
- Streaming platforms require specific bitrates
- Bandwidth is limited

**Use Preset when:**
- You need faster processing (use faster presets)
- You want better compression (use slower presets)
- You're balancing quality vs processing time

### Quality Parameter Reference

#### CRF (Constant Rate Factor) Values
- **0-17**: Near lossless, very large files
- **18**: Visually lossless (default, recommended for high quality)
- **19-23**: Very good quality, reasonable file size
- **24-27**: Good quality, smaller files
- **28-35**: Acceptable quality, much smaller files
- **36-51**: Lower quality, smallest files

#### Preset Speed/Quality Trade-offs
- **ultrafast**: Fastest encoding, largest file, lowest quality
- **superfast**: Very fast, larger files
- **veryfast**: Fast encoding, good for real-time
- **faster**: Faster than default
- **fast**: Good balance for quick processing
- **medium**: Balanced (default)
- **slow**: Better compression, longer processing
- **slower**: Much better compression
- **veryslow**: Best compression, longest processing

#### Bitrate Guidelines
- **1080p @ 30fps**: 8-12 Mbps for high quality
- **1080p @ 60fps**: 12-18 Mbps for high quality
- **720p @ 30fps**: 5-8 Mbps for high quality
- **720p @ 60fps**: 7-10 Mbps for high quality
- Use format: "8M" for 8 Mbps, "5000k" for 5000 kbps

Remember: Quality parameters are optional. The endpoint will use sensible defaults (CRF 18, medium preset) if you don't specify them.