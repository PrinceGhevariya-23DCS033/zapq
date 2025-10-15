# ZapQ - Smart Virtual Queue & Shop Management App

ZapQ is a comprehensive Flutter-based mobile application that revolutionizes the way customers and businesses handle queues. By replacing physical queues with virtual ones, ZapQ reduces crowding, saves time, and improves the overall customer experience.

## 🚀 Features

### Customer Features
- **Virtual Queue Booking**: Book your place in line remotely
- **Map-based Shop Locator**: Find nearby businesses with photos, info, and reviews
- **Real-time Queue Status**: Track your position and estimated wait time
- **Push Notifications**: Get notified when your turn is approaching
- **Feedback & Rating System**: Rate and review businesses after service
- **Booking History**: View past queues and services

### Business Owner Features
- **Owner Dashboard**: Complete overview of queue operations
- **Queue Management**: Add, remove, and reorder customers
- **Business Profile Management**: Update shop details, photos, and location
- **Analytics & Reports**: Track busiest times and customer patterns
- **Slot Management**: Set capacity and operating hours

### Advanced Features
- **QR Code Check-in**: Confirm customer presence at the shop
- **AI-based Wait Time Prediction**: Smart estimates using historical data
- **Multi-language Support**: Accessible in multiple languages
- **Google Maps Integration**: Full location and navigation support

## 🏗️ Architecture

This project follows Clean Architecture principles with feature-based modularization:

```
lib/
├── core/                 # Core functionality
│   ├── constants/        # App constants
│   ├── theme/           # App theming
│   └── utils/           # Utility functions
├── features/            # Feature modules
│   ├── authentication/ # Auth functionality
│   ├── customer/       # Customer features
│   ├── business_owner/ # Business owner features
│   ├── maps/           # Map integration
│   ├── queue/          # Queue management
│   ├── notifications/  # Push notifications
│   └── feedback/       # Rating & reviews
└── shared/             # Shared components
    ├── models/         # Data models
    ├── providers/      # State management
    └── widgets/        # Reusable widgets
```

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Auth, Cloud Messaging, Storage)
- **Maps**: Google Maps API
- **State Management**: Provider
- **Navigation**: Go Router
- **Authentication**: Firebase Auth + Google Sign-In

## 📱 Screenshots

*Screenshots will be added as the UI is developed*

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.8.1)
- Firebase account
- Google Cloud Platform account (for Maps API)
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd zapq
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication, Firestore, Cloud Messaging, and Storage
   - Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

4. **Google Maps Setup**
   - Enable Google Maps SDK in Google Cloud Console
   - Get API key and add to platform-specific files

5. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Firebase Collections Structure

```
users/
  {userId}/
    - id: string
    - email: string
    - name: string
    - phoneNumber: string
    - userType: 'customer' | 'business_owner'
    - profileImageUrl: string?
    - createdAt: timestamp
    - updatedAt: timestamp

businesses/
  {businessId}/
    - id: string
    - ownerId: string
    - name: string
    - description: string
    - category: string
    - address: string
    - latitude: number
    - longitude: number
    - phoneNumber: string
    - imageUrls: string[]
    - operatingHours: map
    - maxCustomersPerDay: number
    - averageServiceTimeMinutes: number
    - isActive: boolean
    - rating: number
    - totalRatings: number

queues/
  {queueId}/
    - id: string
    - businessId: string
    - customerId: string
    - customerName: string
    - position: number
    - status: 'waiting' | 'active' | 'completed' | 'cancelled'
    - bookedAt: timestamp
    - estimatedWaitTimeMinutes: number

feedback/
  {feedbackId}/
    - id: string
    - businessId: string
    - customerId: string
    - customerName: string
    - rating: number
    - comment: string?
    - createdAt: timestamp
    - isVerified: boolean
```

## 🎯 Roadmap

### Phase 1 (Current)
- [x] Project structure setup
- [x] Authentication system
- [x] Basic UI/UX framework
- [ ] Firebase integration
- [ ] Basic queue management

### Phase 2
- [ ] Google Maps integration
- [ ] Real-time queue updates
- [ ] Push notifications
- [ ] Business profile management

### Phase 3
- [ ] QR code functionality
- [ ] Analytics dashboard
- [ ] AI-based predictions
- [ ] Multi-language support

### Phase 4
- [ ] Advanced features
- [ ] Performance optimization
- [ ] Testing & deployment

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Developer**: Prince Ghevariya
- **Project Type**: Mobile Application Development
- **Course**: MAD (Mobile Application Development)

## 📞 Support

For support, email [your-email] or create an issue in this repository.

---

**ZapQ** - Revolutionizing queue management, one app at a time! 🚀
