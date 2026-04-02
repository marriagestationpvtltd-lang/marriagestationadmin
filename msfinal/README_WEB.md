# Marriage Station - Web Version

## Overview
Marriage Station is a matrimonial matchmaking Flutter application. This web version is converted from the Android/iOS mobile application while maintaining all core features.

## Project Structure

```
lib/
├── Auth/                # Authentication screens (Login, Signup)
├── Home/                # Home screen with profile browsing
├── Chat/                # Real-time chat system
├── Calling/             # Video/Audio call features
├── profile/             # User profile management
├── Search/              # Search and filter functionality
├── Package/             # Premium packages
├── Notification/        # Push notifications
├── Models/              # Data models
├── service/             # API services
├── constant/            # Constants
├── responsive/          # NEW: Responsive layout utilities
│   ├── breakpoints.dart
│   ├── platform_utils.dart
│   └── responsive_layout.dart
├── theme/               # NEW: Centralized design system
│   └── app_theme.dart
├── services/            # NEW: Platform-agnostic services
│   ├── image_service.dart
│   └── storage_service.dart
└── main.dart            # App entry point (web-enabled)

web/
├── index.html           # Web app entry HTML
├── manifest.json        # PWA manifest
└── favicon.png          # App icon
```

## Features

### ✅ Implemented
- **Authentication**: Login, Multi-step Signup (10 steps), OTP
- **Profile Browsing**: Swipe cards on mobile, grid on desktop
- **Real-time Chat**: Firebase Firestore messaging
- **Video/Audio Calls**: Agora RTC Engine
- **Search & Filters**: Advanced partner search
- **Packages**: Premium membership plans
- **Responsive Design**: Mobile, Tablet, Desktop layouts
- **Web-optimized UI**: Hover effects, keyboard navigation

### 📱 Platform Support
- **Mobile**: Android, iOS (original)
- **Web**: Chrome, Firefox, Safari, Edge (new)

## Getting Started

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Firebase project configured
- Agora.io account for video/audio calls

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd msfinal

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Build for production
flutter build web --release
```

### Configuration

#### 1. Firebase Configuration
The app uses Firebase for:
- Authentication
- Firestore (chat, user data)
- Storage (images)
- Cloud Messaging (notifications)

Configure your Firebase project and update `lib/firebase_options.dart`.

#### 2. Agora Configuration
For video/audio calls, configure Agora:
- Get your App ID from Agora.io
- Update the configuration in call-related files

#### 3. API Endpoints
The app connects to REST APIs at `https://digitallami.com/api`

### Building for Web

```bash
# Development build
flutter build web

# Production build with optimizations
flutter build web --release \
  --web-renderer canvaskit \
  --dart-define=flutter.inspector.structuredErrors=false

# Build with HTML renderer (better compatibility, slower)
flutter build web --release --web-renderer html
```

## Web-Specific Changes

### 1. URL Routing
- Implemented `PathUrlStrategy` for clean URLs (no hash #)
- Example: `/login` instead of `/#/login`

### 2. Platform Detection
```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // Web-specific code
} else {
  // Mobile-specific code
}
```

### 3. Image Upload
- Mobile: Uses `image_picker` (camera + gallery)
- Web: Uses `file_picker` (file system only)

### 4. Storage
- Mobile: Uses `flutter_secure_storage`
- Web: Uses `SharedPreferences` (web-safe)

### 5. Notifications
- Mobile: Uses `firebase_messaging` + `flutter_local_notifications`
- Web: Uses browser Web Push API

### 6. Responsive Layouts
```dart
import 'package:ms2026/responsive/responsive_layout.dart';

ResponsiveLayout(
  mobile: MobileView(),
  tablet: TabletView(),  // Optional
  desktop: DesktopView(),
)
```

## Responsive Breakpoints

- **Mobile**: < 600px
- **Tablet**: 600px - 1200px
- **Desktop**: ≥ 1200px
- **Max Width**: 1400px (content container)

## Design System

### Colors
- **Primary**: #E91E63 (Pink - marriage theme)
- **Secondary**: #FF4081 (Light Pink)
- **Accent**: #FFC107 (Gold)
- **Success**: #4CAF50
- **Warning**: #FF9800
- **Error**: #F44336

### Typography
- **Font Family**: Poppins (Google Fonts)
- **Spacing**: 8px base unit (4, 8, 12, 16, 24, 32, 48)
- **Border Radius**: 8, 12, 16, 24px

## Deployment

### Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize hosting (first time only)
firebase init hosting

# Deploy
firebase deploy --only hosting
```

### Nginx (Self-hosted)

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    root /var/www/marriagestation/build/web;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_types text/css application/javascript application/json;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

## Performance Optimization

### Current Metrics (Target)
- First Contentful Paint: < 2s
- Time to Interactive: < 4s
- Bundle Size: < 3MB

### Optimization Tips
1. **Image Optimization**: Convert images to WebP
2. **Lazy Loading**: Implement for routes and images
3. **Code Splitting**: Use deferred imports
4. **Caching**: Configure service worker
5. **CDN**: Use for static assets

## Browser Support

| Browser | Version | Status |
|---------|---------|--------|
| Chrome  | Latest  | ✅ Full support |
| Firefox | Latest  | ✅ Full support |
| Safari  | 14+     | ✅ Full support |
| Edge    | Latest  | ✅ Full support |

## Known Limitations

### Web-specific
1. **No Camera Access**: Web browsers don't support camera access via image_picker
   - Solution: Using file_picker for image uploads
2. **Limited Push Notifications**: Requires user permission and service worker
3. **No Background Processes**: Limited background task support
4. **Storage**: Web has limited secure storage options

### Features to Test
- [ ] Video/Audio calls on all browsers
- [ ] File upload (images)
- [ ] Real-time chat updates
- [ ] Push notifications
- [ ] Payment integration
- [ ] Google Sign-in on web

## Development Workflow

### Running Locally
```bash
# Run in Chrome
flutter run -d chrome

# Run with hot reload
flutter run -d chrome --hot

# Run in specific browser
flutter run -d edge
flutter run -d firefox # if configured
```

### Debugging
```bash
# Enable verbose logging
flutter run -d chrome --verbose

# Debug mode
flutter run -d chrome --profile

# DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Manual Testing Checklist
- [ ] Login/Signup flow
- [ ] Profile browsing (swipe/grid)
- [ ] Chat sending/receiving
- [ ] Image upload
- [ ] Video/Audio calls
- [ ] Search and filters
- [ ] Package purchase
- [ ] Responsive layouts (all breakpoints)
- [ ] Cross-browser compatibility

## Troubleshooting

### Common Issues

**1. Build fails with package errors**
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

**2. Firebase not initializing**
- Check `web/index.html` has Firebase scripts
- Verify `firebase_options.dart` configuration
- Ensure Firebase project has Web app configured

**3. Agora calls not working**
- Verify Agora App ID is correct
- Check browser permissions for microphone/camera
- Ensure Agora Web SDK is loaded in `index.html`

**4. Images not loading**
- Check CORS configuration on image server
- Verify image URLs are absolute paths
- Check browser console for errors

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple browsers
5. Submit a pull request

## License

[Your License Here]

## Contact

For questions or issues, please contact:
- Email: support@marriagestation.com
- Website: https://marriagestation.com

---

**Note**: This web version maintains feature parity with the mobile app while optimizing for web user experience. All APIs and backend services remain unchanged.
