{ pkgs, name, src, workspaceRoot }:

# Simple wrapper for Plane frontend apps - development mode until proper build is implemented

let
  # Convert app name to binary name (e.g., "plane-web" -> "web") 
  binName = builtins.replaceStrings ["plane-"] [""] name;
  
in pkgs.stdenv.mkDerivation {
  pname = name;
  version = "0.26.1";
  
  # Use the specific app source directory
  src = src;
  
  # Build inputs  
  nativeBuildInputs = with pkgs; [
    nodejs
    yarn
  ];
  
  # Don't run tests during build
  doCheck = false;

  # Build phase - install dependencies
  buildPhase = ''
    echo "Preparing ${name} for development deployment..."
    
    # Check if workspaceRoot has package.json and node_modules
    if [ -f "${workspaceRoot}/package.json" ] && [ -d "${workspaceRoot}/node_modules" ]; then
      echo "Using workspace dependencies from ${workspaceRoot}"
      
      # Copy node_modules from workspaceRoot to prevent runtime downloads
      mkdir -p node_modules
      cp -r ${workspaceRoot}/node_modules/* node_modules/
      
      # Also copy over workspace packages that might be referenced
      if [ -d "${workspaceRoot}/packages" ]; then
        echo "Copying workspace packages"
        mkdir -p node_modules/@plane
        for dir in ${workspaceRoot}/packages/*; do
          if [ -d "$dir" ]; then
            pkg_name=$(basename "$dir")
            echo "Copying @plane/$pkg_name"
            cp -r "$dir" node_modules/@plane/"$pkg_name" || true
          fi
        done
      fi
    else
      echo "WARNING: No workspace dependencies found. Services may fail to start."
      echo "This package requires a fully built Plane monorepo workspace."
    fi
  '';

  installPhase = ''
    # Create directory structure
    mkdir -p $out/bin $out/share/${name}
    
    # Copy the source
    cp -r $src/* $out/share/${name}/
    
    # Copy node_modules if they exist
    if [ -d "node_modules" ]; then
      echo "Copying node_modules to $out/share/${name}/"
      cp -r node_modules $out/share/${name}/
    fi
    
    # Create startup script that runs a development server without using EOF heredoc to avoid escape issues
    cat > $out/bin/plane-${binName} << EOF

#!/usr/bin/env bash
set -e

# Set default port based on app
case "${binName}" in
  "web")
    DEFAULT_PORT=3000
    ;;
  "space") 
    DEFAULT_PORT=3002
    ;;
  "admin")
    DEFAULT_PORT=3001
    ;;
  "live")
    DEFAULT_PORT=3003
    ;;
  *)
    DEFAULT_PORT=3000
    ;;
esac

PORT="''${PORT:-$DEFAULT_PORT}"
export PORT

echo "Starting ${name} development server on port ''$PORT..."
echo "Source directory: $out/share/${name}/"

# Change to app directory - use the actual path, not $out variable
cd $out/share/${name}

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  ${pkgs.yarn}/bin/yarn install --frozen-lockfile || {
    echo "Warning: Failed to install dependencies with --frozen-lockfile, trying without..."
    ${pkgs.yarn}/bin/yarn install
  }
else
  echo "Node modules directory found, skipping dependency installation"
fi

# Start development server
echo "Starting Next.js development server..."
exec ${pkgs.yarn}/bin/yarn dev --port "$PORT"
EOF
    chmod +x $out/bin/plane-${binName}
    
    # Create compatibility symlink with short name
    ln -s $out/bin/plane-${binName} $out/bin/${binName}
  '';

  meta = with pkgs.lib; {
    description = "Plane ${name} Next.js frontend (source only)";
    homepage = "https://plane.so";
    license = licenses.agpl3Plus;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
