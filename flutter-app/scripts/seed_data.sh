#!/bin/bash

# Seed Data Script for E-Learning Platform
# Usage: ./seed_data.sh <server_ip> [tenant_id]
# Example: ./seed_data.sh 192.168.1.100 school-001

set -e

# Configuration
SERVER_IP="${1:-localhost}"
TENANT_ID="${2:-school-001}"

# Service ports
AUTH_PORT=8081
NOTES_PORT=8088
MINDMAP_PORT=8087
WORKFLOW_PORT=8086

# Base URLs
AUTH_URL="http://${SERVER_IP}:${AUTH_PORT}"
NOTES_URL="http://${SERVER_IP}:${NOTES_PORT}"
MINDMAP_URL="http://${SERVER_IP}:${MINDMAP_PORT}"
WORKFLOW_URL="http://${SERVER_IP}:${WORKFLOW_PORT}"

echo "=========================================="
echo "Seeding Data for E-Learning Platform"
echo "=========================================="
echo "Server IP: ${SERVER_IP}"
echo "Tenant ID: ${TENANT_ID}"
echo "Auth URL: ${AUTH_URL}"
echo "Notes URL: ${NOTES_URL}"
echo "Mindmap URL: ${MINDMAP_URL}"
echo "Workflow URL: ${WORKFLOW_URL}"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Step 1: Create Users
echo "Step 1: Creating Users..."

declare -a USERS=(
    '{
        "email": "teacher1@school.com",
        "password": "password123",
        "name": "John Smith",
        "role": "TEACHER",
        "tenantId": "'"${TENANT_ID}"'"
    }'
    '{
        "email": "teacher2@school.com",
        "password": "password123",
        "name": "Sarah Johnson",
        "role": "TEACHER",
        "tenantId": "'"${TENANT_ID}"'"
    }'
    '{
        "email": "teacher3@school.com",
        "password": "password123",
        "name": "Michael Brown",
        "role": "TEACHER",
        "tenantId": "'"${TENANT_ID}"'"
    }'
    '{
        "email": "admin@school.com",
        "password": "admin123",
        "name": "Admin User",
        "role": "ADMIN",
        "tenantId": "'"${TENANT_ID}"'"
    }'
    '{
        "email": "demo@school.com",
        "password": "demo123",
        "name": "Demo Teacher",
        "role": "TEACHER",
        "tenantId": "'"${TENANT_ID}"'"
    }'
)

USER_COUNT=0
for user in "${USERS[@]}"; do
    EMAIL=$(echo "$user" | grep -o '"email": "[^"]*"' | cut -d'"' -f4)
    print_info "Creating user: ${EMAIL}"

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${AUTH_URL}/auth/signup" \
        -H "Content-Type: application/json" \
        -d "${user}" 2>/dev/null || echo -e "\n000")

    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [[ "$HTTP_CODE" =~ ^2 ]]; then
        USER_COUNT=$((USER_COUNT + 1))
        print_success "Created user: ${EMAIL}"
    elif [[ "$HTTP_CODE" == "409" ]] || [[ "$BODY" == *"already exists"* ]] || [[ "$BODY" == *"duplicate"* ]]; then
        print_info "User already exists: ${EMAIL}"
        USER_COUNT=$((USER_COUNT + 1))
    else
        print_error "Failed to create user ${EMAIL} (HTTP ${HTTP_CODE})"
    fi
done

echo ""
print_success "Processed ${USER_COUNT} users"
echo ""

# Step 2: Login to get access token (using first teacher)
echo "Step 2: Authenticating..."
print_info "Logging in as teacher1@school.com"

LOGIN_RESPONSE=$(curl -s -X POST "${AUTH_URL}/auth/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"tenantId\": \"${TENANT_ID}\",
        \"identifier\": \"teacher1@school.com\",
        \"password\": \"password123\",
        \"otp\": \"\"
    }" 2>/dev/null || echo '{"error": "Connection failed"}')

# Extract token (adjust based on your API response structure)
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
if [ -z "$ACCESS_TOKEN" ]; then
    ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
fi
if [ -z "$ACCESS_TOKEN" ]; then
    ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
fi

