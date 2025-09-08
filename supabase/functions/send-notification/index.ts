import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Initialize Supabase client
const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '' // Use service role key for database access
);

// Firebase Cloud Messaging (FCM) server key from Supabase secrets
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY');

if (!FCM_SERVER_KEY) {
  console.error('FCM_SERVER_KEY is not set in Supabase secrets.');
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  try {
    const payload = await req.json();
    const record = payload.record; // The new or updated row from the database webhook

    if (!record || !record.user_id || !record.title) {
      return new Response('Invalid payload: missing user_id or title', { status: 400 });
    }

    const userId = record.user_id;
    const taskTitle = record.title;
    const taskId = record.id;

    // Fetch FCM token from the profiles table
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', userId)
      .single();

    if (profileError || !profile || !profile.fcm_token) {
      console.error('Error fetching FCM token or token not found:', profileError?.message || 'Token not found');
      return new Response('FCM token not found for user', { status: 404 });
    }

    const fcmToken = profile.fcm_token;

    // Construct FCM message payload
    const message = {
      to: fcmToken,
      notification: {
        title: 'New Task Added!',
        body: `You have a new task: ${taskTitle}`,
      },
      data: {
        task_id: taskId,
        user_id: userId,
        // Add any other custom data you want to send
      },
    };

    // Send FCM message
    const fcmResponse = await fetch('https://fcm.googleapis.com/v1/projects/tickit-f30e7/messages:send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${FCM_SERVER_KEY}`, // Use Bearer token for HTTP v1
      },
      body: JSON.stringify({ message: message }), // FCM HTTP v1 expects { message: ... }
    });

    const fcmResult = await fcmResponse.json();

    if (!fcmResponse.ok) {
      console.error('FCM send failed:', fcmResult);
      return new Response(`FCM send failed: ${JSON.stringify(fcmResult)}`, { status: 500 });
    }

    console.log('FCM message sent successfully:', fcmResult);
    return new Response('Notification sent!', { status: 200 });

  } catch (error) {
    console.error('Error processing request:', error);
    return new Response(`Error: ${error.message}`, { status: 500 });
  }
});

// --- MANUAL STEPS REQUIRED AFTER THIS ---
// 1. Replace 'YOUR_FIREBASE_PROJECT_ID' in the FCM endpoint URL with your actual Firebase project ID.
// 2. Set Supabase Secrets:
//    - Go to your Supabase project dashboard -> "Project Settings" -> "Secrets".
//    - Add a new secret named 'FCM_SERVER_KEY' and paste your Firebase Cloud Messaging server key.
//    - Ensure 'SUPABASE_URL' and 'SUPABASE_SERVICE_ROLE_KEY' are also set as secrets or environment variables.
// 3. Deploy the Edge Function:
//    - Save this code as a TypeScript file (e.g., 'send-notification.ts').
//    - Use the Supabase CLI to deploy it: `supabase functions deploy send-notification --no-verify-jwt`
// 4. Set up Database Webhook:
//    - In your Supabase project dashboard, go to "Database" -> "Webhooks".
//    - Create a new webhook for the 'todos' table (on INSERT, UPDATE events) and link it to the 'send-notification' function.
