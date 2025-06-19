{ pkgs, name, src, workspaceRoot }:

# Build Next.js app for Plane - minimal implementation for now
# TODO: Implement proper Next.js build with yarn workspace support

let
  # Convert app name to binary name (e.g., "plane-web" -> "web") 
  binName = builtins.replaceStrings ["plane-"] [""] name;
  
in pkgs.stdenv.mkDerivation {
  pname = name;
  version = "0.26.1";
  
  # Use the specific app source directory
  src = src;
  
  # Minimal build inputs
  nativeBuildInputs = with pkgs; [
    nodejs
  ];
  
  # Don't run tests during build
  doCheck = false;

  # Skip building for now - just package the source
  buildPhase = ''
    echo "Skipping build phase - packaging source only"
  '';

  installPhase = ''
    # Create directory structure
    mkdir -p $out/bin $out/share/${name}
    
    # Copy the source as-is
    cp -r $src/* $out/share/${name}/
    
    # Create wrapper script for development server
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

PORT=\$\{PORT:-\$DEFAULT_PORT\}
export PORT

echo "Starting ${name} on port \$PORT..."
echo ""
echo "Note: This is a minimal source-only package."
echo "For development, the source is available at: $out/share/${name}/"
echo ""
echo "To run in development mode:"
echo "1. cd $out/share/${name}/"
echo "2. yarn install"
echo "3. yarn dev"
echo ""
echo "Contents of $out/share/${name}/:"
ls -la $out/share/${name}/ 2>/dev/null || echo "Directory not found"
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
