#!/bin/bash

echo "=== Testing Book App ==="
echo ""

# Check if API key is set
echo "1. Checking API configuration..."
if grep -q "gsk_" book/Config/APIKeys.swift; then
    echo "✓ API key found"
else
    echo "✗ API key missing"
fi

echo ""
echo "2. Checking for build errors..."
xcodebuild -project book.xcodeproj -scheme book -configuration Debug -dry-run 2>&1 | grep -i "error" | head -20

echo ""
echo "3. Checking file structure..."
echo "Core files:"
ls -la book/*.swift 2>/dev/null | awk '{print $9}'
echo ""
echo "Services:"
ls -la book/Services/*.swift 2>/dev/null | awk '{print $9}'
echo ""
echo "Views:"
ls -la book/Views/*.swift 2>/dev/null | awk '{print $9}'

echo ""
echo "4. Checking for missing dependencies..."
if [ -f "book.xcodeproj/project.pbxproj" ]; then
    echo "✓ Xcode project file exists"
else
    echo "✗ Xcode project file missing"
fi

echo ""
echo "=== Test Complete ==="
