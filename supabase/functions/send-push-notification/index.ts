// Simplified Push Notification Edge Function - Using Web API Key
// Deploy with: supabase functions deploy send-push-notification --no-verify-jwt

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface NotificationRequest {
  receiver_user_id: string
  title: string
  body: string
  data?: Record<string, any>
  notification_type?: 'message' | 'achievement' | 'support' | 'system' | 'friend_request' | 'pet_interaction'
  priority?: 'high' | 'normal' | 'low'
  custom_sound?: string
  badge_count?: number
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    })
  }

  try {
    // Validate request method
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { 
          status: 405, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Parse request body
    const requestBody: NotificationRequest = await req.json()
    
    // Validate required fields
    if (!requestBody.receiver_user_id || !requestBody.title || !requestBody.body) {
      return new Response(
        JSON.stringify({ 
          error: 'Missing required fields: receiver_user_id, title, body' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Initialize Supabase client with service role
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get Firebase Web API key from environment
    const webApiKey = Deno.env.get('FIREBASE_WEB_API_KEY')
    if (!webApiKey) {
      return new Response(
        JSON.stringify({ error: 'FIREBASE_WEB_API_KEY environment variable not set' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Send notification
    const result = await sendPushNotification(supabase, webApiKey, requestBody)
    
    return new Response(
      JSON.stringify(result),
      { 
        status: result.success ? 200 : 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('❌ Push notification error:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

/**
 * Send push notification to user's devices
 */
async function sendPushNotification(
  supabase: any, 
  webApiKey: string, 
  request: NotificationRequest
) {
  const { receiver_user_id, title, body, data, notification_type, priority, custom_sound, badge_count } = request

  try {
    // Get user's notification preferences (if table exists)
    let userPrefs = { messages: true, achievements: true, support: true, system: true, friend_requests: true, pet_interactions: true }
    try {
      const { data: prefsData } = await supabase
        .from('user_notification_preferences')
        .select('*')
        .eq('user_id', receiver_user_id)
        .maybeSingle()
      
      if (prefsData) userPrefs = prefsData
    } catch (prefsError) {
      console.log('📱 No notification preferences table found, using defaults')
    }

    // Check if user has notifications enabled for this type
    if (!isNotificationAllowed(userPrefs, notification_type || 'message')) {
      return {
        success: false,
        message: 'User has disabled this type of notification',
        devices_reached: 0
      }
    }

    // Get all active devices for the user
    const { data: devices, error: devicesError } = await supabase
      .from('user_devices')
      .select('id, fcm_token, device_type, is_active')
      .eq('user_id', receiver_user_id)
      .eq('is_active', true)
      .not('fcm_token', 'is', null)

    if (devicesError) {
      console.error('❌ Error fetching devices:', devicesError)
      return {
        success: false,
        message: 'Error fetching user devices',
        devices_reached: 0
      }
    }

    if (!devices || devices.length === 0) {
      return {
        success: false,
        message: 'No active devices found for user',
        devices_reached: 0
      }
    }

    // Send notifications via FCM
    let successCount = 0
    let failureCount = 0
    const invalidTokens = []

    for (const device of devices) {
      try {
        const fcmPayload = {
          to: device.fcm_token,
          notification: {
            title,
            body,
            sound: custom_sound || 'default',
            badge: badge_count || 1
          },
          data: {
            type: notification_type || 'message',
            timestamp: new Date().toISOString(),
            ...data
          },
          priority: priority || 'high',
          content_available: true,
          mutable_content: true
        }

        const response = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `key=${webApiKey}`
          },
          body: JSON.stringify(fcmPayload)
        })

        if (response.ok) {
          successCount++
          console.log(`✅ Notification sent to device ${device.id}`)
        } else {
          const errorText = await response.text()
          console.error(`❌ FCM error for device ${device.id}:`, errorText)
          
          // Check for invalid token errors
          if (errorText.includes('NotRegistered') || errorText.includes('InvalidRegistration')) {
            invalidTokens.push(device.id)
          }
          
          failureCount++
        }
      } catch (deviceError) {
        console.error(`❌ Error sending to device ${device.id}:`, deviceError)
        failureCount++
      }
    }

    // Update invalid tokens
    if (invalidTokens.length > 0) {
      try {
        await supabase
          .from('user_devices')
          .update({ is_active: false, updated_at: new Date().toISOString() })
          .in('id', invalidTokens)
        
        console.log(`📱 Marked ${invalidTokens.length} devices as inactive`)
      } catch (updateError) {
        console.error('❌ Error updating invalid tokens:', updateError)
      }
    }

    // Log notification for analytics (if table exists)
    try {
      await supabase.from('notification_logs').insert({
        receiver_user_id,
        sender_username: data?.sender || 'System',
        title,
        body,
        notification_type: notification_type || 'message',
        device_count: devices.length,
        success_count: successCount,
        notification_data: data || {},
        created_at: new Date().toISOString()
      })
    } catch (logError) {
      console.log('📊 No notification logs table found, skipping analytics')
    }

    return {
      success: successCount > 0,
      message: `Notification sent to ${successCount}/${devices.length} devices`,
      devices_reached: successCount,
      devices_failed: failureCount,
      device_count: devices.length,
      success_count: successCount
    }

  } catch (error) {
    console.error('❌ Error sending push notification:', error)
    throw error
  }
}

/**
 * Check if notification type is allowed for user
 */
function isNotificationAllowed(preferences: any, notificationType: string): boolean {
  // Check type-specific preferences
  switch (notificationType) {
    case 'message':
      return preferences.messages ?? true
    case 'achievement':
      return preferences.achievements ?? true
    case 'support':
      return preferences.support ?? true
    case 'system':
      return preferences.system ?? true
    case 'friend_request':
      return preferences.friend_requests ?? true
    case 'pet_interaction':
      return preferences.pet_interactions ?? true
    default:
      return true
  }
}
