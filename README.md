# Unofficial CheckMK Monitoring App

![CheckMK Logo](images/checkmk-logo-green.png)

A mobile application for monitoring your IT infrastructure through CheckMK. This unofficial app allows you to keep track of your hosts and services status on the go.

## About

The Unofficial CheckMK Monitoring App is a Flutter-based mobile application that connects to your CheckMK monitoring system. It provides real-time monitoring of your IT infrastructure, allowing you to view the status of hosts and services, receive notifications for alerts, and perform basic management actions.

Originally developed for RH Köln (Rheinische Hochschule Köln), this app is now publicly available for anyone using CheckMK.

## Features

### Monitoring
- Real-time monitoring of hosts and services
- Dashboard with hexagon-shaped status indicators
- Home screen widget for Android devices
- Event console for recent service events
- Filtering by host and service states

### Notifications
- Real-time alerts for host and service state changes
- Background monitoring with battery optimization
- Customizable notification settings

### Management
- Acknowledge hosts and services
- Schedule downtimes
- Add comments to hosts and services

### User Experience
- Dark and light theme support
- Responsive design for various device sizes
- Offline caching for faster loading

## Requirements

- Android 5.0 (API level 21) or higher
- iOS 11.0 or higher
- CheckMK Raw Edition (CRE) or CheckMK Enterprise Edition (CEE) server

## Installation

### Google Play Store
The app is available on the Google Play Store:

[<img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" height="80">](https://play.google.com/store/apps/details?id=com.unofficial.checkmk_monitoring)

### Manual Installation
1. Download the latest APK from the [Releases](https://git.pabr.de/rh/unofficial_checkmk_monitoring/-/releases) page
2. Enable installation from unknown sources in your device settings
3. Open the APK file to install

## Usage

### Initial Setup
1. Launch the app
2. Enter your CheckMK server URL (e.g., https://checkmk.example.com)
3. Enter your username and password
4. The app will connect to your CheckMK server and start monitoring

### Dashboard
The dashboard provides an overview of your hosts and services status:
- Green hexagons: Hosts UP / Services OK
- Yellow hexagons: Services in WARNING state
- Red hexagons: Hosts DOWN / Services in CRITICAL state
- Orange hexagons: Hosts UNREACHABLE
- Purple hexagons: Services in UNKNOWN state

Tap on any hexagon to view the corresponding hosts or services.

### Home Screen Widget (Android)
1. Long press on your home screen
2. Select "Widgets"
3. Find and add the "CheckMK Monitor" widget
4. The widget will display the current status of your hosts and services

### Battery Optimization (Android)
For reliable background monitoring and notifications:
1. Go to Settings in the app
2. Select "Battery Optimization"
3. Follow the instructions to disable battery optimization for the app

## Development

### Building from Source
1. Ensure you have Flutter installed (version 3.3.4 or higher)
2. Clone the repository
   ```
   git clone https://github.com/yourusername/ptp_4_monitoring_app.git
   ```
3. Install dependencies
   ```
   flutter pub get
   ```
4. Run the app
   ```
   flutter run
   ```

### Project Structure
- `lib/actions/` - Host and service action implementations
- `lib/models/` - Data models
- `lib/screens/` - UI screens
- `lib/services/` - Backend services
- `lib/widgets/` - Reusable UI components

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [CheckMK](https://checkmk.com/) for their excellent monitoring solution
- [Flutter](https://flutter.dev/) for the cross-platform framework
- RH Köln for the initial project support