if [ -z "$ACCESS_TOKEN" ]; then
    print_error "Failed to get access token. Response: ${LOGIN_RESPONSE}"
    echo ""
    echo "Continuing without authentication..."
    AUTH_HEADER=""
else
    print_success "Got access token"
    AUTH_HEADER="Authorization: Bearer ${ACCESS_TOKEN}"
fi

echo ""

# Step 3: Seed Notes
echo "Step 3: Creating Notes..."

declare -a NOTES=(
    '{
        "title": "Introduction to Algebra",
        "content": "# Introduction to Algebra\n\n## What is Algebra?\n\nAlgebra is a branch of mathematics that uses symbols and letters to represent numbers and quantities in formulas and equations.\n\n## Key Concepts\n\n1. **Variables** - Letters that represent unknown values\n2. **Constants** - Fixed numerical values\n3. **Expressions** - Combinations of variables and constants\n4. **Equations** - Statements that two expressions are equal\n\n## Basic Operations\n\n- Addition and Subtraction of like terms\n- Multiplication and Division\n- Solving for unknowns\n\n## Examples\n\n```\n2x + 3 = 7\nSolving for x:\n2x = 7 - 3\n2x = 4\nx = 2\n```",
        "summary": "An introduction to basic algebraic concepts including variables, expressions, and equations.",
        "tags": ["math", "algebra", "basics"],
        "status": "DRAFT"
    }'
    '{
        "title": "The Water Cycle",
        "content": "# The Water Cycle\n\n## Overview\n\nThe water cycle, also known as the hydrological cycle, describes the continuous movement of water on, above, and below the surface of the Earth.\n\n## Stages\n\n### 1. Evaporation\nWater from oceans, lakes, and rivers turns into water vapor due to heat from the sun.\n\n### 2. Condensation\nWater vapor rises and cools, forming clouds.\n\n### 3. Precipitation\nWater falls back to Earth as rain, snow, sleet, or hail.\n\n### 4. Collection\nWater collects in oceans, lakes, rivers, and underground.\n\n## Importance\n\n- Provides fresh water\n- Regulates climate\n- Supports all life on Earth",
        "summary": "Learn about the continuous movement of water through evaporation, condensation, precipitation, and collection.",
        "tags": ["science", "water", "environment"],
        "status": "PUBLISHED"
    }'
    '{
        "title": "Photosynthesis Explained",
        "content": "# Photosynthesis\n\n## Definition\n\nPhotosynthesis is the process by which plants, algae, and some bacteria convert light energy into chemical energy stored in glucose.\n\n## The Equation\n\n```\n6CO₂ + 6H₂O + Light Energy → C₆H₁₂O₆ + 6O₂\n```\n\n## Requirements\n\n1. **Sunlight** - Energy source\n2. **Carbon Dioxide** - From the air\n3. **Water** - From the soil\n4. **Chlorophyll** - Green pigment in leaves\n\n## Products\n\n- **Glucose** - Food for the plant\n- **Oxygen** - Released into the atmosphere\n\n## Location\n\nPhotosynthesis occurs in the chloroplasts, specifically in the thylakoid membranes.",
        "summary": "Understanding how plants convert sunlight into food through photosynthesis.",
        "tags": ["biology", "plants", "science"],
        "status": "DRAFT"
    }'
    '{
        "title": "World War II Timeline",
        "content": "# World War II: Key Events\n\n## 1939\n- **September 1**: Germany invades Poland\n- **September 3**: Britain and France declare war on Germany\n\n## 1940\n- **May-June**: Battle of France\n- **July-October**: Battle of Britain\n\n## 1941\n- **June 22**: Germany invades Soviet Union\n- **December 7**: Pearl Harbor attack\n\n## 1942\n- **February**: Battle of Stalingrad begins\n- **June**: Battle of Midway\n\n## 1943\n- **February**: Germans surrender at Stalingrad\n- **July**: Allied invasion of Sicily\n\n## 1944\n- **June 6**: D-Day invasion of Normandy\n- **August**: Liberation of Paris\n\n## 1945\n- **May 8**: V-E Day - Victory in Europe\n- **August 15**: V-J Day - Victory over Japan",
        "summary": "A comprehensive timeline of major events during World War II from 1939 to 1945.",
        "tags": ["history", "wwii", "timeline"],
        "status": "PUBLISHED"
    }'
    '{
        "title": "Introduction to Programming",
        "content": "# Introduction to Programming\n\n## What is Programming?\n\nProgramming is the process of creating instructions that tell a computer what to do.\n\n## Key Concepts\n\n### Variables\nContainers for storing data values.\n\n```python\nname = \"Alice\"\nage = 15\n```\n\n### Data Types\n- Strings: Text data\n- Numbers: Integers and decimals\n- Booleans: True or False\n\n### Control Flow\n- If statements\n- Loops (for, while)\n\n### Functions\nReusable blocks of code.\n\n```python\ndef greet(name):\n    return f\"Hello, {name}!\"\n```\n\n## Popular Languages\n\n1. Python - Great for beginners\n2. JavaScript - Web development\n3. Java - Enterprise applications\n4. C++ - System programming",
        "summary": "Learn the basics of programming including variables, data types, and control flow.",
        "tags": ["programming", "computer science", "basics"],
        "status": "DRAFT"
    }'
    '{
        "title": "Chemical Reactions",
        "content": "# Chemical Reactions\n\n## Definition\n\nA chemical reaction is a process where substances (reactants) are transformed into different substances (products).\n\n## Types of Reactions\n\n### 1. Synthesis (Combination)\nA + B → AB\n\n### 2. Decomposition\nAB → A + B\n\n### 3. Single Replacement\nA + BC → AC + B\n\n### 4. Double Replacement\nAB + CD → AD + CB\n\n### 5. Combustion\nFuel + O₂ → CO₂ + H₂O + Energy\n\n## Balancing Equations\n\nThe law of conservation of mass requires that the number of atoms of each element is the same on both sides of the equation.\n\n## Signs of a Reaction\n\n- Color change\n- Gas production\n- Precipitate formation\n- Temperature change",
        "summary": "An overview of different types of chemical reactions and how to balance equations.",
        "tags": ["chemistry", "reactions", "science"],
        "status": "PUBLISHED"
    }'
)

