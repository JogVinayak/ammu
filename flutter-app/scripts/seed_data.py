#!/usr/bin/env python3
"""
Seed Data Script for E-Learning Platform

Usage:
    python seed_data.py <server_ip> [tenant_id]

Example:
    python seed_data.py 192.168.1.100 school-001
"""

import sys
import json
import requests
from datetime import datetime

# Configuration
SERVER_IP = sys.argv[1] if len(sys.argv) > 1 else "localhost"
TENANT_ID = sys.argv[2] if len(sys.argv) > 2 else "school-001"

# Service ports
AUTH_PORT = 8081
NOTES_PORT = 8088
MINDMAP_PORT = 8087
WORKFLOW_PORT = 8086

# Base URLs
AUTH_URL = f"http://{SERVER_IP}:{AUTH_PORT}"
NOTES_URL = f"http://{SERVER_IP}:{NOTES_PORT}"
MINDMAP_URL = f"http://{SERVER_IP}:{MINDMAP_PORT}"
WORKFLOW_URL = f"http://{SERVER_IP}:{WORKFLOW_PORT}"

# Colors
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
NC = '\033[0m'

def print_success(msg):
    print(f"{GREEN}✓ {msg}{NC}")

def print_error(msg):
    print(f"{RED}✗ {msg}{NC}")

def print_info(msg):
    print(f"{YELLOW}→ {msg}{NC}")

def print_header(msg):
    print(f"{BLUE}{msg}{NC}")

# Sample Users Data
USERS = [
    {
        "email": "teacher1@school.com",
        "password": "password123",
        "name": "John Smith",
        "role": "TEACHER",
        "tenantId": TENANT_ID
    },
    {
        "email": "teacher2@school.com",
        "password": "password123",
        "name": "Sarah Johnson",
        "role": "TEACHER",
        "tenantId": TENANT_ID
    },
    {
        "email": "teacher3@school.com",
        "password": "password123",
        "name": "Michael Brown",
        "role": "TEACHER",
        "tenantId": TENANT_ID
    },
    {
        "email": "admin@school.com",
        "password": "admin123",
        "name": "Admin User",
        "role": "ADMIN",
        "tenantId": TENANT_ID
    },
    {
        "email": "demo@school.com",
        "password": "demo123",
        "name": "Demo Teacher",
        "role": "TEACHER",
        "tenantId": TENANT_ID
    }
]

# Sample Notes Data
NOTES = [
    {
        "title": "Introduction to Algebra",
        "content": """# Introduction to Algebra

## What is Algebra?

Algebra is a branch of mathematics that uses symbols and letters to represent numbers and quantities in formulas and equations.

## Key Concepts

1. **Variables** - Letters that represent unknown values
2. **Constants** - Fixed numerical values
3. **Expressions** - Combinations of variables and constants
4. **Equations** - Statements that two expressions are equal

## Basic Operations

- Addition and Subtraction of like terms
- Multiplication and Division
- Solving for unknowns

## Examples

```
2x + 3 = 7
Solving for x:
2x = 7 - 3
2x = 4
x = 2
```""",
        "summary": "An introduction to basic algebraic concepts including variables, expressions, and equations.",
        "tags": ["math", "algebra", "basics"],
        "status": "DRAFT"
    },
    {
        "title": "The Water Cycle",
        "content": """# The Water Cycle

## Overview

The water cycle, also known as the hydrological cycle, describes the continuous movement of water on, above, and below the surface of the Earth.

## Stages

### 1. Evaporation
Water from oceans, lakes, and rivers turns into water vapor due to heat from the sun.

### 2. Condensation
Water vapor rises and cools, forming clouds.

### 3. Precipitation
Water falls back to Earth as rain, snow, sleet, or hail.

### 4. Collection
Water collects in oceans, lakes, rivers, and underground.

## Importance

- Provides fresh water
- Regulates climate
- Supports all life on Earth""",
        "summary": "Learn about the continuous movement of water through evaporation, condensation, precipitation, and collection.",
        "tags": ["science", "water", "environment"],
        "status": "PUBLISHED"
    },
    {
        "title": "Photosynthesis Explained",
        "content": """# Photosynthesis

## Definition

Photosynthesis is the process by which plants, algae, and some bacteria convert light energy into chemical energy stored in glucose.

## The Equation

```
6CO₂ + 6H₂O + Light Energy → C₆H₁₂O₆ + 6O₂
```

## Requirements

1. **Sunlight** - Energy source
2. **Carbon Dioxide** - From the air
3. **Water** - From the soil
4. **Chlorophyll** - Green pigment in leaves

## Products

- **Glucose** - Food for the plant
- **Oxygen** - Released into the atmosphere""",
        "summary": "Understanding how plants convert sunlight into food through photosynthesis.",
        "tags": ["biology", "plants", "science"],
        "status": "DRAFT"
    },
    {
        "title": "World War II Timeline",
        "content": """# World War II: Key Events

## 1939
- **September 1**: Germany invades Poland
- **September 3**: Britain and France declare war on Germany

## 1940
- **May-June**: Battle of France
- **July-October**: Battle of Britain

## 1941
- **June 22**: Germany invades Soviet Union
- **December 7**: Pearl Harbor attack

## 1944
- **June 6**: D-Day invasion of Normandy
- **August**: Liberation of Paris

## 1945
- **May 8**: V-E Day - Victory in Europe
- **August 15**: V-J Day - Victory over Japan""",
        "summary": "A comprehensive timeline of major events during World War II from 1939 to 1945.",
        "tags": ["history", "wwii", "timeline"],
        "status": "PUBLISHED"
    },
    {
        "title": "Introduction to Programming",
        "content": """# Introduction to Programming

## What is Programming?

Programming is the process of creating instructions that tell a computer what to do.

## Key Concepts

### Variables
Containers for storing data values.

```python
name = "Alice"
age = 15
```

### Data Types
- Strings: Text data
- Numbers: Integers and decimals
- Booleans: True or False

### Functions
Reusable blocks of code.

```python
def greet(name):
    return f"Hello, {name}!"
```

## Popular Languages

1. Python - Great for beginners
2. JavaScript - Web development
3. Java - Enterprise applications""",
        "summary": "Learn the basics of programming including variables, data types, and control flow.",
        "tags": ["programming", "computer science", "basics"],
        "status": "DRAFT"
    },
    {
        "title": "Chemical Reactions",
        "content": """# Chemical Reactions

## Definition

A chemical reaction is a process where substances (reactants) are transformed into different substances (products).

## Types of Reactions

### 1. Synthesis (Combination)
A + B → AB

### 2. Decomposition
AB → A + B

### 3. Single Replacement
A + BC → AC + B

### 4. Double Replacement
AB + CD → AD + CB

## Signs of a Reaction

- Color change
- Gas production
- Precipitate formation
- Temperature change""",
        "summary": "An overview of different types of chemical reactions and how to balance equations.",
        "tags": ["chemistry", "reactions", "science"],
        "status": "PUBLISHED"
    }
]

