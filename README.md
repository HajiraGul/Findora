# Findora

> A cross-platform lost-and-found platform built as a Final Year Project (FYP) that helps people recover lost items through real-time messaging, geolocation search, and push notifications.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Node.js](https://img.shields.io/badge/Node.js-22.x-339933?logo=node.js)
![MongoDB](https://img.shields.io/badge/MongoDB-8.x-47A248?logo=mongodb)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Table of Contents

- [About](#about)
- [FYP Overview](#fyp-overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Backend Setup](#backend-setup)
  - [Flutter App Setup](#flutter-app-setup)
  - [Firebase Functions Setup](#firebase-functions-setup)
- [Environment Variables](#environment-variables)
- [API Endpoints](#api-endpoints)
- [Firestore Security Rules](#firestore-security-rules)
- [Running the App](#running-the-app)

---

## About

**Findora** is a full-stack lost-and-found application developed as a **Final Year Project (FYP)**. The platform bridges the gap between people who lose items and those who find them by providing a centralized digital space for reporting, searching, and recovering lost belongings. Users can report lost or found items, browse nearby incidents on an interactive map, chat in real time with other users, and receive instant push notifications when someone responds.

### How it works

1. A user posts a **lost** or **found** item with photos, location, and optional reward.
2. Other users can browse, filter, and search items by category, status, or proximity.
3. When two users want to coordinate a return, they open a **chat** conversation.
4. A Firebase Cloud Function sends **push notifications** to the recipient on every new message.
5. An admin can enable/disable chats and approve **claims** to unlock conversations.

---

## FYP Overview

Findora was designed and developed as a **Final Year Project** in Software Engineering. The project demonstrates end-to-end full-stack development skills across mobile, backend, and cloud services. It addresses a real-world problem — the inefficiency of recovering lost items in campus and urban environments — by combining modern technologies into a single cohesive platform.

### FYP Objectives

- Design and implement a cross-platform mobile application for lost-and-found reporting
- Build a secure and scalable RESTful API backend with Node.js and Express
- Integrate real-time chat functionality using Firebase Firestore
- Implement push notification delivery for instant user engagement
- Provide geolocation-based search to find items near a specific location
- Apply security best practices including JWT authentication, OTP verification, and Firestore rules

### FYP Features Delivered

- Complete user authentication system with registration, login, OTP email verification, and password reset
- Lost and found item CRUD with image upload, category filtering, and status management
- Real-time one-to-one messaging between users for item recovery coordination
- Push notifications via Firebase Cloud Messaging triggered by Cloud Functions
- Interactive map view using flutter_map with geolocation and geocoding support
- Nearby items search based on device coordinates and configurable radius
- User profile management with avatar, preferences, and activity statistics
- Admin endpoints for chat moderation and claim-based chat unlocking
- Firestore security rules for data protection at the database level
- Cloudinary integration for scalable image storage and delivery

---

## Key Features

| Feature | Description |
| --- | --- |
| **Cross-Platform App** | Single Flutter codebase runs on Android, iOS, Web, Windows, macOS, and Linux |
| **JWT Authentication** | Secure token-based auth with OTP email verification via Nodemailer |
| **Real-Time Chat** | Firestore-powered messaging with live updates and message polling |
| **Push Notifications** | FCM notifications delivered instantly via Firebase Cloud Functions |
| **Geolocation Search** | Find items near you using device GPS with configurable search radius |
| **Interactive Map** | Visualize lost and found items on a map with flutter_map |
| **Image Upload** | Upload item photos through Cloudinary for reliable image hosting |
| **Profile and Stats** | Track posts, claims, and matches with a personal dashboard |
| **Admin Controls** | Enable/disable chats and approve claims through admin API endpoints |
| **Secure by Design** | Helmet, CORS, rate limiting, Firestore rules, and shadow-auth scheme |

---

## Architecture

```
+------------------------+
|     Flutter App        |
|   (GetX + Firebase)    |
+----------+-------------+
           | REST API
           v
+------------------------+
|   Node.js / Express    |---- MongoDB
|     Backend API        |---- Cloudinary
|                        |---- Nodemailer (SMTP)
+----------+-------------+
           | Admin SDK
           v
+------------------------+
|     Firebase           |---- Firestore (realtime chat)
|   Cloud Functions      |---- FCM (push notifications)
|   Security Rules       |
+------------------------+
```

---

## Tech Stack

| Layer | Technology |
| --- | --- |
| **Mobile** | Flutter 3.x, Dart, GetX (state management) |
| **Backend** | Node.js 22, Express 4, Mongoose 8 |
| **Database** | MongoDB |
| **Auth** | JWT (bcryptjs, jsonwebtoken), Firebase Auth (shadow) |
| **Realtime Chat** | Cloud Firestore |
| **Push** | Firebase Cloud Messaging (FCM) via Cloud Functions |
| **Images** | Cloudinary |
| **Email/OTP** | Nodemailer (Gmail SMTP) |
| **Maps** | flutter_map, geolocator, geocoding, latlong2 |
| **Deployment** | Vercel (frontend), Firebase (functions + Firestore) |

---

## Project Structure

```
Findora/
├── backend/                    # Node.js REST API
│   ├── src/
│   │   ├── config/             # Database, Cloudinary, Firebase config
│   │   ├── controllers/        # Auth, chat, item, user controllers
│   │   ├── middleware/          # Auth and error middleware
│   │   ├── models/             # Mongoose schemas (User, Item, Claim)
│   │   ├── routes/             # Express route definitions
│   │   ├── services/           # Business logic (auth, chat, claim, image, item, mail, user)
│   │   ├── utils/              # Validators, JWT helpers
│   │   ├── app.js              # Express app setup
│   │   └── server.js           # Entry point
│   ├── .env.example
│   ├── package.json
│   └── README.md
│
├── findora/                    # Flutter mobile application
│   ├── lib/
│   │   ├── bindings/           # GetX dependency injection
│   │   ├── config/             # App configuration
│   │   ├── controllers/        # GetX controllers
│   │   ├── models/             # Dart data models
│   │   ├── routes/             # Named route definitions
│   │   ├── screens/            # UI screens
│   │   ├── services/           # API and Firebase service layer
│   │   ├── utils/              # Helpers and constants
│   │   ├── widgets/            # Reusable UI components
│   │   └── main.dart           # App entry point
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── windows/
│   ├── macos/
│   ├── linux/
│   ├── pubspec.yaml
│   └── run.sh / run.bat
│
├── functions/                  # Firebase Cloud Functions
│   ├── index.js                # onNewChatMessage trigger
│   └── package.json
│
├── firebase.json               # Firebase project config
├── firestore.rules             # Firestore security rules
└── README.md
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.x)
- [Node.js](https://nodejs.org/) 22.x
- [MongoDB](https://www.mongodb.com/) running locally or an Atlas URI
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- A [Cloudinary](https://cloudinary.com/) account (for image uploads)
- A Gmail account with an [App Password](https://support.google.com/accounts/answer/185833) (for OTP emails)

### Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create your environment file
cp .env.example .env

# Edit .env with your actual values (see Environment Variables below)

# Start the development server
npm run dev
```

The API starts on **http://localhost:5000** by default.

### Flutter App Setup

```bash
cd findora

# Install Flutter dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

For web:
```bash
flutter run -d chrome
```

### Firebase Functions Setup

```bash
cd functions

# Install dependencies
npm install

# Deploy to Firebase (requires firebase login first)
firebase deploy --only functions
```

---

## Environment Variables

Copy `backend/.env.example` to `backend/.env` and fill in:

```env
# Server
NODE_ENV=development
PORT=5000
CORS_ORIGIN=*

# MongoDB
MONGODB_URI=mongodb://127.0.0.1:27017/findora

# JWT
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRES_IN=7d

# OTP
OTP_TTL_MINUTES=10

# SMTP (Gmail)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_gmail@gmail.com
SMTP_PASS=your_gmail_app_password
SMTP_FROM=Findora <your_gmail@gmail.com>

# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# Firebase Admin SDK
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_SERVICE_ACCOUNT_PATH=/absolute/path/to/service-account.json
```

---

## API Endpoints

### Auth

| Method | Endpoint | Description |
| --- | --- | --- |
| POST | `/api/auth/register` | Register a new user |
| POST | `/api/auth/login` | Login and receive a JWT |
| POST | `/api/auth/logout` | Revoke active JWT |
| POST | `/api/auth/forgot-password` | Generate password-reset OTP |
| POST | `/api/auth/reset-password` | Reset password with OTP |
| POST | `/api/auth/verify-otp` | Verify registration OTP |
| POST | `/api/auth/resend-otp` | Resend registration OTP |
| GET | `/api/auth/me` | Get current authenticated user |

### Users

| Method | Endpoint | Description |
| --- | --- | --- |
| GET | `/api/users/me` | Get user profile |
| GET | `/api/users/me/profile-summary` | Profile with stats |
| PATCH | `/api/users/me` | Update profile fields |
| PATCH | `/api/users/me/avatar` | Update avatar URL |
| PATCH | `/api/users/me/password` | Change password |
| PATCH | `/api/users/me/preferences` | Update settings |
| DELETE | `/api/users/me` | Delete account |

### Items

| Method | Endpoint | Description |
| --- | --- | --- |
| GET | `/api/items` | List public unresolved items |
| GET | `/api/items/nearby` | Nearby items by coordinates |
| GET | `/api/items/me` | Current user's posts |
| GET | `/api/items/:id` | Get single item |
| POST | `/api/items` | Create a lost/found item |
| PATCH | `/api/items/:id` | Update owned item |
| DELETE | `/api/items/:id` | Delete owned item |
| POST | `/api/items/:id/resolve` | Mark item as resolved |
| POST | `/api/items/:id/images` | Add images to an item |

### Chats

| Method | Endpoint | Description |
| --- | --- | --- |
| GET | `/api/chats` | List user's conversations |
| GET | `/api/chats/:chatId` | Get single conversation |
| GET | `/api/chats/:chatId/messages` | List messages (`?after=<ms>`) |
| POST | `/api/chats/:chatId/messages` | Send a message |

### Admin

| Method | Endpoint | Description |
| --- | --- | --- |
| GET | `/api/admin/chats` | List all conversations |
| PATCH | `/api/admin/chats/:chatId/status` | Enable/disable a chat |
| POST | `/api/admin/chats/claim/:claimId` | Unlock chat for approved claim |

---

## Firestore Security Rules

The `firestore.rules` file enforces:

- **Chat read**: Any signed-in device can read chat documents.
- **Chat write**: Only the backend Admin SDK writes chat metadata.
- **Message create**: Signed-in users can append messages (text <= 2000 chars, optional HTTPS image URL) only while the chat is enabled.
- **Message update/delete**: Not permitted for clients.
- **Device tokens**: Clients write their own FCM tokens; only Admin SDK reads them.

> **Note:** The app currently uses a shared Firebase credential (shadow-auth). For true per-user enforcement, mint Firebase custom tokens on the backend with `uid == Mongo _id`.

---

## Running the App

1. Start **MongoDB** locally.
2. Start the **backend**: `cd backend && npm run dev`
3. Run the **Flutter app**: `cd findora && flutter run`
4. (Optional) Deploy **Cloud Functions**: `firebase deploy --only functions`

The Vercel deployment is at [findora-nine.vercel.app](https://findora-nine.vercel.app).

---

## License

MIT