NOTE_COUNT=0
for note in "${NOTES[@]}"; do
    print_info "Creating note..."

    if [ -n "$AUTH_HEADER" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${NOTES_URL}/notes" \
            -H "Content-Type: application/json" \
            -H "${AUTH_HEADER}" \
            -d "${note}" 2>/dev/null)
    else
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${NOTES_URL}/notes" \
            -H "Content-Type: application/json" \
            -d "${note}" 2>/dev/null)
    fi

    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [[ "$HTTP_CODE" =~ ^2 ]]; then
        NOTE_COUNT=$((NOTE_COUNT + 1))
        TITLE=$(echo "$note" | grep -o '"title": "[^"]*"' | cut -d'"' -f4)
        print_success "Created note: ${TITLE}"
    else
        print_error "Failed to create note (HTTP ${HTTP_CODE})"
    fi
done

echo ""
print_success "Created ${NOTE_COUNT} notes"
echo ""

# Step 4: Seed Mindmaps
echo "Step 4: Creating Mindmaps..."

declare -a MINDMAPS=(
    '{
        "title": "Solar System Overview",
        "description": "A visual map of our solar system and its components",
        "nodes": [
            {"id": "1", "label": "Solar System", "x": 400, "y": 50, "isRoot": true},
            {"id": "2", "label": "Sun", "x": 200, "y": 150},
            {"id": "3", "label": "Inner Planets", "x": 400, "y": 150},
            {"id": "4", "label": "Outer Planets", "x": 600, "y": 150},
            {"id": "5", "label": "Mercury", "x": 250, "y": 250},
            {"id": "6", "label": "Venus", "x": 350, "y": 250},
            {"id": "7", "label": "Earth", "x": 450, "y": 250},
            {"id": "8", "label": "Mars", "x": 550, "y": 250},
            {"id": "9", "label": "Jupiter", "x": 500, "y": 350},
            {"id": "10", "label": "Saturn", "x": 600, "y": 350},
            {"id": "11", "label": "Uranus", "x": 700, "y": 350},
            {"id": "12", "label": "Neptune", "x": 800, "y": 350}
        ],
        "edges": [
            {"source": "1", "target": "2"},
            {"source": "1", "target": "3"},
            {"source": "1", "target": "4"},
            {"source": "3", "target": "5"},
            {"source": "3", "target": "6"},
            {"source": "3", "target": "7"},
            {"source": "3", "target": "8"},
            {"source": "4", "target": "9"},
            {"source": "4", "target": "10"},
            {"source": "4", "target": "11"},
            {"source": "4", "target": "12"}
        ],
        "tags": ["science", "astronomy", "planets"]
    }'
    '{
        "title": "Parts of Speech",
        "description": "English grammar parts of speech and their functions",
        "nodes": [
            {"id": "1", "label": "Parts of Speech", "x": 400, "y": 50, "isRoot": true},
            {"id": "2", "label": "Nouns", "x": 150, "y": 150},
            {"id": "3", "label": "Verbs", "x": 300, "y": 150},
            {"id": "4", "label": "Adjectives", "x": 450, "y": 150},
            {"id": "5", "label": "Adverbs", "x": 600, "y": 150},
            {"id": "6", "label": "Person/Place/Thing", "x": 100, "y": 250},
            {"id": "7", "label": "Common", "x": 200, "y": 250},
            {"id": "8", "label": "Action Words", "x": 300, "y": 250},
            {"id": "9", "label": "Describe Nouns", "x": 450, "y": 250},
            {"id": "10", "label": "Describe Verbs", "x": 600, "y": 250}
        ],
        "edges": [
            {"source": "1", "target": "2"},
            {"source": "1", "target": "3"},
            {"source": "1", "target": "4"},
            {"source": "1", "target": "5"},
            {"source": "2", "target": "6"},
            {"source": "2", "target": "7"},
            {"source": "3", "target": "8"},
            {"source": "4", "target": "9"},
            {"source": "5", "target": "10"}
        ],
        "tags": ["english", "grammar", "language"]
    }'
    '{
        "title": "Cell Structure",
        "description": "Components of a typical animal cell",
        "nodes": [
            {"id": "1", "label": "Animal Cell", "x": 400, "y": 50, "isRoot": true},
            {"id": "2", "label": "Nucleus", "x": 200, "y": 150},
            {"id": "3", "label": "Cytoplasm", "x": 400, "y": 150},
            {"id": "4", "label": "Cell Membrane", "x": 600, "y": 150},
            {"id": "5", "label": "DNA", "x": 150, "y": 250},
            {"id": "6", "label": "Nucleolus", "x": 250, "y": 250},
            {"id": "7", "label": "Mitochondria", "x": 350, "y": 250},
            {"id": "8", "label": "Ribosomes", "x": 450, "y": 250},
            {"id": "9", "label": "ER", "x": 550, "y": 250}
        ],
        "edges": [
            {"source": "1", "target": "2"},
            {"source": "1", "target": "3"},
            {"source": "1", "target": "4"},
            {"source": "2", "target": "5"},
            {"source": "2", "target": "6"},
            {"source": "3", "target": "7"},
            {"source": "3", "target": "8"},
            {"source": "3", "target": "9"}
        ],
        "tags": ["biology", "cells", "science"]
    }'
    '{
        "title": "Mathematical Operations",
        "description": "Overview of basic mathematical operations",
        "nodes": [
            {"id": "1", "label": "Math Operations", "x": 400, "y": 50, "isRoot": true},
            {"id": "2", "label": "Addition", "x": 150, "y": 150},
            {"id": "3", "label": "Subtraction", "x": 300, "y": 150},
            {"id": "4", "label": "Multiplication", "x": 500, "y": 150},
            {"id": "5", "label": "Division", "x": 650, "y": 150},
            {"id": "6", "label": "Sum", "x": 150, "y": 250},
            {"id": "7", "label": "Difference", "x": 300, "y": 250},
            {"id": "8", "label": "Product", "x": 500, "y": 250},
            {"id": "9", "label": "Quotient", "x": 650, "y": 250}
        ],
        "edges": [
            {"source": "1", "target": "2"},
            {"source": "1", "target": "3"},
            {"source": "1", "target": "4"},
            {"source": "1", "target": "5"},
            {"source": "2", "target": "6"},
            {"source": "3", "target": "7"},
            {"source": "4", "target": "8"},
            {"source": "5", "target": "9"}
        ],
        "tags": ["math", "operations", "basics"]
    }'
)

