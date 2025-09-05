// cron-script/index.js
const { createClient } = require('@supabase/supabase-js');
const fetch = require('node-fetch'); // For making HTTP requests

// Supabase credentials from GitHub Secrets
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

// URL of your deployed Supabase Edge Function
const EDGE_FUNCTION_URL = process.env.EDGE_FUNCTION_URL;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !EDGE_FUNCTION_URL) {
  console.error('Missing required environment variables.');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function checkAndSendReminders() {
  console.log('Running external reminder check...');

  const now = new Date();
  const oneHourFromNow = new Date(now.getTime() + (60 * 60 * 1000));
  const oneHourFiveMinutesFromNow = new Date(now.getTime() + (65 * 60 * 1000)); // A small window

  try {
    // Query Supabase for todos whose deadline is between 1 hour and 1 hour 5 minutes from now
    // and where notification_sent is false.
    const { data: todos, error: todosError } = await supabase
      .from('todos')
      .select('*')
      .gte('deadline', oneHourFromNow.toISOString())
      .lt('deadline', oneHourFiveMinutesFromNow.toISOString())
      .eq('notification_sent', false);

    if (todosError) {
      console.error('Error fetching todos:', todosError);
      return;
    }

    if (!todos || todos.length === 0) {
      console.log('No upcoming todos found for notification.');
      return;
    }

    console.log(`Found ${todos.length} todos to process.`);

    for (const todo of todos) {
      console.log(`Processing todo: ${todo.title} (ID: ${todo.id}) for user: ${todo.user_id}`);

      // Fetch the user's FCM token from the profiles table
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('fcm_token')
        .eq('id', todo.user_id)
        .single();

      if (profileError || !profile || !profile.fcm_token) {
        console.error(`Could not get FCM token for user ${todo.user_id}:`, profileError || 'FCM token not found.');
        continue; // Skip to the next todo
      }

      const fcmToken = profile.fcm_token;

      // Call the Supabase Edge Function to send FCM
      const response = await fetch(EDGE_FUNCTION_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          // You might need an API key for your Edge Function if you've secured it
          // 'Authorization': `Bearer YOUR_EDGE_FUNCTION_API_KEY`
        },
        body: JSON.stringify({
          fcmToken: fcmToken,
          title: 'Todo Reminder!',
          body: `Your todo "${todo.title}" is due in 1 hour!`,
          data: {
            todoId: todo.id,
            // Add more data here to help your app navigate
            // e.g., screen: "todo_details", id: todo.id
          },
        }),
      });

      const result = await response.json();

      if (!response.ok) {
        console.error('Error calling Edge Function:', result);
      } else {
        console.log('Edge Function call successful:', result);
        // Update the todo to mark notification as sent
        const { error: updateError } = await supabase
          .from('todos')
          .update({ notification_sent: true })
          .eq('id', todo.id);

        if (updateError) {
          console.error(`Error updating todo ${todo.id} notification_sent status:`, updateError);
        }
      }
    }
    console.log('Finished external reminder check.');
  } catch (overallError) {
    console.error('An unexpected error occurred in external script:', overallError);
  }
}

checkAndSendReminders();
