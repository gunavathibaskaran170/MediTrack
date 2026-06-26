# 🏥 MediTrack

> Your Secure, Offline-First Personal Health Companion & Medication Tracking Application.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart)](https://dart.dev)
[![Database](https://img.shields.io/badge/Database-SQLite%20(Sqflite)-003B57?logo=sqlite)](https://github.com/tekartik/sqflite)
[![Deployment](https://img.shields.io/badge/Deploy-Vercel-black?logo=vercel)](https://vercel.com)
[![Category](https://img.shields.io/badge/Category-HealthTech-green)](#)
[![License](https://img.shields.io/badge/License-MIT-lightgrey)](#)

---

## 📋 Overview

**MediTrack** is a high-fidelity, comprehensive HealthTech web and mobile application designed to help individuals track their chronic health conditions, vital checkups, medication regimens, doctor follow-ups, and emergency alerts. 

By leveraging a secure, **offline-first local database architecture (SQLite)**, MediTrack guarantees user health privacy while providing premium features like real-time interactive vital animations, clinical hospital synchronization selectors, dynamic health profile QR codes, and automated PDF medical report exports.

---

## 🌟 Key Features

### 🔐 Secure Authentication & Detailed Sign Up
- **Demographic profile mapping**: Track medical metrics (blood group, allergies, existing chronic diseases).
- **Hospital Connection**: Select and synchronize clinical records with a local health provider database.
- **Emergency Contacts**: Record emergency helper details directly in local secure memory.

### 📊 Health Analytics Dashboard
Features a dynamic grid containing **six premium interactive visual animations** placed in a horizontal layout to prevent empty space:
* **Heart Rate**: A beating heart icon pulsing in sync with user BPM over a rolling background ECG cardiogram.
* **Blood Pressure**: A dual-ring circular progress gauge representing Systolic (outer) and Diastolic (inner) values.
* **Blood Sugar**: A fluid liquid wave gauge displaying glucose saturation levels with a floating droplet icon.
* **Oxygen Saturation**: A rotating radial progress gauge with a breathing air icon in the center.
* **Body Temperature**: A mercury-filled thermometer indicator indicating degrees alongside rising heat waves.
* **Body Weight**: A weight scale gauge with a needle that dynamically sweeps to weight marks with an elastic bounce.

### 💊 Medication Tracker & Care Guidelines
- Add and schedule medicine routines with precise dosage, frequency, and duration.
- View clinical instructions, precautions, and side effects side-by-side.
- Integration of a quick-action banner to call pharmacy support or order replacements.

### 📱 Dynamic QR Medical Card
- Generates a high-fidelity QR Code containing full demographic, chronic condition, and clinical details in JSON format.
- Ideal for emergency personnel or doctors to scan and immediately understand user medical parameters.

### 🔔 Smart Reminders & SOS Actions
- Push notifications for medication dosages and vital logging schedules.
- Tap-to-SOS trigger to share allergy records, medical profiles, and coordinates during emergencies.
- PDF Report Generator: Exports consolidated logs of vitals history, schedules, and clinical logs.

---

## 🏗️ Architecture

```
Flutter UI (Web & Desktop)
        │
        ▼
   Providers (State Management)
        │
        ▼
  Local SQLite (Sqflite Helper)
        │
        ▼
   Vercel Hosting (Static Output)
```

---

## 📁 Folder Directory Structure

```
meditrack/
├── assets/                 # Graphics, logos, and medical illustrations
├── lib/
│   ├── main.dart           # App bootstrap and route navigator registry
│   ├── core/               # SQLite database schemas and data models
│   ├── providers/          # Provider controllers (User, Vitals, Medicine, Analytics)
│   ├── screens/            # UI Screens (Analytics, Vitals Logging, Sign Up, Profile)
│   ├── services/           # PDF compiler, notifications, and SOS services
│   ├── theme/              # MediTrack custom color system and typography
│   └── widgets/            # Custom painters, floating particle nodes, vital animations
├── web/                    # Vercel routing configurations and index.html template
├── pubspec.yaml            # Package dependencies configuration
└── README.md
```

---

## 🗄️ Database Tables (SQLite Schema v4)
* **`users`**: Contains demographic, blood group, allergic history, and `connected_hospital` parameters.
* **`vitals`**: Logs heart rate, systolic/diastolic pressures, glucose levels, temperature, SpO2, and weights.
* **`medicines`**: Stores dosage schedules, active times, precautions, and instructions.
* **`medication_logs`**: Tracks adherence history (Taken/Missed doses).
* **`doctor_visits`**: Logs clinical consultations and appointment follow-ups.

---

## 🚀 Getting Started Locally

### Prerequisites
- Flutter SDK (v3.19.x or higher)
- Dart SDK
- Android SDK (for mobile emulation) or Chrome/Edge (for web debugging)

### Setup
1. **Clone the repo**:
   ```bash
   git clone https://github.com/gunavathibaskaran170/MediTrack.git
   cd MediTrack
   ```

2. **Retrieve Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Application**:
   ```bash
   flutter run -d chrome # Runs Flutter Web App
   ```

---

## ☁️ Vercel Web Deployment

To deploy this project as a live, routing-friendly static web application on Vercel:

1. **Build the production web build**:
   ```bash
   flutter build web --release
   ```
   *This compiles all files and copies the routing-friendly [web/vercel.json](file:///D:/dev%20fusion/web/vercel.json) configuration into `build/web/`.*

2. **Deploy to production**:
   ```bash
   vercel build/web --prod --scope amigotech
   ```
   *This uploads only the static folder, treating the compiled folder as root, and configures route rewrites to allow deep links (e.g. `/analytics`) to load index.html without throwing 404 errors.*

---

## 📃 License

This project is licensed under the MIT License.