MINDMAP_COUNT=0
for mindmap in "${MINDMAPS[@]}"; do
    print_info "Creating mindmap..."

    if [ -n "$AUTH_HEADER" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${MINDMAP_URL}/mindmaps" \
            -H "Content-Type: application/json" \
            -H "${AUTH_HEADER}" \
            -d "${mindmap}" 2>/dev/null)
    else
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${MINDMAP_URL}/mindmaps" \
            -H "Content-Type: application/json" \
            -d "${mindmap}" 2>/dev/null)
    fi

    HTTP_CODE=$(echo "$RESPONSE" | tail -1)

    if [[ "$HTTP_CODE" =~ ^2 ]]; then
        MINDMAP_COUNT=$((MINDMAP_COUNT + 1))
        TITLE=$(echo "$mindmap" | grep -o '"title": "[^"]*"' | cut -d'"' -f4)
        print_success "Created mindmap: ${TITLE}"
    else
        print_error "Failed to create mindmap (HTTP ${HTTP_CODE})"
    fi
done

echo ""
print_success "Created ${MINDMAP_COUNT} mindmaps"
echo ""

# Step 5: Seed Classes (via Workflow Service)
echo "Step 5: Creating Classes..."

declare -a CLASSES=(
    '{
        "name": "Class 8A - Mathematics",
        "description": "8th Grade Mathematics class focusing on algebra and geometry",
        "grade": "8",
        "section": "A",
        "subject": "Mathematics",
        "studentCount": 32
    }'
    '{
        "name": "Class 8B - Science",
        "description": "8th Grade Science class covering physics, chemistry, and biology",
        "grade": "8",
        "section": "B",
        "subject": "Science",
        "studentCount": 30
    }'
    '{
        "name": "Class 9A - English",
        "description": "9th Grade English class focusing on literature and grammar",
        "grade": "9",
        "section": "A",
        "subject": "English",
        "studentCount": 28
    }'
    '{
        "name": "Class 9B - History",
        "description": "9th Grade History class covering world history",
        "grade": "9",
        "section": "B",
        "subject": "History",
        "studentCount": 35
    }'
    '{
        "name": "Class 10A - Computer Science",
        "description": "10th Grade Computer Science class covering programming basics",
        "grade": "10",
        "section": "A",
        "subject": "Computer Science",
        "studentCount": 25
    }'
)

