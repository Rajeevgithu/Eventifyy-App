🎟️ Eventifyy — Flutter Event Booking App

<!--
NOTE: These badges are placeholders. You will need to set up GitHub Actions
and other services to generate real, dynamic badge links.
-->
# 🎟️ Eventifyy — Flutter Event Booking App

> A modern cross-platform event booking application built with **Flutter** and powered by **Firebase**.  
> Browse, book, and manage events effortlessly — with secure authentication and real-time data sync.

---

## 🚀 Features

- 🔐 **Secure Authentication** — Firebase Email/Password & Google Sign-In  
- 🗓️ **Dynamic Event Management** — Browse and book events dynamically  
- 💾 **Local Persistence** — Shared Preferences for faster load times  
- ☁️ **Web Deployment Ready** — Built for Firebase Hosting  
- 🎨 **Clean UI** — Responsive, intuitive Flutter interface  
- 🧱 **Scalable Architecture** — Structured for future expansion  

---

## 🧩 Tech Stack

| Technology | Purpose |
|-------------|----------|
| **Flutter** | Cross-platform mobile & web development |
| **Dart** | Programming language |
| **Firebase Auth** | User authentication |
| **Firestore** | Real-time database |
| **Firebase Storage** | Profile image handling |
| **Shared Preferences** | Local data persistence |
| **GitHub Actions** | CI/CD for automated deploys |

---

## 🛠️ Setup Instructions

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/Rajeevgithu/Eventifyy-App.git
cd Eventifyy-App


2️⃣ Install Dependencies
flutter pub get

3️⃣ Configure Firebase

Generate the Firebase config file:

flutterfire configure


Add (but don’t commit) the following files:

android/app/google-services.json
ios/Runner/GoogleService-Info.plist
lib/firebase_options.dart


⚠️ Make sure these files are ignored in your .gitignore.

🌍 Environment Variables

Create a .env file in the project root:

touch .env


Example:

STRIPE_SECRET_KEY=sk_test_*****************************
API_BASE_URL=https://your-api-url.com


⚠️ .env is already ignored — never commit secrets.

💻 Running the App

Android / iOS:

flutter run


Web:

flutter run -d chrome

☁️ Deployment & CI/CD
Firebase Hosting Deployment

Step 1 — Initialize Firebase (first time only):

firebase init


Select:

✅ Hosting

✅ Existing project → event-booking-app-1fa34

📁 Public directory → build/web

🔁 Configure as SPA → Yes

⚙️ GitHub Workflow → Optional (recommended)

Step 2 — Build for Web:

flutter build web


Step 3 — Deploy:

firebase deploy --only hosting

🌐 Live URL

Once deployed:

👉 https://event-booking-app-1fa34.web.app

🔄 GitHub Actions (Auto Deployment)

If configured via firebase init, a workflow file is created at:

.github/workflows/firebase-hosting-merge.yml


This workflow:

🏗️ Builds your Flutter web app on push to main

☁️ Deploys automatically to Firebase Hosting

To trigger manually:

git add .
git commit -m "feat: Add new feature and deploy"
git push origin main

🧪 Deployment Shortcut
flutter build web && firebase deploy --only hosting

🧱 Folder Structure
.
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── pages/
│   │   ├── splash_screen.dart
│   │   ├── login.dart
│   │   ├── bottomnav.dart
│   │   └── ... (home, profile, booking)
│   ├── services/
│   │   ├── auth.dart
│   │   ├── database.dart
│   │   └── shared_pref.dart
├── assets/
│   └── images/
├── pubspec.yaml
└── README.md

🧹 Git & Security Best Practices
Verify Sensitive Files Are Ignored
git check-ignore -v android/app/google-services.json
git check-ignore -v lib/firebase_options.dart
git check-ignore -v .env

If Secrets Were Accidentally Committed

Clean your repo using:

git filter-repo --path .env --path-glob '.env*' --invert-paths --force


🚫 Never store API keys in source code.
✅ Use .env or Firebase Remote Config instead.

✍️ Author & License

Author

Rajeev

📧 your-email@example.com

🌐 https://github.com/Rajeevgithu

License

This project is licensed under the MIT License — feel free to use and modify with attribution.