# Sample Mindmaps Data
MINDMAPS = [
    {
        "title": "Solar System Overview",
        "description": "A visual map of our solar system and its components",
        "nodes": [
            {"id": "1", "label": "Solar System", "x": 400, "y": 50, "isRoot": True},
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
    },
    {
        "title": "Parts of Speech",
        "description": "English grammar parts of speech and their functions",
        "nodes": [
            {"id": "1", "label": "Parts of Speech", "x": 400, "y": 50, "isRoot": True},
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
    },
    {
        "title": "Cell Structure",
        "description": "Components of a typical animal cell",
        "nodes": [
            {"id": "1", "label": "Animal Cell", "x": 400, "y": 50, "isRoot": True},
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
    },
    {
        "title": "Mathematical Operations",
        "description": "Overview of basic mathematical operations",
        "nodes": [
            {"id": "1", "label": "Math Operations", "x": 400, "y": 50, "isRoot": True},
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
    }
]

# Sample Classes Data (matches CreateClassRequest: name, subject, grade, description)
CLASSES = [
    {
        "name": "Class 8A - Mathematics",
        "description": "8th Grade Mathematics class focusing on algebra and geometry",
        "grade": "8",
        "subject": "Mathematics"
    },
    {
        "name": "Class 8B - Science",
        "description": "8th Grade Science class covering physics, chemistry, and biology",
        "grade": "8",
        "subject": "Science"
    },
    {
        "name": "Class 9A - English",
        "description": "9th Grade English class focusing on literature and grammar",
        "grade": "9",
        "subject": "English"
    },
    {
        "name": "Class 9B - History",
        "description": "9th Grade History class covering world history",
        "grade": "9",
        "subject": "History"
    },
    {
        "name": "Class 10A - Computer Science",
        "description": "10th Grade Computer Science class covering programming basics",
        "grade": "10",
        "subject": "Computer Science"
    }
]


def main():
    print("=" * 50)
    print("Seeding Data for E-Learning Platform")
    print("=" * 50)
    print(f"Server IP: {SERVER_IP}")
    print(f"Tenant ID: {TENANT_ID}")
    print(f"Auth URL: {AUTH_URL}")
    print(f"Notes URL: {NOTES_URL}")
    print(f"Mindmap URL: {MINDMAP_URL}")
    print(f"Workflow URL: {WORKFLOW_URL}")
    print()

    headers = {"Content-Type": "application/json"}

    # Step 1: Create Users
    print("Step 1: Creating Users...")
    user_count = 0
    for user in USERS:
        print_info(f"Creating user: {user['email']}")
        try:
            response = requests.post(
                f"{AUTH_URL}/auth/signup",
                json=user,
                timeout=10
            )
            if response.status_code in [200, 201]:
                user_count += 1
                print_success(f"Created user: {user['email']}")
            elif response.status_code == 409 or "already exists" in response.text.lower():
                print_info(f"User already exists: {user['email']}")
                user_count += 1
            else:
                print_error(f"Failed (HTTP {response.status_code}): {response.text[:100]}")
        except requests.exceptions.ConnectionError:
            print_error("Could not connect to auth service")
        except Exception as e:
            print_error(f"Error: {e}")

    print()
    print_success(f"Processed {user_count} users")
    print()

    # Step 2: Authentication
    print("Step 2: Authenticating...")
    print_info("Logging in as teacher1@school.com")

    access_token = None
    user_id = None
    tenant_id = None
    try:
        response = requests.post(
            f"{AUTH_URL}/auth/login",
            json={
                "tenantId": TENANT_ID,
                "identifier": "teacher1@school.com",
                "password": "password123",
                "otp": ""
            },
            timeout=10
        )
        if response.status_code == 200:
            data = response.json()
            access_token = data.get("accessToken") or data.get("access_token") or data.get("token")
            user_id = data.get("userId")
            tenant_id = data.get("tenantId") or TENANT_ID
            if access_token:
                print_success(f"Got access token (userId={user_id}, tenantId={tenant_id})")
                headers["Authorization"] = f"Bearer {access_token}"
                headers["X-Tenant-Id"] = str(tenant_id)
                if user_id:
                    headers["X-User-Id"] = str(user_id)
            else:
                print_error("No token in response")
        else:
            print_error(f"Login failed: {response.status_code}")
    except requests.exceptions.ConnectionError:
        print_error("Could not connect to auth service")
    except Exception as e:
        print_error(f"Auth error: {e}")

    if not access_token:
        print("Continuing without authentication...")
        headers["X-Tenant-Id"] = TENANT_ID
    print()

    # Step 3: Seed Notes
    print("Step 3: Creating Notes...")
    note_count = 0
    for note in NOTES:
        print_info(f"Creating note: {note['title']}")
        try:
            response = requests.post(
                f"{NOTES_URL}/notes",
                json=note,
                headers=headers,
                timeout=10
            )
            if response.status_code in [200, 201]:
                note_count += 1
                print_success(f"Created note: {note['title']}")
            else:
                print_error(f"Failed (HTTP {response.status_code}): {response.text[:100]}")
        except requests.exceptions.ConnectionError:
            print_error("Could not connect to notes service")
        except Exception as e:
            print_error(f"Error: {e}")

    print()
    print_success(f"Created {note_count} notes")
    print()

    # Step 4: Seed Mindmaps
    print("Step 4: Creating Mindmaps...")
    mindmap_count = 0
    for mindmap in MINDMAPS:
        print_info(f"Creating mindmap: {mindmap['title']}")
        try:
            response = requests.post(
                f"{MINDMAP_URL}/mindmaps",
                json=mindmap,
                headers=headers,
                timeout=10
            )
            if response.status_code in [200, 201]:
                mindmap_count += 1
                print_success(f"Created mindmap: {mindmap['title']}")
            else:
                print_error(f"Failed (HTTP {response.status_code}): {response.text[:100]}")
        except requests.exceptions.ConnectionError:
            print_error("Could not connect to mindmap service")
        except Exception as e:
            print_error(f"Error: {e}")

    print()
    print_success(f"Created {mindmap_count} mindmaps")
    print()

    # Step 5: Seed Classes
    print("Step 5: Creating Classes...")
    class_count = 0
    for cls in CLASSES:
        print_info(f"Creating class: {cls['name']}")
        try:
            response = requests.post(
                f"{WORKFLOW_URL}/classes",
                json=cls,
                headers=headers,
                timeout=10
            )
            if response.status_code in [200, 201]:
                class_count += 1
                print_success(f"Created class: {cls['name']}")
            else:
                print_error(f"Failed (HTTP {response.status_code}): {response.text[:100]}")
        except requests.exceptions.ConnectionError:
            print_error("Could not connect to workflow service")
        except Exception as e:
            print_error(f"Error: {e}")

    print()
    print_success(f"Created {class_count} classes")
    print()

    # Summary
    print("=" * 50)
    print("Seeding Complete!")
    print("=" * 50)
    print()
    print_header("Users Created:")
    print("  - teacher1@school.com / password123")
    print("  - teacher2@school.com / password123")
    print("  - teacher3@school.com / password123")
    print("  - admin@school.com / admin123")
    print("  - demo@school.com / demo123")
    print()
    print_header("Content Created:")
    print(f"  - Notes: {note_count}")
    print(f"  - Mindmaps: {mindmap_count}")
    print(f"  - Classes: {class_count}")
    print()
    print(f"You can now use the Flutter app to view this data.")
    print(f"Server IP: {SERVER_IP}")
    print("=" * 50)


if __name__ == "__main__":
    main()
