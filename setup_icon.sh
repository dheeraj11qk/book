#!/bin/bash

echo "=== Book App Icon Setup ==="
echo ""

# Check if source icon exists
if [ ! -f "app_icon.png" ]; then
    echo "❌ Error: app_icon.png not found"
    echo ""
    echo "Please save your icon as 'app_icon.png' (1024x1024) in the project root"
    echo "Then run this script again."
    exit 1
fi

# Check image size
SIZE=$(sips -g pixelWidth -g pixelHeight app_icon.png | grep -E "pixelWidth|pixelHeight" | awk '{print $2}')
WIDTH=$(sips -g pixelWidth app_icon.png | grep pixelWidth | awk '{print $2}')
HEIGHT=$(sips -g pixelHeight app_icon.png | grep pixelHeight | awk '{print $2}')

echo "Source icon: ${WIDTH}x${HEIGHT}"

if [ "$WIDTH" -lt 1024 ] || [ "$HEIGHT" -lt 1024 ]; then
    echo "⚠️  Warning: Icon should be at least 1024x1024 for best quality"
    echo "Current size: ${WIDTH}x${HEIGHT}"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create output directory
OUTPUT_DIR="book/Assets.xcassets/AppIcon.appiconset"
echo ""
echo "Generating icon sizes..."

# Generate all required sizes
sips -z 16 16 app_icon.png --out "${OUTPUT_DIR}/icon_16x16.png" > /dev/null 2>&1
echo "✓ 16x16"

sips -z 32 32 app_icon.png --out "${OUTPUT_DIR}/icon_16x16@2x.png" > /dev/null 2>&1
echo "✓ 16x16@2x (32x32)"

sips -z 32 32 app_icon.png --out "${OUTPUT_DIR}/icon_32x32.png" > /dev/null 2>&1
echo "✓ 32x32"

sips -z 64 64 app_icon.png --out "${OUTPUT_DIR}/icon_32x32@2x.png" > /dev/null 2>&1
echo "✓ 32x32@2x (64x64)"

sips -z 128 128 app_icon.png --out "${OUTPUT_DIR}/icon_128x128.png" > /dev/null 2>&1
echo "✓ 128x128"

sips -z 256 256 app_icon.png --out "${OUTPUT_DIR}/icon_128x128@2x.png" > /dev/null 2>&1
echo "✓ 128x128@2x (256x256)"

sips -z 256 256 app_icon.png --out "${OUTPUT_DIR}/icon_256x256.png" > /dev/null 2>&1
echo "✓ 256x256"

sips -z 512 512 app_icon.png --out "${OUTPUT_DIR}/icon_256x256@2x.png" > /dev/null 2>&1
echo "✓ 256x256@2x (512x512)"

sips -z 512 512 app_icon.png --out "${OUTPUT_DIR}/icon_512x512.png" > /dev/null 2>&1
echo "✓ 512x512"

sips -z 1024 1024 app_icon.png --out "${OUTPUT_DIR}/icon_512x512@2x.png" > /dev/null 2>&1
echo "✓ 512x512@2x (1024x1024)"

# Update Contents.json
cat > "${OUTPUT_DIR}/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo ""
echo "✅ Icon setup complete!"
echo ""
echo "Next steps:"
echo "1. Open book.xcodeproj in Xcode"
echo "2. Clean build folder (Cmd + Shift + K)"
echo "3. Build and run (Cmd + R)"
echo "4. Your new icon should appear in the Dock!"
echo ""
echo "Icon files created in: ${OUTPUT_DIR}"
