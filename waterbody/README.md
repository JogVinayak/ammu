# 💧 Aqua Reminder

A sophisticated water drinking reminder app built with Flutter that helps you stay hydrated throughout the day.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

### 🔔 Smart Reminders
- Customizable reminder intervals (15 min to 3 hours)
- Active hours configuration (e.g., 7 AM - 10 PM)
- Works in background even when app is closed
- Gentle notifications with snooze option

### 🎵 Customizable Sounds
- **Default**: Simple bell ringing sound
- **Built-in Library**: Water drop, gentle chime, ocean wave, and more
- **Custom Sounds**: Pick your own MP3, WAV, or M4A from device storage

### 📊 Water Tracking
- Quick-add buttons for common amounts (150ml, 250ml, 350ml, 500ml)
- Custom amount input with slider
- Daily progress visualization with animated water wave
- Weekly and monthly statistics with charts

### 🎯 Goals & Statistics
- Customizable daily water goal (1L - 5L)
- Streak tracking for consecutive goal days
- Average intake calculation
- Best day highlights

### 🎨 Beautiful UI
- Modern, water-themed design
- Animated water progress indicator
- Light and dark theme support
- Smooth transitions and micro-interactions

## 📱 Screenshots

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│    💧 Home      │  │   📊 Stats      │  │   ⚙️ Settings   │
│                 │  │                 │  │                 │
│   ╭─────────╮   │  │  Weekly Chart   │  │  Reminder       │
│   │  1.5L   │   │  │  ▄▄▄▄▄▄▄▄▄▄▄   │  │  • Interval     │
│   │  ~~~~   │   │  │  █ █ █▄█ █ █   │  │  • Active Hours │
│   ╰─────────╯   │  │                 │  │                 │
│                 │  │  Summary        │  │  Sound          │
│  Next: 23 min   │  │  • Streak: 5    │  │  • Bell 🔔      │
│                 │  │  • Avg: 2.1L    │  │  • Vibration    │
│  +150  +250     │  │                 │  │                 │
│  +350  Custom   │  │  Daily Log      │  │  Goals          │
│                 │  │  ...            │  │  • Target: 2L   │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / Xcode for mobile development

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/aqua_reminder.git
cd aqua_reminder
```

2. **Add sound assets**
Place your sound files in `assets/sounds/`:
```
assets/sounds/
├── bell.mp3        (default reminder sound)
├── water_drop.mp3
├── chime.mp3
├── ocean.mp3
├── ding.mp3
└── bubbles.mp3
```

3. **Install dependencies**
```bash
flutter pub get
```

4. **Generate Hive adapters** (if needed)
```bash
flutter pub run build_runner build
```

5. **Run the app**
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App configuration
│
├── core/
│   ├── constants/            # Colors, strings, assets
│   ├── theme/                # App theming
│   └── utils/                # Helper functions
│
├── data/
│   ├── models/               # Data models
│   ├── repositories/         # Data access layer
│   └── local/                # Local storage
│
├── services/
│   ├── notification_service.dart
│   ├── sound_service.dart
│   ├── alarm_service.dart
│   └── permission_service.dart
│
├── features/
│   ├── home/                 # Home screen
│   ├── settings/             # Settings & sound picker
│   ├── history/              # Statistics & history
│   └── onboarding/           # First-time setup
│
└── providers/                # State management
```

## 🔧 Configuration

### Reminder Intervals
Available intervals: 15, 30, 45, 60, 90, 120, 180 minutes

### Active Hours
Set your waking hours to avoid disturbance during sleep.

### Sound Options
| Sound | Description |
|-------|-------------|
| Bell (Default) | Simple bell ring |
| Water Drop | Refreshing water droplet |
| Gentle Chime | Soft musical chime |
| Ocean Wave | Calming ocean sounds |
| Soft Ding | Subtle notification ding |
| Bubbles | Playful bubble sounds |
| Custom | Pick from device storage |

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `hive_flutter` | Local database |
| `flutter_local_notifications` | Push notifications |
| `audioplayers` | Sound playback |
| `fl_chart` | Statistics charts |
| `permission_handler` | Runtime permissions |
| `workmanager` | Background tasks |

## 🔒 Permissions

### Android
- `POST_NOTIFICATIONS` - Show reminders
- `SCHEDULE_EXACT_ALARM` - Precise scheduling
- `READ_MEDIA_AUDIO` - Custom sounds
- `VIBRATE` - Haptic feedback
- `RECEIVE_BOOT_COMPLETED` - Restart after reboot

### iOS
- Push Notifications
- Background Modes (audio, fetch, processing)
- Music Library Access (for custom sounds)

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All the open-source package maintainers
- Design inspiration from modern health apps

---

**Stay hydrated, stay healthy! 💧**
