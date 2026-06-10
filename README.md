# Smart_108 -  Multi-App Emergency Response Ecosystem


Smart 108 is a real-time, high-performance emergency response platform designed for the Indian context. The ecosystem bridges the gap between citizens in distress and field responders (Ambulance, Fire Brigade, and Police).

The entire system is cross-platform, powered by **Flutter** for front-end experiences and **Firebase** for real-time state synchronization, authentication, and serverless data transactions.

---

## 🏗️ System Architecture

The ecosystem consists of three specialized applications interacting with a centralized cloud backend:

1. **Victim Application (Mobile):** Allows citizens to broadcast emergency alerts with live GPS coordinates, tracking their current state (`pending`, `assigned`, `resolved`).
2. **Responder Application (Mobile):** Tailored for field units (Ambulance, Police, Fire). Handles secure authentication, real-time availability updates (`idle` vs. `busy`), and interactive routing to incident scenes.
3. **Command Center Dashboard (Web):** A tactical map-centric panel designed for **Emergency Dispatchers** to monitor incoming district requests, view the top 5 nearest matching responders, draw routing paths, and execute dispatch operations.

---

## 🛠️ Tech Stack

* **Front-end Framework:** Flutter (Dart)
* **Backend-as-a-Service:** Firebase Authentication, Cloud Firestore
* **Geospatial & Mapping:** Google Maps Flutter API, Flutter Polyline Points, Geolocator
* **State Management & Architecture:** StreamBuilder (Reactive streams for live data updates)

---

## 📁 Repository Structure

```text
smart-108/
├── victim_app/             # Flutter app for citizens raising alerts
├── responder_app/          # Flutter app for emergency field units
└── dispatch_dashboard/     # Flutter Web app for Emergency Dispatchers
