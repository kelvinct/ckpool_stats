# CKPool Stats Viewer

A modern, native Flutter application designed to view **CKPool Solo Mining** statistics for any Bitcoin address. It provides a clean dashboard interface to monitor hashrate, shares, best shares, and individual worker details in real-time.

## ✨ Features

- **BTC Address Management**: Input, validate, and save multiple Bitcoin addresses locally for quick access.
- **Real-time API**: Fetches live JSON data from the official CKPool raw API (`https://raw.stats.ckpool.org/`).
- **Dashboard Overview**: Clean card-based UI displaying account hashrate (1m, 5m, 1hr, 1d, 7d), total shares, best shares, and timestamps.
- **Worker List**: Expandable cards for each individual worker showing specific hashrate and share data.
- **Pull to Refresh**: Easily refresh the data directly on the stats page.
- **Local Persistence**: Saves your configured BTC addresses using `shared_preferences` so you don't have to re-enter them.
- **Modern UI**: Built with Material 3, featuring dark mode support (system-adaptive) and a sleek orange-accented theme.

## 📱 Screenshots

*(Add your screenshots here after uploading them to GitHub)*
- Home Page (Input & Saved Addresses)
- Account Overview Dashboard
- Worker Detail Expansion

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **HTTP Client**: [`http`](https://pub.dev/packages/http)
- **Local Storage**: [`shared_preferences`](https://pub.dev/packages/shared_preferences)
- **API Endpoint**: `https://raw.stats.ckpool.org/users/{btc_address}`

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Android Studio / VS Code
- Android SDK & NDK (configured correctly)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ckpool_stats.git
   cd ckpool_stats

   flutter pub get

   flutter build apk --release --split-per-abi

   build/app/outputs/flutter-apk/
   
   adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
