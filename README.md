# ABRAR - Internet Data Usage Monitor

![ABRAR Logo](assets/icon/icon.png)

## Overview

ABRAR is a comprehensive mobile application built with Flutter that helps users monitor and manage their internet data usage. The app provides real-time tracking, usage statistics, and customizable alerts to ensure users never exceed their data limits.

## Features

- **Real-time Data Monitoring**: Track your mobile and WiFi data usage in real-time
- **Usage Statistics**: Visualize your data consumption patterns with interactive charts
- **Customizable Alerts**: Set data usage thresholds and receive notifications
- **Background Monitoring**: Continuous monitoring even when the app is closed
- **Multi-platform Support**: Works on Android, iOS, Windows, macOS, Linux, and Web
- **Data History**: View historical usage data and identify trends
- **User-friendly Interface**: Clean and intuitive design for easy navigation

## Technologies

- **Frontend**: Flutter 3.10+, Dart 3.0+
- **State Management**: Flutter Riverpod, Flutter Bloc, Equatable
- **Navigation**: Go Router
- **Local Storage**: SQLite (sqflite), Shared Preferences, Flutter Secure Storage
- **Charts & Visualization**: FL Chart, Syncfusion Flutter Charts
- **Background Services**: Flutter Background Service
- **Notifications**: Flutter Local Notifications
- **Backend Integration**: Firebase Core, Cloud Firestore
- **Device Information**: Permission Handler, Device Info Plus, Network Info Plus
- **Dependency Injection**: GetIt

## Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/monitoring_data.git
   ```

2. Navigate to the project directory
   ```bash
   cd monitoring_data
   ```

3. Install dependencies
   ```bash
   flutter pub get
   ```

4. Run the app
   ```bash
   flutter run
   ```

## Requirements

- Flutter SDK: >=3.10.0
- Dart SDK: >=3.0.0 <4.0.0
- Android: SDK 21+ (Android 5.0 or newer)
- iOS: 11.0 or newer

## Architecture

The application follows a clean architecture approach with the following structure:

- `lib/models`: Data models
- `lib/screens`: UI screens
- `lib/widgets`: Reusable UI components
- `lib/services`: Business logic and services
- `lib/cubits`: State management using Bloc pattern
- `lib/utils`: Helper functions and utilities
- `lib/router`: Application routing
- `lib/extensions`: Dart extensions

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For any inquiries, please open an issue in this repository.