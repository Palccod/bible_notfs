# Bible Notifier App

## Overview
Bible Notifier is a Flutter application that delivers daily random Bible verses directly to your notification panel and lock screen. The app aims to inspire and uplift users by providing them with a new verse each day.

## Features
- Daily notifications with random Bible verses.
- Display of verses on the lock screen.
- User-friendly interface to view and read verses.
- Customizable notification settings.

## Project Structure
```
bible_notfs
├── lib
│   ├── main.dart                # Entry point of the application.
│   ├── screens
│   │   └── home_screen.dart     # Home screen displaying the daily verse.
│   ├── services
│   │   ├── notification_service.dart # Handles notification scheduling and display.
│   │   └── verse_service.dart    # Retrieves random Bible verses.
│   ├── models
│   │   └── verse.dart            # Model representing a Bible verse.
│   └── widgets
│       └── verse_card.dart       # Widget for displaying a verse in a card format.
├── pubspec.yaml                  # Project configuration and dependencies.
└── README.md                     # Documentation for the project.
```

## Setup Instructions
1. Clone the repository:
   ```
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```
   cd bible_notfs
   ```
3. Install the dependencies:
   ```
   flutter pub get
   ```
4. Run the application:
   ```
   flutter run
   ```

## Usage
Upon launching the app, users will receive a daily notification with a random Bible verse. Users can customize their notification preferences in the app settings.

## Contributing
Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for details.