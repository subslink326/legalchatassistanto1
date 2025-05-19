#!/usr/bin/env python
"""
Database migration script for creating and applying Alembic migrations.
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

# Ensure script is run from project root
project_root = Path(__file__).resolve().parent.parent
os.chdir(project_root)

# Define command line arguments
parser = argparse.ArgumentParser(description="Database migration utility")
subparsers = parser.add_subparsers(dest="command", help="Commands")

# Create migration command
create_parser = subparsers.add_parser("create", help="Create a new migration")
create_parser.add_argument("name", help="Name of the migration")

# Apply migrations command
apply_parser = subparsers.add_parser("upgrade", help="Apply migrations")
apply_parser.add_argument("--sql", action="store_true", help="Generate SQL instead of applying")
apply_parser.add_argument("--revision", default="head", help="Revision to upgrade to (default: head)")

# History command
history_parser = subparsers.add_parser("history", help="Show migration history")

# Rollback command
rollback_parser = subparsers.add_parser("downgrade", help="Rollback migrations")
rollback_parser.add_argument("--revision", default="-1", help="Revision to downgrade to (default: -1)")

# Parse arguments
args = parser.parse_args()

# Execute command
if args.command == "create":
    subprocess.run(["alembic", "revision", "--autogenerate", "-m", args.name])
elif args.command == "upgrade":
    if args.sql:
        subprocess.run(["alembic", "upgrade", args.revision, "--sql"])
    else:
        subprocess.run(["alembic", "upgrade", args.revision])
elif args.command == "history":
    subprocess.run(["alembic", "history"])
elif args.command == "downgrade":
    subprocess.run(["alembic", "downgrade", args.revision])
else:
    parser.print_help()
    sys.exit(1)
