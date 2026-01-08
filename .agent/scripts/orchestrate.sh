#!/bin/bash
# orchestrate.sh - Simple orchestrator for common tasks

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Base directory
AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Show usage
show_usage() {
    echo "================================"
    echo "Orchestrator - Common Tasks"
    echo "================================"
    echo ""
    echo "Quick Commands:"
    echo "  analyze              - Analyze current project"
    echo "  search <pattern>     - Search in files"
    echo "  find <filename>      - Find files"
    echo "  list <ext>           - List files by extension"
    echo ""
    echo "Examples:"
    echo "  $0 analyze"
    echo "  $0 search 'function'"
    echo "  $0 find '*.tsx'"
    echo "  $0 list tsx"
    echo ""
}

# Analyze project
analyze_project() {
    echo "================================"
    echo "🔍 Project Analysis"
    echo "================================"
    echo ""

    local project_dir=$(pwd)
    echo "📁 Project: $project_dir"
    echo ""

    # Detect project type
    echo "🔎 Detecting project type..."

    if [ -f "package.json" ]; then
        echo "   ✅ Node.js/TypeScript project found"

        # Get project info
        local project_name=$(jq -r '.name // "Unknown"' package.json 2>/dev/null)
        local version=$(jq -r '.version // "Unknown"' package.json 2>/dev/null)

        echo ""
        echo "📦 Project Info:"
        echo "   Name: $project_name"
        echo "   Version: $version"

        # Dependencies
        echo ""
        echo "📚 Main Dependencies:"
        jq -r '.dependencies | keys[]' package.json 2>/dev/null | head -10 | sed 's/^/   - /'

        # Framework detection
        echo ""
        echo "🎯 Framework/Libraries:"
        if jq -e '.dependencies.react' package.json >/dev/null 2>&1; then
            echo "   ✅ React"
        fi
        if jq -e '.dependencies.vue' package.json >/dev/null 2>&1; then
            echo "   ✅ Vue"
        fi
        if jq -e '.dependencies.next' package.json >/dev/null 2>&1; then
            echo "   ✅ Next.js"
        fi
        if jq -e '.dependencies."@angular"' package.json >/dev/null 2>&1; then
            echo "   ✅ Angular"
        fi
        if jq -e '.dependencies."react-native"' package.json >/dev/null 2>&1; then
            echo "   ✅ React Native"
        fi

        # Dev dependencies
        echo ""
        echo "🛠️  Dev Tools:"
        if jq -e '.devDependencies.typescript' package.json >/dev/null 2>&1; then
            echo "   ✅ TypeScript"
        fi
        if jq -e '.devDependencies.vite' package.json >/dev/null 2>&1; then
            echo "   ✅ Vite"
        fi
        if jq -e '.devDependencies."@vitejs/plugin-react"' package.json >/dev/null 2>&1; then
            echo "   ✅ Vite React Plugin"
        fi
        if jq -e '.devDependencies.tailwindcss' package.json >/dev/null 2>&1; then
            echo "   ✅ Tailwind CSS"
        fi
        if jq -e '.devDependencies.jest' package.json >/dev/null 2>&1; then
            echo "   ✅ Jest"
        fi
        if jq -e '.devDependencies.cypress' package.json >/dev/null 2>&1; then
            echo "   ✅ Cypress"
        fi
    elif [ -f "requirements.txt" ]; then
        echo "   ✅ Python project found"
        echo ""
        echo "📚 Dependencies (top 10):"
        head -10 requirements.txt | sed 's/^/   - /'
    elif [ -f "go.mod" ]; then
        echo "   ✅ Go project found"
        echo ""
        echo "📚 Module:"
        head -5 go.mod | sed 's/^/   /'
    elif [ -f "Cargo.toml" ]; then
        echo "   ✅ Rust project found"
        echo ""
        echo "📦 Package:"
        grep -E "name|version" Cargo.toml | head -5 | sed 's/^/   /'
    else
        echo "   ⚠️  Unknown project type"
    fi

    # File structure
    echo ""
    echo "📂 File Structure:"
    echo "   Source files:"
    find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" \) 2>/dev/null | head -20 | sed 's|^\./|      |'

    # Config files
    echo ""
    echo "⚙️  Config Files:"
    for config in tsconfig.json vite.config.ts tailwind.config.js jest.config.js .eslintrc .prettierrc; do
        if [ -f "$config" ]; then
            echo "   ✅ $config"
        fi
    done

    echo ""
}

# Search in files
search_files() {
    local pattern=$1

    if [ -z "$pattern" ]; then
        echo "Usage: $0 search <pattern>"
        exit 1
    fi

    echo "================================"
    echo "🔍 Searching: $pattern"
    echo "================================"
    echo ""

    # Use grep to search
    grep -r "$pattern" \
        --include="*.ts" \
        --include="*.tsx" \
        --include="*.js" \
        --include="*.jsx" \
        --include="*.py" \
        --include="*.go" \
        --color=always \
        -n \
        . 2>/dev/null || echo "No matches found"

    echo ""
}

# Find files
find_files() {
    local pattern=$1

    if [ -z "$pattern" ]; then
        echo "Usage: $0 find <pattern>"
        echo "Example: $0 find '*.tsx'"
        exit 1
    fi

    echo "================================"
    echo "🔍 Finding: $pattern"
    echo "================================"
    echo ""

    find . -name "$pattern" -type f 2>/dev/null | sed 's|^\./|  |' || echo "No files found"

    echo ""
}

# List files by extension
list_by_ext() {
    local ext=$1

    if [ -z "$ext" ]; then
        echo "Usage: $0 list <extension>"
        echo "Example: $0 list tsx"
        exit 1
    fi

    echo "================================"
    echo "📋 Files with .$ext extension"
    echo "================================"
    echo ""

    find . -type f -name "*.$ext" 2>/dev/null | sed 's|^\./|  |' | sort || echo "No files found"

    echo ""
}

# Main command handling
case "${1:-help}" in
    help|--help|-h)
        show_usage
        ;;
    analyze)
        analyze_project
        ;;
    search)
        search_files "$2"
        ;;
    find)
        find_files "$2"
        ;;
    list)
        list_by_ext "$2"
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac
