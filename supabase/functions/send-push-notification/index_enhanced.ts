// Enhanced Supabase Edge Function: send-push-notification
// This version uses Firebase Admin SDK instead of deprecated FCM server keys
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
  schedule_time?: string // ISO string for scheduled notifications
}

interface FCMResponse {
  success: number
  failure: number
  canonical_ids: number
  multicast_id: number
  results: Array<{
    message_id?: string
    registration_id?: string
    error?: string
  }>
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

    // Get Firebase service account from environment
    const firebaseServiceAccountBase64 = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!firebaseServiceAccountBase64) {
      return new Response(
        JSON.stringify({ error: 'FIREBASE_SERVICE_ACCOUNT environment variable not set' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    let firebaseServiceAccount
    try {
      const serviceAccountJson = atob(firebaseServiceAccountBase64)
      firebaseServiceAccount = JSON.parse(serviceAccountJson)
    } catch (error) {
      return new Response(
        JSON.stringify({ error: 'Invalid FIREBASE_SERVICE_ACCOUNT format' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Check if notification should be scheduled
    if (requestBody.schedule_time) {
      const scheduleTime = new Date(requestBody.schedule_time)
      const now = new Date()
      
      if (scheduleTime > now) {
        // Store scheduled notification
        await storeScheduledNotification(supabase, requestBody)
        return new Response(
          JSON.stringify({ 
            success: true, 
            message: 'Notification scheduled successfully',
            scheduled_for: scheduleTime.toISOString()
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // Send notification immediately
    const result = await sendPushNotification(supabase, firebaseServiceAccount, requestBody)
    
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
  firebaseServiceAccount: any, 
  request: NotificationRequest
) {
  const { receiver_user_id, title, body, data, notification_type, priority, custom_sound, badge_count } = request

  try {
    // Get user's notification preferences
    const userPrefs = await getUserNotificationPreferences(supabase, receiver_user_id)
    
    // Check if user has notifications enabled for this type
    if (!isNotificationAllowed(userPrefs, notification_type || 'message')) {
      return {
        success: false,
        message: 'User has disabled this type of notification',
        devices_reached: 0
      }
    }

    // Get all active devices for the user
    const devices = await getUserDevices(supabase, receiver_user_id)
    
    if (devices.length === 0) {
      return {
        success: false,
        message: 'No active devices found for user',
        devices_reached: 0
      }
    }

    // Prepare FCM tokens
    const fcmTokens = devices
      .map(device => device.fcm_token)
      .filter(token => token && token.length > 0)

    if (fcmTokens.length === 0) {
      return {
        success: false,
        message: 'No valid FCM tokens found',
        devices_reached: 0
      }
    }

    // Send notifications via Firebase Admin SDK
    const fcmResult = await sendFCMNotification(firebaseServiceAccount, {
      tokens: fcmTokens,
      title,
      body,
      data: {
        type: notification_type || 'message',
        timestamp: new Date().toISOString(),
        ...data
      },
      priority: priority || 'high',
      sound: custom_sound || userPrefs.sound || 'default',
      badge: badge_count || 1
    })

    // Update device tokens if some failed
    await updateInvalidTokens(supabase, devices, fcmResult)

    // Log notification for analytics
    await logNotification(supabase, {
      receiver_user_id,
      title,
      body,
      notification_type: notification_type || 'message',
      devices_targeted: devices.length,
      devices_reached: fcmResult.success,
      fcm_response: fcmResult
    })

    return {
      success: fcmResult.success > 0,
      message: `Notification sent to ${fcmResult.success}/${fcmTokens.length} devices`,
      devices_reached: fcmResult.success,
      devices_failed: fcmResult.failure,
      device_count: devices.length,
      success_count: fcmResult.success
    }

  } catch (error) {
    console.error('❌ Error sending push notification:', error)
    throw error
  }
}

/**
 * Send FCM notification using Firebase Admin SDK with OAuth 2.0
 */
async function sendFCMNotification(firebaseServiceAccount: any, payload: {
  tokens: string[]
  title: string
  body: string
  data: Record<string, any>
  priority: string
  sound: string
  badge: number
}): Promise<FCMResponse> {
  const { tokens, title, body, data, priority, sound, badge } = payload

  try {
    // Get OAuth 2.0 access token
    const accessToken = await getFirebaseAccessToken(firebaseServiceAccount)
    
    // Send notifications using the new FCM HTTP v1 API
    const results = []
    let successCount = 0
    let failureCount = 0
    
    for (const token of tokens) {
      try {
        const fcmPayload = {
          message: {
            token: token,
            notification: {
              title,
              body
            },
            data: Object.fromEntries(
              Object.entries(data).map(([key, value]) => [key, String(value)])
            ),
            android: {
              priority: priority === 'high' ? 'high' : 'normal',
              notification: {
                sound,
                notification_count: badge
              }
            },
            apns: {
              payload: {
                aps: {
                  alert: {
                    title,
                    body
                  },
                  sound,
                  badge
                }
              }
            }
          }
        }

        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${firebaseServiceAccount.project_id}/messages:send`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${accessToken}`
            },
            body: JSON.stringify(fcmPayload)
          }
        )

        if (response.ok) {
          const result = await response.json()
          results.push({ message_id: result.name })
          successCount++
        } else {
          const error = await response.text()
          console.error(`FCM error for token ${token}:`, error)
          
          // Parse common errors
          let errorType = 'UnknownError'
          if (error.includes('NOT_FOUND') || error.includes('UNREGISTERED')) {
            errorType = 'NotRegistered'
          } else if (error.includes('INVALID_ARGUMENT')) {
            errorType = 'InvalidRegistration'
          }
          
          results.push({ error: errorType })
          failureCount++
        }
      } catch (tokenError) {
        console.error(`Error sending to token ${token}:`, tokenError)
        results.push({ error: 'NetworkError' })
        failureCount++
      }
    }

    return {
      success: successCount,
      failure: failureCount,
      canonical_ids: 0,
      multicast_id: Date.now(),
      results
    }

  } catch (error) {
    console.error('FCM sending error:', error)
    throw new Error(`FCM request failed: ${error.message}`)
  }
}

/**
 * Get Firebase access token using service account
 */
async function getFirebaseAccessToken(serviceAccount: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const claim = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now
  }

  // Create JWT header
  const header = {
    alg: 'RS256',
    typ: 'JWT'
  }

  // Encode header and claim
  const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const encodedClaim = btoa(JSON.stringify(claim)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

  // Create signature using RSA-SHA256
  const message = `${encodedHeader}.${encodedClaim}`
  const signature = await signJWT(message, serviceAccount.private_key)
  
  const jwt = `${message}.${signature}`

  // Exchange JWT for access token
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt
    })
  })

  if (!response.ok) {
    throw new Error(`Failed to get access token: ${response.status}`)
  }

  const tokenData = await response.json()
  return tokenData.access_token
}

/**
 * Sign JWT using RSA-SHA256
 */
async function signJWT(message: string, privateKey: string): Promise<string> {
  // Import the private key
  const key = await crypto.subtle.importKey(
    'pkcs8',
    new TextEncoder().encode(privateKey.replace(/\\n/g, '\n')),
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256'
    },
    false,
    ['sign']
  )

  // Sign the message
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(message)
  )

  // Convert to base64url
  return btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
}

/**
 * Get user's active devices
 */
async function getUserDevices(supabase: any, userId: string) {
  const { data, error } = await supabase
    .from('user_devices')
    .select('id, fcm_token, device_type, is_active, last_seen')
    .eq('user_id', userId)
    .eq('is_active', true)
    .not('fcm_token', 'is', null)

  if (error) {
    console.error('❌ Error fetching user devices:', error)
    return []
  }

  return data || []
}

/**
 * Get user's notification preferences
 */
async function getUserNotificationPreferences(supabase: any, userId: string) {
  const { data, error } = await supabase
    .from('user_notification_preferences')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle()

  if (error) {
    console.error('❌ Error fetching notification preferences:', error)
  }

  // Default preferences if none found
  return data || {
    messages: true,
    achievements: true,
    support: true,
    system: true,
    friend_requests: true,
    pet_interactions: true,
    sound: 'default',
    vibrate: true,
    quiet_hours_enabled: false,
    quiet_hours_start: '22:00',
    quiet_hours_end: '08:00'
  }
}

/**
 * Check if notification type is allowed for user
 */
function isNotificationAllowed(preferences: any, notificationType: string): boolean {
  // Check quiet hours
  if (preferences.quiet_hours_enabled) {
    const now = new Date()
    const currentTime = now.toTimeString().slice(0, 5) // HH:MM format
    
    if (currentTime >= preferences.quiet_hours_start || currentTime <= preferences.quiet_hours_end) {
      // During quiet hours, only allow high priority notifications
      const allowedDuringQuietHours = ['support', 'system']
      if (!allowedDuringQuietHours.includes(notificationType)) {
        return false
      }
    }
  }

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

/**
 * Update invalid FCM tokens
 */
async function updateInvalidTokens(supabase: any, devices: any[], fcmResult: FCMResponse) {
  if (fcmResult.results) {
    for (let i = 0; i < fcmResult.results.length; i++) {
      const result = fcmResult.results[i]
      
      if (result.error) {
        const device = devices[i]
        
        // Handle different FCM errors
        if (result.error === 'NotRegistered' || result.error === 'InvalidRegistration') {
          // Mark device as inactive
          await supabase
            .from('user_devices')
            .update({ is_active: false, updated_at: new Date().toISOString() })
            .eq('id', device.id)
            
          console.log(`📱 Marked device ${device.id} as inactive due to: ${result.error}`)
        }
        
        if (result.registration_id) {
          // Update token if FCM provided a new one
          await supabase
            .from('user_devices')
            .update({ 
              fcm_token: result.registration_id,
              updated_at: new Date().toISOString()
            })
            .eq('id', device.id)
            
          console.log(`🔄 Updated FCM token for device ${device.id}`)
        }
      }
    }
  }
}

/**
 * Log notification for analytics
 */
async function logNotification(supabase: any, logData: {
  receiver_user_id: string
  title: string
  body: string
  notification_type: string
  devices_targeted: number
  devices_reached: number
  fcm_response: any
}) {
  try {
    await supabase.from('notification_logs').insert({
      receiver_user_id: logData.receiver_user_id,
      sender_username: logData.fcm_response?.data?.sender || 'System',
      title: logData.title,
      body: logData.body,
      notification_type: logData.notification_type,
      device_count: logData.devices_targeted,
      success_count: logData.devices_reached,
      notification_data: logData.fcm_response?.data || {},
      created_at: new Date().toISOString()
    })
  } catch (error) {
    console.error('❌ Error logging notification:', error)
  }
}

/**
 * Store scheduled notification
 */
async function storeScheduledNotification(supabase: any, request: NotificationRequest) {
  try {
    await supabase.from('scheduled_notifications').insert({
      receiver_user_id: request.receiver_user_id,
      title: request.title,
      body: request.body,
      data: request.data || {},
      notification_type: request.notification_type || 'message',
      scheduled_for: request.schedule_time,
      created_at: new Date().toISOString(),
      status: 'pending'
    })
  } catch (error) {
    console.error('❌ Error storing scheduled notification:', error)
    throw error
  }
}