CLASS_COUNT=0
for class_data in "${CLASSES[@]}"; do
    print_info "Creating class..."

    if [ -n "$AUTH_HEADER" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${WORKFLOW_URL}/classes" \
            -H "Content-Type: application/json" \
            -H "${AUTH_HEADER}" \
            -d "${class_data}" 2>/dev/null)
    else
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${WORKFLOW_URL}/classes" \
            -H "Content-Type: application/json" \
            -d "${class_data}" 2>/dev/null)
    fi

    HTTP_CODE=$(echo "$RESPONSE" | tail -1)

    if [[ "$HTTP_CODE" =~ ^2 ]]; then
        CLASS_COUNT=$((CLASS_COUNT + 1))
        NAME=$(echo "$class_data" | grep -o '"name": "[^"]*"' | cut -d'"' -f4)
        print_success "Created class: ${NAME}"
    else
        print_error "Failed to create class (HTTP ${HTTP_CODE})"
    fi
done

echo ""
print_success "Created ${CLASS_COUNT} classes"
echo ""

# Summary
echo "=========================================="
echo "Seeding Complete!"
echo "=========================================="
echo ""
print_header "Users Created:"
echo "  - teacher1@school.com / password123"
echo "  - teacher2@school.com / password123"
echo "  - teacher3@school.com / password123"
echo "  - admin@school.com / admin123"
echo "  - demo@school.com / demo123"
echo ""
print_header "Content Created:"
echo "  - Notes: ${NOTE_COUNT}"
echo "  - Mindmaps: ${MINDMAP_COUNT}"
echo "  - Classes: ${CLASS_COUNT}"
echo ""
echo "You can now use the Flutter app to view this data."
echo "Server IP: ${SERVER_IP}"
echo "=========================================="
