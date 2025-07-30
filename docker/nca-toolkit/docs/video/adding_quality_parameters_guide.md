# Step-by-Step Guide: Adding Quality Parameters to Caption Endpoint

This guide explains how to use the video quality parameters (`video_crf`, `video_preset`, `video_bitrate`) when calling the `/v1/video/caption` endpoint.

## Quick Reference

### Available Quality Parameters

1. **`video_crf`** (integer, 0-51)
   - Controls video quality vs file size
   - Lower = better quality, larger file
   - Default: 18 (visually lossless)

2. **`video_preset`** (string)
   - Controls encoding speed vs compression efficiency
   - Slower = better compression, longer processing
   - Options: `ultrafast`, `superfast`, `veryfast`, `faster`, `fast`, `medium`, `slow`, `slower`, `veryslow`
   - Default: `medium`

3. **`video_bitrate`** (string)
   - Forces constant bitrate instead of variable quality
   - Format: `"5M"`, `"8000k"`, etc.
   - Overrides CRF when specified

## Step 1: Understand Your Quality Needs

### Choose Based on Use Case:

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

## Step 2: Structure Your Request Correctly

### ⚠️ CRITICAL: Parameters MUST be at the root level

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

### ❌ NEVER put quality parameters inside settings:
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

## Step 3: Complete Examples

### Example 1: High Quality for Final Production
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
        "outline_color": "#080818"
    },
    "webhook_url": "https://yourwebhook.com/endpoint"
}
```

### Example 2: Balanced Quality and Speed
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

### Example 3: Fixed Bitrate for Streaming
```json
{
    "video_url": "https://example.com/video.mp4",
    "video_bitrate": "6M",
    "video_preset": "fast",
    "settings": {
        "style": "karaoke",
        "font_size": 60
    }
}
```

## Step 4: Test Your Request

### Using curl:
```bash
curl -X POST https://your-api-endpoint/v1/video/caption \
  -H "x-api-key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "video_url": "https://example.com/video.mp4",
    "video_crf": 18,
    "video_preset": "slow",
    "settings": {
        "font_size": 72,
        "style": "highlight"
    }
}'
```

### Using n8n:
1. Add HTTP Request node
2. Set Method: POST
3. Set URL: `https://your-api-endpoint/v1/video/caption`
4. Add Header: `x-api-key: YOUR_API_KEY`
5. Set Body Content Type: JSON
6. Use this expression if your data is nested:
   ```
   {{ $json.captionApiPayload }}
   ```

## Step 5: Verify Success

### Successful Response:
```json
{
    "code": 200,
    "response": "https://storage.example.com/output-video.mp4",
    "message": "success"
}
```

### Common Error (Wrong Structure):
```json
{
    "message": "Invalid payload: Additional properties are not allowed ('video_crf', 'video_preset' were unexpected)"
}
```
**Fix:** Ensure parameters are at root level, not inside settings or wrapped in another object.

## Quality Parameter Guidelines

### CRF (Constant Rate Factor)
- **0-17**: Near lossless, very large files
- **18**: Visually lossless (recommended for high quality)
- **19-23**: Very good quality, reasonable file size
- **24-27**: Good quality, smaller files
- **28-35**: Acceptable quality, much smaller files
- **36-51**: Lower quality, smallest files

### Preset Speed/Quality Trade-offs
- **ultrafast**: Fastest encoding, largest file, lowest quality
- **fast/faster**: Good for quick processing
- **medium**: Balanced (default)
- **slow/slower**: Better compression, longer processing
- **veryslow**: Best compression, longest processing

### When to Use Bitrate Instead of CRF
- When you need predictable file sizes
- For streaming platforms with bitrate requirements
- When bandwidth is a primary concern

## Troubleshooting

### "Additional properties are not allowed" Error
- Check that quality parameters are at root level
- Ensure no typos in parameter names
- Verify you're not wrapping the payload

### Quality Looks Poor
- Lower the CRF value (try 18-20)
- Use a slower preset
- Consider using bitrate for consistency

### Processing Takes Too Long
- Use a faster preset
- Increase CRF slightly (23-25)
- Consider processing in batches

## Best Practices

1. **Start with defaults** - Only add quality parameters when needed
2. **Test with short clips** - Find optimal settings before processing long videos
3. **Monitor file sizes** - Balance quality vs storage costs
4. **Use webhooks** - Don't poll for results
5. **Log your settings** - Track what works for different content types

## Example Integration Workflow

1. Receive video for captioning
2. Determine quality requirements:
   - Final production? → CRF 18, slow preset
   - Quick review? → CRF 25, fast preset
   - Size limit? → Use bitrate
3. Build request with parameters at root level
4. Send request with webhook URL
5. Handle webhook response
6. Deliver captioned video

Remember: Quality parameters are optional. The endpoint will use sensible defaults (CRF 18, medium preset) if you don't specify them.