#!/bin/bash

echo "=== Fixing API Model Name ==="
echo ""

# Backup original file
cp book/Services/GroqAPIService.swift book/Services/GroqAPIService.swift.backup
echo "✓ Backup created: GroqAPIService.swift.backup"

# Replace the model name
sed -i '' 's/openai\/gpt-oss-120b/mixtral-8x7b-32768/g' book/Services/GroqAPIService.swift

if grep -q "mixtral-8x7b-32768" book/Services/GroqAPIService.swift; then
    echo "✓ Model name updated to: mixtral-8x7b-32768"
    echo ""
    echo "The API model has been updated to a valid Groq model."
    echo "This should fix any 'model not found' errors."
else
    echo "✗ Failed to update model name"
    echo "Restoring backup..."
    mv book/Services/GroqAPIService.swift.backup book/Services/GroqAPIService.swift
fi

echo ""
echo "=== Done ==="
