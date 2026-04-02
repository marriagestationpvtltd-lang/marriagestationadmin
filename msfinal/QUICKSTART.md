# 🚀 Quick Start Guide - Marriage Station Web

## तुरुन्त सुरु गर्नुहोस् (Quick Start)

### 1️⃣ Dependencies Install गर्नुहोस्
```bash
cd msfinal
flutter pub get
```

### 2️⃣ Local मा Run गर्नुहोस्
```bash
flutter run -d chrome
```

### 3️⃣ Build गर्नुहोस्
```bash
# Automated build
./build_web.sh

# Or manual
flutter build web --release
```

---

## 📁 Project Structure

```
msfinal/
├── lib/
│   ├── Auth/              # Login, Signup screens
│   ├── Home/              # Profile browsing
│   ├── Chat/              # Real-time chat
│   ├── Calling/           # Video/Audio calls
│   ├── responsive/        # 🆕 Responsive utilities
│   ├── theme/             # 🆕 Design system
│   ├── services/          # 🆕 Platform services
│   └── main.dart          # 🔄 Updated for web
├── web/                   # 🆕 Web config
├── pubspec.yaml           # 🔄 Updated packages
└── build_web.sh           # 🆕 Build script
```

---

## ⚡ Commands

### Development
```bash
# Run in Chrome
flutter run -d chrome

# Hot reload
flutter run -d chrome --hot

# Debug mode
flutter run -d chrome --profile
```

### Building
```bash
# Production build (optimized)
flutter build web --release --web-renderer canvaskit

# HTML renderer (better compatibility)
flutter build web --release --web-renderer html
```

### Testing
```bash
# Unit tests
flutter test

# Local server
cd build/web
python3 -m http.server 8000
# Open: http://localhost:8000
```

### Deployment
```bash
# Firebase
firebase deploy --only hosting

# Or copy build/web/ to your server
```

---

## 🎯 Key Features

### Mobile (< 600px)
- Bottom navigation
- Full-screen views
- Swipe gestures
- Touch-optimized

### Desktop (≥ 1200px)
- Top navigation
- Multi-column layouts
- Hover effects
- Keyboard shortcuts

---

## 🔧 Configuration

### Firebase
1. Go to Firebase Console
2. Add Web App
3. Copy config to `lib/firebase_options.dart`

### Agora (Video Calls)
1. Go to Agora.io Dashboard
2. Enable Web platform
3. Copy App ID to call files

---

## 🐛 Troubleshooting

### Build Errors
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Firebase Issues
- Check `web/index.html` has Firebase scripts
- Verify Firebase config
- Enable Web platform in Firebase Console

### Agora Issues
- Check App ID is correct
- Allow microphone/camera in browser
- Verify Agora Web SDK loaded

### CORS Errors
- Configure CORS on API server
- Check image server CORS
- Use HTTPS in production

---

## 📚 Documentation

- **COMPLETE_NEPALI.md** - नेपालीमा complete guide
- **README_WEB.md** - Detailed web documentation
- **WEB_CONVERSION_SUMMARY.md** - Technical details

---

## ✅ Testing Checklist

- [ ] Login works
- [ ] Signup (10 steps) works
- [ ] Profile browsing
- [ ] Chat messages
- [ ] Image upload
- [ ] Video/Audio calls
- [ ] Search filters
- [ ] Mobile responsive
- [ ] Desktop responsive
- [ ] Cross-browser

---

## 🎨 Design System

### Colors
```dart
Primary: #E91E63 (Pink)
Secondary: #FF4081
Accent: #FFC107 (Gold)
```

### Breakpoints
```dart
Mobile: < 600px
Tablet: 600px - 1200px
Desktop: ≥ 1200px
```

### Typography
- Font: Poppins
- Spacing: 8, 16, 24, 32, 48px
- Radius: 8, 12, 16, 24px

---

## 🌐 Browser Support

| Browser | Status |
|---------|--------|
| Chrome  | ✅ Best |
| Firefox | ✅ Good |
| Safari  | ✅ Good (14+) |
| Edge    | ✅ Best |

---

## 💡 Tips

1. **Development**: Use Chrome for best DevTools
2. **Building**: Use canvaskit renderer for performance
3. **Testing**: Test on multiple browsers
4. **Images**: Optimize images for web (WebP)
5. **CORS**: Configure API and image servers

---

## 🆘 Need Help?

### Check These First:
1. Browser console (F12)
2. Network tab (check API calls)
3. Firebase Console (check config)
4. Documentation files

### Common Issues:
- **No camera access**: Normal on web, use file upload
- **Notifications not working**: Enable browser permissions
- **Build fails**: Run `flutter clean && flutter pub get`
- **White screen**: Check browser console for errors

---

## 🎉 You're Ready!

Your Marriage Station app is now web-ready. Follow the steps above to:
1. Test locally
2. Build for production
3. Deploy to hosting
4. Make improvements

**Good luck!** 🚀
