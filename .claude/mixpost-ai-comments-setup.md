# Mixpost AI Comments with Eve - Setup Guide

## Overview
This guide walks you through setting up the AI-powered comment system in Mixpost, where Eve (your AI assistant) can automatically respond to comments using n8n and your AI agent.

## System Components

### 1. Eve AI Assistant Account
- **Name:** Eve (AI Assistant)
- **Email:** eve@everydaycreator.org
- **User ID:** 2
- **Role:** Member in workspace (can post comments)
- **Purpose:** The AI persona that responds to comments

### 2. Webhook Event: "New Comment Posted"
- **Triggers when:** Any user posts a comment in the Activity section of a post
- **Event name:** `post.comment.created`
- **Payload includes:**
  - Comment text
  - User information (who posted the comment)
  - Post UUID and details
  - Workspace ID
  - Parent comment ID (if it's a reply)

### 3. API Endpoint for Posting Comments
- **Endpoint:** `POST /api/mixpost/{workspace}/posts/{post}/comments`
- **Authentication:** Bearer token (API key from Mixpost)
- **Parameters:**
  - `text` (required): The comment content
  - `user_id` (optional): Set to 2 for Eve, or omit to use authenticated user
  - `parent_id` (optional): UUID of parent comment when replying to a thread

## Step-by-Step Setup Guide

### Step 1: Generate API Token in Mixpost

1. Log into Mixpost at https://social.everydaycreator.org
2. Navigate to Settings → API Access Tokens
3. Create a new token with appropriate permissions
4. Copy and save the token securely (you'll need it for n8n)

### Step 2: Create Webhook in Mixpost

1. In Mixpost, go to the **Webhooks** section
2. Click **Create Webhook**
3. Fill in the details:
   - **Name:** "n8n Comment Handler" (or any descriptive name)
   - **Callback URL:** Your n8n webhook URL (you'll get this from n8n in Step 3)
   - **Method:** POST
   - **Events:** Select "New Comment Posted"
   - **Active:** Yes
4. Save the webhook

### Step 3: Set Up n8n Workflow

#### 3.1 Create Webhook Trigger
1. Add a **Webhook** node
2. Set to **POST** method
3. Copy the webhook URL and paste it in Mixpost (Step 2)
4. The webhook will receive data like:
```json
{
  "comment": {
    "id": "comment-uuid",
    "text": "User's comment text",
    "user": {
      "id": 1,
      "name": "Francis Waldecker",
      "email": "francis.waldecker@gmail.com"
    },
    "is_reply": false,
    "timestamps": {...}
  },
  "post_id": 123,
  "post_uuid": "post-uuid-here",
  "workspace_id": 1,
  "workspace_uuid": "dd7477ef-bcd2-45dd-8f2e-14e790fdd2e2",
  "text": "User's comment text",
  "parent_id": null
}
```

#### 3.2 Process with AI Agent
1. Add your AI processing nodes (OpenAI, Claude, etc.)
2. Extract the comment text from `{{ $json.text }}`
3. Generate an appropriate response
4. Consider the context from post information if needed

#### 3.3 Post Response Back to Mixpost
1. Add an **HTTP Request** node
2. Configure it as follows:

**Method:** POST

**URL:** 
```
https://social.everydaycreator.org/mixpost/api/{{ $('Webhook').item.json.body.data.workspace_uuid }}/posts/{{ $('Webhook').item.json.body.data.post_uuid }}/comments
```

⚠️ **IMPORTANT:** 
- The URL structure is `/mixpost/api/` NOT `/api/mixpost/`
- The API requires the workspace UUID (not the numeric ID)
- The webhook node must be named "Webhook" for these variables to work

**Authentication:** 
- Type: Header Auth
- Name: `Authorization`
- Value: `Bearer YOUR_API_TOKEN_HERE`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

**Body (JSON):**
```json
{
  "text": "{{ $json.ai_response }}",
  "user_id": 2,
  "parent_id": "{{ $('Webhook').item.json.body.data.comment.id }}"
}
```

**Note:** 
- Set `user_id` to `2` to post as Eve
- Include `parent_id` to reply in thread, or omit for top-level comment
- The `text` field should contain your AI-generated response

### Step 4: Test the Integration

1. **Test Webhook Reception:**
   - Go to a post in Mixpost
   - Add a comment in the Activity section
   - Check n8n to see if the webhook was received

2. **Test AI Processing:**
   - Verify your AI agent receives the comment text
   - Check the generated response is appropriate

3. **Test Response Posting:**
   - Verify the HTTP Request succeeds
   - Check Mixpost to see Eve's response appear in the Activity section
   - The comment should show as from "Eve (AI Assistant)"

## Workflow Example

1. **User posts:** "What are the best times to post on Instagram?"
2. **Webhook fires** with comment data to n8n
3. **n8n processes** with AI agent
4. **AI generates:** "Based on engagement data, the best times to post on Instagram are typically Tuesday through Friday, 11am-3pm and 7pm-9pm in your audience's timezone. However, I recommend checking your specific analytics for optimal timing!"
5. **n8n posts** response as Eve
6. **Eve's comment appears** in Activity thread

## Troubleshooting

### Webhook Not Firing
- Check webhook is active in Mixpost
- Verify the callback URL is correct
- Check n8n webhook node is active

### API Authentication Failed
- Verify API token is correct
- Check token has necessary permissions
- Ensure Bearer prefix is included

### Comment Not Appearing
- Check the workspace UUID and post UUID are correct
- Verify Eve (user_id: 2) exists in the database
- Check API response for error messages

### Eve Shows as Regular User
- Ensure user_id is set to 2 in the API request
- Verify Eve's account exists with correct name

## Advanced Features

### Threading Replies
To make Eve reply directly to a comment (creating a thread):
- Include `parent_id` with the original comment's UUID
- This creates a nested conversation

### Conditional Responses
You can add logic in n8n to:
- Only respond to certain types of comments
- Ignore comments from specific users
- Rate limit responses
- Add different AI personalities based on context

### Multiple AI Personas
You could create additional AI users:
- Each with different expertise areas
- Route comments to different AI agents based on content
- Create a team of AI assistants

## API Reference

### POST /api/mixpost/{workspace}/posts/{post}/comments

**Request:**
```bash
curl -X POST \
  https://social.everydaycreator.org/mixpost/api/1/posts/abc-123/comments \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "This is Eve responding!",
    "user_id": 2,
    "parent_id": "parent-comment-uuid"
  }'
```

**Response:**
```json
{
  "id": "new-comment-uuid",
  "user": {
    "id": 2,
    "name": "Eve (AI Assistant)",
    "email": "eve@everydaycreator.org"
  },
  "text": "This is Eve responding!",
  "type": "comment",
  "is_child": true,
  "timestamps": {
    "created_at": "2025-08-09T02:45:00Z",
    "updated_at": "2025-08-09T02:45:00Z"
  }
}
```

## Security Considerations

1. **API Token:** Keep your API token secure and rotate it periodically
2. **Rate Limiting:** Implement rate limiting in n8n to prevent spam
3. **Content Filtering:** Add content moderation before posting
4. **Error Handling:** Implement proper error handling in n8n workflow
5. **Monitoring:** Log all AI responses for quality control

## Support

For issues or questions:
- Check Mixpost logs: `docker logs mixpost`
- Check n8n execution logs for errors
- Verify database entries: Eve should be user_id 2 in the users table
- Check webhook deliveries in Mixpost UI for status

---

*This system integrates Mixpost's internal commenting system with AI capabilities through Eve, your Everyday Operator Brain System assistant.*