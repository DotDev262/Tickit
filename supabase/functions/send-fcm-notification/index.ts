import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Initialize Supabase client (if needed to fetch data, though for this function, it's passed in)
const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Get Firebase Service Account from environment variable
const firebaseServiceAccountBase64 = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_BASE64");

if (!firebaseServiceAccountBase64) {
  console.error("FIREBASE_SERVICE_ACCOUNT_BASE64 environment variable not set.");
  Deno.exit(1);
}

// Decode the base64 string to get the service account JSON
const firebaseServiceAccount = JSON.parse(atob(firebaseServiceAccountBase64));

// Function to get an access token for FCM
async function getAccessToken() {
  const jwt = await new Response(
    await crypto.subtle.sign(
      { name: "RS256" },
      await crypto.subtle.importKey(
        "jwk",
        firebaseServiceAccount,
        { name: "RS256", hash: "SHA-256" },
        false,
        ["sign"],
      ),
      new TextEncoder().encode(
        JSON.stringify({
          iss: firebaseServiceAccount.client_email,
          scope: "https://www.googleapis.com/auth/firebase.messaging",
          aud: "https://oauth2.googleapis.com/token",
          exp: Math.floor(Date.now() / 1000) + 3600, // 1 hour expiration
          iat: Math.floor(Date.now() / 1000),
        }),
      ),
    ),
  ).text();

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await response.json();
  return data.access_token;
}

// Main handler for the Edge Function
serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  try {
    const { fcmToken, title, body, data } = await req.json();

    if (!fcmToken || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing fcmToken, title, or body" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const accessToken = await getAccessToken();

    const message = {
      message: {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: data, // Optional data payload
      },
    };

    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${firebaseServiceAccount.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(message),
      },
    );

    const fcmResult = await fcmResponse.json();

    if (!fcmResponse.ok) {
      console.error("FCM Error:", fcmResult);
      return new Response(
        JSON.stringify({ error: "Failed to send FCM", details: fcmResult }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    console.log("Successfully sent FCM:", fcmResult);
    return new Response(JSON.stringify({ success: true, result: fcmResult }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Edge Function Error:", error);
    return new Response(
      JSON.stringify({ error: "Internal Server Error", details: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});