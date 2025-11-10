🎟️ Eventifyy — Flutter Event Booking App

<!--
NOTE: These badges are placeholders. You will need to set up GitHub Actions
and other services to generate real, dynamic badge links.
-->

Eventifyy is a modern cross-platform event booking application built with Flutter and powered by Firebase. It allows users to browse, book, and manage events, featuring secure authentication and real-time data sync.

🚀 Features

🔐 Secure Authentication: Firebase Email/Password and Google Sign-In.

🗓️ Dynamic Event Management: Users can browse and book events dynamically.

💾 Local Persistence: Data caching using Shared Preferences for speed.

☁️ Web Deployment Ready: Configured for deployment via Firebase Hosting.

🎨 Clean UI: Responsive and intuitive Flutter user interface.

🧱 Scalable Architecture: Built with structure for easy future expansion.

🧩 Tech Stack

Technology

Purpose

Flutter

Cross-platform mobile & web development

Dart

Programming language

Firebase Auth

User authentication

Firestore

Real-time database

Firebase Storage

Profile image handling

Shared Preferences

Local data persistence

GitHub Actions

CI/CD for automated deploys

🛠️ Setup Instructions

1️⃣ Clone the Repository

git clone [https://github.com/Rajeevgithu/Eventifyy-App.git](https://github.com/Rajeevgithu/Eventifyy-App.git)
cd Eventifyy-App


2️⃣ Install Dependencies

flutter pub get


3️⃣ Add Firebase Configuration Files

You must manually configure Firebase for your project.

Generate firebase_options.dart:

flutterfire configure


Required files to add (but not commit):

android/app/google-services.json

ios/Runner/GoogleService-Info.plist

lib/firebase_options.dart

⚠️ Security Note: Verify these files are ignored in .gitignore.

🌍 Environment Variables

For secrets (like Stripe keys or API tokens), create a .env file in the project root:

touch .env


Example .env:

STRIPE_SECRET_KEY=sk_test_*****************************
API_BASE_URL=[https://your-api-url.com](https://your-api-url.com)


⚠️ The .env file is already ignored in .gitignore—never commit secrets to your repository.

💻 Running the App

Run on Android / iOS:

flutter run


Run on Web:

flutter run -d chrome


☁️ Deployment & CI/CD

Firebase Hosting Deployment

Step 1 — Initialize Firebase (first time only):

firebase init


Choose:

Hosting

Existing project → event-booking-app-1fa34

Public directory → build/web

Configure as SPA → Yes

GitHub Workflow → Optional (but recommended for auto-deploy)

Step 2 — Build the Web App:

flutter build web


Step 3 — Deploy to Firebase:

firebase deploy --only hosting


🌐 Live URL

Once deployed, visit your live web application:

👉 https://event-booking-app-1fa34.web.app

🔄 GitHub Actions (Automatic Deploy)

If you chose to set up GitHub workflow during firebase init, a file is created at:

.github/workflows/firebase-hosting-merge.yml

This workflow automatically:

Builds your Flutter web app on push to main.

Deploys it to Firebase Hosting.

To manually trigger the workflow, push your changes:

git add .
git commit -m "feat: Add new feature and deploy"
git push origin main


🧪 Deployment Shortcut

Use this one-liner for a quick rebuild and redeploy:

flutter build web && firebase deploy --only hosting


🧱 Folder Structure

.
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── pages/
│   │    ├── splash_screen.dart
│   │    ├── login.dart
│   │    ├── bottomnav.dart
│   │    └── ... (home, profile, booking)
│   ├── services/
│   │    ├── auth.dart
│   │    ├── database.dart
│   │    └── shared_pref.dart
├── assets/
│   └── images/
├── pubspec.yaml
└── README.md


🧹 Git & Security Best Practices

Verify Sensitive Files Are Ignored:

git check-ignore -v android/app/google-services.json
git check-ignore -v lib/firebase_options.dart
git check-ignore -v .env


If you accidentally committed secrets (Banned practice):
You must use tools like git filter-repo to clean your history:

git filter-repo --path .env --path-glob '.env*' --invert-paths --force


Never store API keys in source files. Use .env or Firebase Remote Config instead.

🔧 Useful Commands

Command

Description

flutter clean

Clean build cache

flutter pub get

Get dependencies

flutter run

Run app on connected device

flutter build web

Build production web bundle

firebase deploy

Deploy to Firebase Hosting

firebase login

Log in to Firebase account

✍️ Author & License

Author

Rajeev

📧 your-email@example.com

🌐 https://github.com/Rajeevgithu

License

This project is licensed under the MIT License — feel free to use and modify with attribution.
