#!/bin/bash

echo "🎲 Sicbo Multiplayer Server Setup"
echo "================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    echo "   Download from: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js found: $(node --version)"

# Navigate to server directory
cd "$(dirname "$0")"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Start the server
echo "🚀 Starting Sicbo Multiplayer Server..."
echo "   Server will run on: ws://localhost:8080"
echo "   Press Ctrl+C to stop the server"
echo ""

npm start
