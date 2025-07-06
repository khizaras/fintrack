# FinTrack - Automatic SMS Transaction Tracking

FinTrack is a Flutter mobile application that automatically reads SMS messages from banks and financial institutions to track expenses and income. The app categorizes transactions, provides spending insights, and allows users to set budgets.

## Features

### 🔑 Core Features

- **Automatic SMS Reading**: Reads bank SMS messages to extract transaction data
- **Smart Categorization**: Automatically categorizes transactions into predefined categories
- **Budget Management**: Set and track budgets for different spending categories
- **Financial Insights**: Visualizations and reports showing spending patterns
- **Secure Storage**: Local SQLite database with encryption for sensitive data
- **Permission Management**: Proper SMS permission handling

### 📱 User Interface

- Clean, modern Material Design 3 interface
- Dashboard with quick financial overview
- Transaction list with filtering and search
- Budget tracking with progress indicators
- Charts and graphs for spending insights
- Dark/Light theme support

### 🔒 Security & Privacy

- Local data storage only
- Encrypted sensitive information
- SMS permission transparency
- GDPR compliance considerations
- No data sent to external servers

## Tech Stack

### Frontend

- **Flutter** - Cross-platform mobile development
- **Material Design 3** - Modern UI components
- **BLoC Pattern** - State management
- **Equatable** - Value equality

### Backend & Storage

- **SQLite** - Local database storage
- **SharedPreferences** - Simple data storage

### SMS & Permissions

- **Telephony** - SMS reading functionality
- **Permission Handler** - Runtime permissions

### Utilities

- **Intl** - Internationalization
- **Logger** - Logging functionality

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_strings.dart
│   ├── database/
│   │   └── database_helper.dart
│   ├── error/
│   ├── network/
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── transactions/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── budget/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── insights/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── sms/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── home/
│       └── presentation/
│           ├── pages/
│           └── widgets/
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (>=2.19.6)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd fin-track
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Android Permissions

The app requires the following permissions:

- `READ_SMS` - To read bank transaction SMS messages
- `RECEIVE_SMS` - To receive new SMS messages
- `READ_PHONE_STATE` - To access phone state information

These permissions are declared in `android/app/src/main/AndroidManifest.xml`.

## Architecture

The app follows **Clean Architecture** principles with clear separation of concerns:

- **Presentation Layer**: UI components, pages, widgets, and BLoCs
- **Domain Layer**: Business logic, entities, and use cases
- **Data Layer**: Repositories, data sources, and models

### State Management

Uses **BLoC (Business Logic Component)** pattern for:

- Reactive state management
- Separation of business logic from UI
- Testable code structure
- Event-driven architecture

## SMS Processing

The app includes sophisticated SMS parsing to extract transaction data from various bank formats:

### Supported Banks

- State Bank of India (SBI)
- HDFC Bank
- ICICI Bank
- Axis Bank
- (More banks can be added via SMS patterns)

### Transaction Extraction

- Amount parsing with currency symbols
- Date and time extraction
- Merchant/vendor identification
- Account number masking
- Transaction type detection (debit/credit)

## Development

### Running Tests

```bash
flutter test
```

### Code Generation

```bash
flutter packages pub run build_runner build
```

### Building for Release

```bash
flutter build apk --release
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Dart/Flutter conventions
- Use meaningful variable and function names
- Add documentation for public APIs
- Write tests for new features

## Privacy & Security

- **Local Storage Only**: All data is stored locally on the device
- **Encryption**: Sensitive data is encrypted before storage
- **Permission Transparency**: Clear explanation of why permissions are needed
- **No External APIs**: No data is sent to external servers
- **Open Source**: Code is open for security audits

## Roadmap

### Phase 1 (Current)

- [x] Basic app structure
- [x] SMS permission handling
- [x] Database setup
- [x] UI foundation

### Phase 2 (Next)

- [ ] SMS parsing implementation
- [ ] Transaction categorization
- [ ] Budget management
- [ ] Basic charts and insights

### Phase 3 (Future)

- [ ] Advanced analytics
- [ ] Export functionality
- [ ] Backup and restore
- [ ] Multiple bank account support

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email support@fintrack.app or open an issue on GitHub.

## Acknowledgments

- Flutter team for the amazing framework
- Material Design team for the design system
- Open source community for various packages used
