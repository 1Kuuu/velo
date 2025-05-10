# Firestore Rules Update Instructions

Follow these steps to update your Firestore security rules:

1. Open the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. In the left navigation menu, click on "Firestore Database"
4. Click on the "Rules" tab
5. Replace the existing rules with the updated rules from your `firestore.rules` file
6. Click "Publish" to deploy the rules

## What Changed?

The updated rules include:

1. Added proper security rules for the `notifications` collection:
   - Only the recipient can read their notifications
   - Any authenticated user can create notifications (must include their own user ID as sender)
   - Recipients can update notifications (e.g., to mark as read)
   - Recipients can delete their notifications

2. Added security rules for the `user_notification_settings` collection:
   - Users can only read/write their own notification settings

## Fixing the Permission Denied Error

The "permission-denied" error occurred because one or more collections being accessed in your app didn't have proper security rules defined. By implementing these missing rules, authenticated users should now be able to access the required collections with the appropriate permissions.

If you continue to experience permission denied errors, please check the app logs to identify which specific collection or operation is failing, and update the rules accordingly. 