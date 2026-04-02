#!/bin/bash

# Marriage Station - Web Build Script
# This script builds the Flutter web application with optimization

echo "🚀 Building Marriage Station Web App..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Flutter found"

# Clean previous builds
echo -e "${YELLOW}📦 Cleaning previous builds...${NC}"
flutter clean

# Get dependencies
echo -e "${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get

# Build for web
echo -e "${YELLOW}🔨 Building web application...${NC}"
echo ""

flutter build web \
  --release \
  --web-renderer canvaskit \
  --dart-define=flutter.inspector.structuredErrors=false \
  --base-href "/" \
  --no-tree-shake-icons

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""
    echo "📁 Output directory: build/web/"
    echo ""
    echo "🌐 To test locally:"
    echo "   cd build/web && python3 -m http.server 8000"
    echo "   Then open: http://localhost:8000"
    echo ""
    echo "🚀 To deploy to Firebase Hosting:"
    echo "   firebase deploy --only hosting"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Build failed!${NC}"
    echo "Please check the error messages above."
    exit 1
fi
