# Findora Backend

Node.js API backend for the Findora Flutter app.

## Setup

```sh
npm install
cp .env.example .env
npm run dev
```

The API starts on `http://localhost:5000` by default.
Make sure MongoDB is running and `MONGODB_URI` in `.env` points to your database.

## Scripts

- `npm run dev` starts the API with `nodemon`.
- `npm start` starts the API with Node.js.
- `npm run check` checks JavaScript syntax.

## Endpoints

- `GET /api/health` returns API status.
- `POST /api/auth/register` creates a user and returns a JWT.
- `POST /api/auth/login` logs in a user and returns a JWT.
- `POST /api/auth/logout` revokes the current user's active JWTs.
- `POST /api/auth/forgot-password` creates a password reset OTP.
- `POST /api/auth/reset-password` resets a password with an OTP.
- `POST /api/auth/verify-otp` verifies a registration OTP.
- `POST /api/auth/resend-otp` creates a new registration OTP.
- `GET /api/auth/me` returns the authenticated user for a Bearer token.
- `GET /api/users/me` returns the authenticated user's profile.
- `GET /api/users/me/profile-summary` returns profile data plus profile page stats.
- `PATCH /api/users/me` updates profile fields.
- `PATCH /api/users/me/avatar` updates avatar URL.
- `PATCH /api/users/me/password` updates password.
- `PATCH /api/users/me/preferences` updates settings/preferences.
- `DELETE /api/users/me` deletes the authenticated user's account.
- `GET /api/items` lists public unresolved items with filters.
- `GET /api/items/nearby` lists nearby unresolved items by coordinates.
- `GET /api/items/me` lists the authenticated user's posts.
- `GET /api/items/:id` returns one item.
- `POST /api/items` creates a lost or found item.
- `PATCH /api/items/:id` updates an owned item.
- `DELETE /api/items/:id` deletes an owned item.
- `POST /api/items/:id/resolve` marks an owned item resolved.
- `POST /api/items/:id/images` adds image URLs to an owned item.
- `GET /api/chats` lists the authenticated user's chat conversations.
- `GET /api/chats/:chatId` returns one conversation (participants or admin).
- `GET /api/chats/:chatId/messages` lists messages, `?after=<ms>` for polling.
- `POST /api/chats/:chatId/messages` sends a message (403 if chat disabled).
- `GET /api/admin/chats` lists all conversations (admin).
- `PATCH /api/admin/chats/:chatId/status` enables/disables a conversation (admin).
- `POST /api/admin/chats/claim/:claimId` unlocks chat for an approved claim (admin).

### Register

```json
{
  "fullName": "Hajira Gul",
  "email": "hajira@example.com",
  "phone": "+923001234567",
  "cityOrUniversity": "Islamabad",
  "password": "Password1"
}
```

### Forgot Password

```json
{
  "email": "hajira@example.com"
}
```

### Reset Password

```json
{
  "email": "hajira@example.com",
  "otp": "123456",
  "password": "Password2"
}
```

### Verify OTP

```json
{
  "email": "hajira@example.com",
  "otp": "123456"
}
```

### Resend OTP

```json
{
  "email": "hajira@example.com"
}
```

In development, OTP responses include the generated `otp` value so the app can
be tested before an email or SMS provider is connected. Production responses do
not include OTP values.

To send OTP emails through Gmail SMTP, set these environment variables:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_gmail@gmail.com
SMTP_PASS=your_gmail_app_password
SMTP_FROM=Findora <your_gmail@gmail.com>
```

To upload item images through Cloudinary, set these environment variables:

```env
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

### Login

```json
{
  "email": "hajira@example.com",
  "password": "Password1"
}
```

### Update Profile

```json
{
  "fullName": "Hajira Gul",
  "email": "hajira@example.com",
  "phone": "+923001234567",
  "cityOrUniversity": "IIU Islamabad",
  "about": "Software Engineering student passionate about campus communities."
}
```

### Profile Summary

```txt
GET /api/users/me/profile-summary
```

```json
{
  "user": {
    "id": "66f...",
    "fullName": "Hajira Gul",
    "cityOrUniversity": "IIU Islamabad",
    "avatarUrl": "https://example.com/avatar.jpg",
    "about": "Software Engineering student passionate about campus communities."
  },
  "stats": {
    "posts": 24,
    "claims": 11,
    "matches": 7
  }
}
```

### Update Avatar

```json
{
  "avatarUrl": "https://example.com/avatar.jpg"
}
```

### Update Password

```json
{
  "currentPassword": "Password1",
  "newPassword": "Password2"
}
```

### Update Preferences

```json
{
  "notifications": true,
  "darkMode": false,
  "twoFactor": true,
  "biometric": false
}
```

### Create Item

```json
{
  "title": "Black Wallet",
  "description": "Lost near CS Department. Brown leather wallet with cards.",
  "category": "Bags",
  "status": "lost",
  "color": "Black",
  "location": {
    "address": "IIU Main Gate, Islamabad",
    "latitude": 33.7215,
    "longitude": 73.0433
  },
  "reward": {
    "enabled": true,
    "amount": 1000
  },
  "handoverMethod": "Police Station",
  "contactInfo": "+92 300 1234567",
  "images": ["data:image/jpeg;base64,..."]
}
```

### List Items

```txt
GET /api/items?status=lost&category=Bags&q=wallet&page=1&limit=20
GET /api/items/nearby?lat=33.7215&lng=73.0433&radiusKm=1&sort=distance
```

### Add Item Images

```json
{
  "imageUrls": ["data:image/jpeg;base64,..."]
}
```

The API uploads selected images to Cloudinary and stores the resulting
Cloudinary `secure_url` values in `images`. It also stores Cloudinary
`public_id` values in `imagePublicIds` so images can be managed later.

## Included Packages

- `express` for the API server.
- `mongoose` for MongoDB.
- `dotenv` for environment variables.
- `cors`, `helmet`, and `express-rate-limit` for API protection.
- `morgan` for request logging.
- `bcryptjs` and `jsonwebtoken` for future authentication features.
- `nodemon` for local development.
