import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { create, getNumericDate, decode } from 'https://deno.land/x/djwt@v2.8/mod.ts'; // For JWT signing

// Initialize Supabase client
const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '' // Use service role key for database access
);

// Google Service Account Key from Supabase secrets
const GOOGLE_SERVICE_ACCOUNT_KEY_JSON = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_KEY');

if (!GOOGLE_SERVICE_ACCOUNT_KEY_JSON) {
  console.error('GOOGLE_SERVICE_ACCOUNT_KEY is not set in Supabase secrets.');
}

let googleServiceAccount: any;
try {
  googleServiceAccount = JSON.parse(GOOGLE_SERVICE_ACCOUNT_KEY_JSON || '{}');
} catch (e) {
  console.error('Error parsing GOOGLE_SERVICE_ACCOUNT_KEY_JSON:', e);
}

// Function to generate OAuth 2.0 access token
async function getAccessToken(): Promise<string> {
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };

  const payload = {
    iss: googleServiceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: getNumericDate(3600), // Expires in 1 hour
    iat: getNumericDate(0),
  };

  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    new TextEncoder().encode(googleServiceAccount.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signedJwt = await create(header, payload, privateKey);

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: signedJwt,
    }).toString(),
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Failed to get access token: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

serve(async (req) => {
  try {
    // Calculate time window for tasks due in the next hour
    const now = new Date();
    const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000); // 1 hour in milliseconds

    // Query for tasks due in the next hour
    const { data: tasks, error: tasksError } = await supabase
      .from('todos')
      .select('id, title, user_id, deadline')
      .eq('completed', false) // Only consider incomplete tasks
      .gte('deadline', now.toISOString())
      .lte('deadline', oneHourFromNow.toISOString());

    if (tasksError) {
      console.error('Error fetching tasks:', tasksError);
      return new Response(`Error fetching tasks: ${tasksError.message}`, { status: 500 });
    }

    if (!tasks || tasks.length === 0) {
      return new Response('No tasks due in the next hour.', { status: 200 });
    }

    const accessToken = await getAccessToken();

    for (const task of tasks) {
      // Fetch FCM token for each user
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('fcm_token')
        .eq('id', task.user_id)
        .single();

      if (profileError || !profile || !profile.fcm_token) {
        console.error(`Error fetching FCM token for user ${task.user_id}:`, profileError?.message || 'Token not found');
        continue; // Skip to the next task
      }

      const fcmToken = profile.fcm_token;

      // Construct FCM message payload
      const message = {
        to: fcmToken,
        notification: {
          title: 'Task Reminder!',
          body: `Your task "${task.title}" is due at ${new Date(task.deadline).toLocaleTimeString()}.`,
        },
        data: {
          task_id: task.id,
          user_id: task.user_id,
          // Add any other custom data you want to send
        },
      };

      // Send FCM message
      const fcmResponse = await fetch(`https://fcm.googleapis.com/v1/projects/${googleServiceAccount.project_id}/messages:send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({ message: message }),
      });

      const fcmResult = await fcmResponse.json();

      if (!fcmResponse.ok) {
        console.error(`FCM send failed for task ${task.id}:`, fcmResult);
      } else {
        console.log(`FCM message sent successfully for task ${task.id}:`, fcmResult);
      }
    }

    return new Response('Scheduled reminders processed.', { status: 200 });

  } catch (error) {
    console.error('Error processing scheduled reminders:', error);
    return new Response(`Error: ${error.message}`, { status: 500 });
  }
});

// --- MANUAL STEPS REQUIRED AFTER THIS ---
// 1. Deploy the Edge Function:
//    - Save this code as a TypeScript file (e.g., 'schedule-reminders.ts').
//    - Use the Supabase CLI to deploy it: `supabase functions deploy schedule-reminders --no-verify-jwt`
// 2. Set up pg_cron job:
//    - In your Supabase SQL Editor, run the following SQL to schedule this function to run every 5 minutes:
//      SELECT cron.schedule(
//        'schedule-reminders-job', -- unique name of the job
//        '*/5 * * * *',            -- cron schedule (every 5 minutes)
//        'SELECT net.http_post(
//           url: "https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/schedule-reminders",
//           headers: "{"Authorization": "Bearer YOUR_SUPABASE_ANON_KEY"}",
//           body: "{}"
//         );'
//      );
//    - Replace 'YOUR_SUPABASE_PROJECT_REF' with your actual Supabase project reference.
//    - Replace 'YOUR_SUPABASE_ANON_KEY' with your actual Supabase public anon key.