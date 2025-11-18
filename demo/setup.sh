#!/bin/bash
# Setup script for the lucky-swagger demo

set -e

echo "🔧 Setting up lucky-swagger demo..."
echo ""

# Check if we're in the demo directory
if [ ! -f "shard.yml" ]; then
    echo "❌ Error: Please run this script from the demo directory"
    exit 1
fi

echo "📦 Installing dependencies..."
shards install

echo ""
echo "✅ Setup complete!"
echo ""
echo "📚 Quick Start:"
echo "  1. Run the server:    crystal src/demo.cr"
echo "  2. Visit SwaggerUI:   http://localhost:5000/api-docs"
echo "  3. Test an endpoint:  curl http://localhost:5000/api/health"
echo ""
