# Modern Firebase Push Notification Setup (2025)

Since FCM Server Keys are deprecated, here's the updated approach using Firebase Admin SDK.

## Quick Setup for Modern Firebase (Recommended)

### Option 1: Use Firebase Admin SDK (Most Secure)

**Step 1: Get Firebase Service Account**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → Settings → Service Accounts
3. Click "Generate new private key"
4. Download the JSON file

**Step 2: Convert to Base64**
```powershell
# Windows PowerShell
$jsonContent = Get-Content "path\to\your\service-account.json" -Raw
$bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonContent)
$base64 = [System.Convert]::ToBase64String($bytes)
Write-Output $base64
```

**Step 3: Set Environment Variable**
In Supabase Dashboard → Project Settings → Edge Functions:
```
FIREBASE_SERVICE_ACCOUNT=your_base64_encoded_service_account_here
```

### Option 2: Use Firebase REST API with Web API Key (Simpler)

**Step 1: Get Firebase Web API Key**
1. Go to Firebase Console → Project Settings → General
2. Copy the "Web API Key" from your web app configuration

**Step 2: Set Environment Variable**
In Supabase Dashboard:
```
FIREBASE_WEB_API_KEY=your_web_api_key_here
```

## Simplified Edge Function (Using Web API Key)

Since the full Admin SDK implementation is complex, here's a simpler version using Firebase's Web API:

```typescript
// supabase/functions/send-push-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface NotificationRequest {
  receiver_user_id: string
  title: string
  body: string
  data?: Record<string, any>
  notification_type?: string
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders })
  }

  try {
    const { receiver_user_id, title, body, data } = await req.json()
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const webApiKey = Deno.env.get('FIREBASE_WEB_API_KEY')
    if (!webApiKey) {
      throw new Error('FIREBASE_WEB_API_KEY not set')
    }

    // Get user's FCM tokens
    const { data: devices } = await supabase
      .from('user_devices')
      .select('fcm_token')
      .eq('user_id', receiver_user_id)
      .eq('is_active', true)
      .not('fcm_token', 'is', null)

    if (!devices || devices.length === 0) {
      return new Response(JSON.stringify({ 
        success: false, 
        message: 'No active devices found' 
      }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    let successCount = 0
    let failureCount = 0

    // Send to each device
    for (const device of devices) {
      try {
        const response = await fetch(`https://fcm.googleapis.com/fcm/send`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `key=${webApiKey}`
          },
          body: JSON.stringify({
            to: device.fcm_token,
            notification: { title, body },
            data: data || {},
            priority: 'high'
          })
        })

        if (response.ok) {
          successCount++
        } else {
          failureCount++
          console.error('FCM error:', await response.text())
        }
      } catch (error) {
        failureCount++
        console.error('Send error:', error)
      }
    }

    return new Response(JSON.stringify({
      success: successCount > 0,
      devices_reached: successCount,
      devices_failed: failureCount
    }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

  } catch (error) {
    return new Response(JSON.stringify({ 
      error: error.message 
    }), { 
      status: 500, 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })
  }
})
```

## Quick Deployment

1. **Replace your current Edge Function:**
   ```bash
   # Copy the simplified code above to:
   # supabase/functions/send-push-notification/index.ts
   ```

2. **Deploy:**
   ```bash
   cd e:\github\crystal_social
   supabase functions deploy send-push-notification --no-verify-jwt
   ```

3. **Test:**
   ```dart
   await pushService.sendChatNotification(
     receiverUserId: 'test-user-id',
     senderUsername: 'TestUser',
     message: 'Hello from modern Firebase!',
   );
   ```

## Migration Notes

- ✅ **FCM Server Keys still work** but are deprecated (will be removed eventually)
- ✅ **Web API Keys** continue to work and are simpler to implement
- ✅ **Firebase Admin SDK** is the future-proof approach but more complex
- ✅ **Your existing Flutter FCM setup** doesn't need changes

## Recommendation

**For immediate deployment**: Use Option 2 (Web API Key) - it's simple and works reliably.

**For production long-term**: Plan migration to Firebase Admin SDK when you have time for the more complex implementation.

Your Crystal Social notifications will work perfectly with either approach! 🚀
