# 🏥 MediTrack

> Your Personal Health Tracking & Medication Management Companion

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Backend-orange?logo=firebase)
![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart)
![HealthTech](https://img.shields.io/badge/Category-HealthTech-green)
![Status](https://img.shields.io/badge/Status-In%20Development-yellow)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## 📋 Overview

**MediTrack** is a comprehensive HealthTech mobile application designed to help individuals manage chronic health conditions, medication schedules, vital records, doctor visits, prescriptions, and emergency situations — all from a single platform.

MediTrack acts as a digital health companion that assists users in maintaining their healthcare routine through smart reminders, tracking systems, visual analytics, and PDF report generation.

> ⚠️ **Disclaimer:** MediTrack is not a diagnostic tool and does not provide medical advice. Its purpose is to improve health management, medication adherence, and record keeping.

---

## 🔍 Problem Statement

Millions of people with chronic illnesses — diabetes, hypertension, heart disease, asthma, post-surgery recovery — struggle to maintain their daily healthcare routines. Common challenges include:

- Forgetting medications or dosage schedules
- Inconsistent vital tracking
- Losing prescriptions and medical records
- Difficulty sharing health history with doctors
- Poor treatment adherence over time

Existing solutions often address only one aspect of healthcare management, forcing users to juggle multiple apps. **MediTrack solves this** by providing a centralized platform that unifies everything.

---

## ✨ Features

### 🔐 Authentication & Profile Management
- Secure registration and login
- Personal medical profile (blood group, allergies, existing conditions)
- Emergency contact storage

### 📊 Vital Tracking
Track and visualize key health metrics:
| Vital | Details |
|---|---|
| Blood Pressure | Systolic & Diastolic |
| Blood Sugar | Fasting & Post-meal |
| Body Temperature | Daily readings |
| Weight | Progress over time |
| SpO2 | Oxygen saturation |
| Heart Rate | Daily monitoring |

- Daily logging with weekly & monthly trend views
- Color-coded health indicators

### 💊 Medication Management
- Add, edit, and delete medicines
- Set dosage, frequency, start/end dates
- Supported frequencies: once daily, twice daily, three times daily, every X hours, custom

### 🔔 Smart Medication Reminders
- Scheduled push notifications
- Mark as Taken / Missed / Snooze actions
- Missed dose alerts

### 📈 Adherence Tracking
- Adherence percentage by week and month
- Missed dose counts and daily completion rates

### 🏥 Doctor Visit Management
- Log doctor name, hospital, date, consultation notes
- Track follow-up appointments

### 📄 Prescription Management
- Upload prescription images or PDFs (JPG, PNG, PDF)
- View and search past prescriptions

### 📉 Dashboard & Analytics
- Health overview with medication and vital summaries
- Line charts, bar charts, pie charts, and progress indicators

### 📑 PDF Health Report Generation
- Generate downloadable reports including vitals, medications, doctor visits, and prescriptions
- Ideal for doctor consultations and health reviews

### 🚨 Emergency SOS
- One-tap SOS trigger
- Shares location, blood group, conditions, allergies, and emergency contacts with designated people

---

## 🏗️ Architecture

```
Flutter UI
    │
    ▼
Providers / Controllers
    │
    ▼
Repositories
    │
    ▼
Services Layer
    │
    ▼
Firebase Firestore
    │
    ▼
Firebase Cloud Storage
```

---

## 📁 Project Structure

```
meditrack/
├── lib/
│   ├── main.dart
│   ├── core/               # Constants, routes, theme, utils, validators
│   ├── shared/             # Shared widgets, components, services
│   ├── models/             # Data models (user, vitals, medicine, etc.)
│   ├── repositories/       # Data access layer
│   ├── services/           # Firebase, notifications, PDF, SOS
│   ├── providers/          # State management
│   ├── features/
│   │   ├── auth/
│   │   ├── profile/
│   │   ├── vitals/
│   │   ├── medication/
│   │   ├── doctor_visits/
│   │   ├── prescriptions/
│   │   ├── dashboard/
│   │   ├── analytics/
│   │   ├── reports/
│   │   └── emergency/
│   └── firebase/
├── assets/
├── test/
├── pubspec.yaml
└── README.md
```

---

## 🗄️ Firestore Collections

```
Firestore
├── users
├── vitals
├── medicines
├── medication_logs
├── doctor_visits
├── prescriptions
├── reports
└── emergency_contacts
```

---

## 👥 Team

| Member | Responsibilities |
|---|---|
| Person 1 | Auth, Profile, Firebase Auth |
| Person 2 | Vitals, Vital Model, Vital Repository |
| Person 3 (Nee) | Medication, Doctor Visits, Prescriptions, Notifications, Medicine Repository |
| Person 4 | Dashboard, Analytics, Reports, Emergency, PDF Service, SOS Service |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Dart SDK
- Firebase project (Firestore + Storage + Auth enabled)
- Android Studio or VS Code

### Setup

```bash
# Clone the repository
git clone https://github.com/your-username/meditrack.git
cd meditrack

# Install dependencies
flutter pub get

# Add your Firebase config
# Place google-services.json in android/app/
# Place GoogleService-Info.plist in ios/Runner/

# Run the app
flutter run
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| State Management | Provider |
| Backend | Firebase Firestore |
| Storage | Firebase Cloud Storage |
| Auth | Firebase Authentication |
| Notifications | Flutter Local Notifications |
| PDF Generation | Custom PDF Service |

---

## 📌 Objectives

- ✅ Improve medication adherence
- ✅ Encourage regular health monitoring
- ✅ Digitize medical records
- ✅ Simplify doctor consultations
- ✅ Generate organized health reports
- ✅ Provide emergency support tools
- ✅ Build a long-term personal health history

---

## 📃 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
