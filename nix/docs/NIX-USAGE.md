# Plane - Nix Package Usage

This document explains how to use the Nix flake-based packaging of Plane, the open-source project management tool.

## Overview

The Nix packaging of Plane consists of several components bundled into a meta-package:

- Backend (Django API server, Celery worker, beat scheduler, and migrator)
- Multiple Next.js frontends (web, space, admin, live)
- Configuration files and helper scripts

## Building Plane with Nix

To build the Plane package:

```bash
nix build .#plane
```

This will create a `result` symlink pointing to the Nix store path containing the built package.

## Using the Plane Package

The Plane meta-package provides a unified CLI entrypoint that can be used to run different components:

```bash
# Show help
./result/bin/plane help

# Run the API server
./result/bin/plane api

# Run the Celery worker
./result/bin/plane worker

# Run the Celery beat scheduler
./result/bin/plane beat

# Run database migrations
./result/bin/plane migrate

# Run the web frontend
./result/bin/plane web

# Run the space frontend
./result/bin/plane space

# Run the admin frontend
./result/bin/plane admin

# Run the realtime/live frontend
./result/bin/plane live

# Set up initial configuration
./result/bin/plane setup
```

## Development Environment

The repository includes direnv integration. When entering the directory, direnv will automatically load the Nix environment defined in the flake.nix file:

1. Ensure you have direnv installed and configured in your shell
2. The `.envrc` file is configured with `use flake`
3. Run `direnv allow` to enable the environment

## Configuration

The package includes sample configuration files located in the Nix store. When running `plane setup`, these files are copied to `$HOME/.plane/` (or the directory specified by `$PLANE_HOME`). The following files are included:

- `.env.example` - Environment variables for configuring Plane components
- `docker-compose.yml` - Docker Compose configuration for database and other services

## Installation

To install Plane permanently on your system using Nix:

```bash
# Install to your user profile
nix profile install .#plane

# Or, install to system profile (requires sudo/root)
sudo nix profile install .#plane
```

After installation, you can run `plane` from anywhere.

## Customization

To modify the Nix packaging:

- `nix/packages/backend.nix` - Django backend packaging
- `nix/packages/frontend.nix` - Next.js frontends packaging 
- `nix/packages/default.nix` - Main meta-package configuration
- `nix/modules/default.nix` - NixOS module definition

## Notes

- The current packaging is focused on production deployment rather than development workflows
- Frontend builds are currently minimal implementations that will be enhanced in future updates
- For development purposes, refer to the project's main README and development setup guides
