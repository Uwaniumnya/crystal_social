// Supabase Edge Function: send-onesignal-notification
// This function sends OneSignal notifications to specific player IDs
// Place this file in: supabase/functions/send-onesignal-notification/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface NotificationRequest {
  player_ids: string[];
  title: string;
  content: string;
  additional_data?: Record<string, any>;
}

interface NotificationResult {
  id: string;
  success: boolean;
  error?: string;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get environment variables with fallbacks
    const supabaseUrl = (globalThis as any).Deno?.env?.get('SUPABASE_URL') || '';
    const supabaseServiceKey = (globalThis as any).Deno?.env?.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    const oneSignalAppId = (globalThis as any).Deno?.env?.get('ONESIGNAL_APP_ID') || '';
    const oneSignalApiKey = (globalThis as any).Deno?.env?.get('ONESIGNAL_REST_API_KEY') || '';

    // Initialize Supabase client
    const supabaseClient = createClient(
      supabaseUrl,
      supabaseServiceKey,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    );

    // Get request data
    const requestData: NotificationRequest = await req.json();
    const { player_ids, title, content, additional_data } = requestData;

    if (!player_ids || player_ids.length === 0 || !title || !content) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: player_ids, title, content' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // Get OneSignal API Key from environment variables
    if (!oneSignalAppId || !oneSignalApiKey) {
      return new Response(
        JSON.stringify({ error: 'OneSignal configuration not found' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // Send notification via OneSignal REST API
    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${oneSignalApiKey}`,
      },
      body: JSON.stringify({
        app_id: oneSignalAppId,
        include_player_ids: player_ids,
        headings: { en: title },
        contents: { en: content },
        data: additional_data || {},
      }),
    });

    const result = await response.json();
    
    if (response.status >= 200 && response.status < 300 && result.id) {
      // Log the notification
      try {
        await supabaseClient.from('notification_logs').insert({
          sender_username: additional_data?.sender || 'System',
          title,
          body: content,
          device_count: player_ids.length,
          success_count: player_ids.length,
          notification_data: additional_data,
          onesignal_notification_id: result.id,
        });
      } catch (error) {
        console.error('Error logging notification:', error);
      }
      
      return new Response(
        JSON.stringify({
          message: `OneSignal notification sent successfully`,
          success: true,
          notification_id: result.id,
          player_count: player_ids.length,
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    } else {
      console.error('OneSignal API error:', result);
      return new Response(
        JSON.stringify({ 
          error: 'Failed to send notification via OneSignal',
          details: result.errors || result 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

  } catch (error) {
    console.error('Edge function error:', error);
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        details: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }
});
