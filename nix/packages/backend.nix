{ pkgs, src ? ../apiserver }:

# Plane backend derivation using buildPythonApplication for proper dependency management

let
  python = pkgs.python312;
  
in python.pkgs.buildPythonApplication rec {
  pname = "plane-backend";
  version = "0.26.1"; # Match version from root package.json
  inherit src;
  
  format = "other";  # We don't have a setup.py
  
  # Build inputs for native dependencies
  nativeBuildInputs = with pkgs; [
    pkg-config
  ];
  
  buildInputs = with pkgs; [
    libxml2
    libxslt
    postgresql
    xmlsec
    libffi
    openssl
  ];

  # Python dependencies based on requirements/base.txt and requirements/production.txt
  propagatedBuildInputs = with python.pkgs; [
    # Django core
    django
    djangorestframework
    
    # Database
    psycopg
    dj-database-url
    
    # Redis
    redis
    django-redis
    
    # CORS
    django-cors-headers
    
    # Celery
    celery
    django-celery-beat
    django-celery-results
    python-json-logger # For JSON formatting in Celery logs
    
    # File serving
    whitenoise
    
    # Web server
    gunicorn
    uvicorn
    
    # Utilities
    faker
    django-filter
    django-storages
    
    # Communication
    channels
    
    # Integrations
    openai
    
    # File processing
    openpyxl
    beautifulsoup4
    lxml
    
    # Cloud storage
    boto3
    
    # Security & crypto
    cryptography
    pyjwt
    
    # Timezone
    pytz
    
    # Core dependencies
    requests
    pillow
    setuptools
    wheel
    pip
  ];

  # Don't run tests during build
  doCheck = false;
  
  # Build phase: prepare the Django application
  buildPhase = ''
    # Nothing to build for Django app
    true
  '';

  installPhase = ''
    # Create directory structure
    mkdir -p $out/bin $out/share/plane/backend
    
    # Copy Django application source
    cp -r $src/* $out/share/plane/backend/
    
    # Create wrapper scripts for different services
    cat > $out/bin/plane-api << EOF
#!/usr/bin/env bash
set -e
cd $out/share/plane/backend
export PYTHONPATH=$out/share/plane/backend:${python.pkgs.makePythonPath propagatedBuildInputs}:\$PYTHONPATH


# Wait for database
${python}/bin/python manage.py wait_for_db

# Wait for migrations  
${python}/bin/python manage.py wait_for_migrations

# Generate machine signature
HOSTNAME=\$(hostname)
MAC_ADDRESS=\$(ip link show 2>/dev/null | awk '/ether/ {print \$2}' | head -n 1 || echo "unknown")
CPU_INFO=\$(cat /proc/cpuinfo 2>/dev/null || echo "unknown")
MEMORY_INFO=\$(free -h 2>/dev/null || echo "unknown")
DISK_INFO=\$(df -h 2>/dev/null || echo "unknown")

SIGNATURE=\$(echo "\$HOSTNAME\$MAC_ADDRESS\$CPU_INFO\$MEMORY_INFO\$DISK_INFO" | sha256sum | awk '{print \$1}')
export MACHINE_SIGNATURE=\$SIGNATURE

# Register instance
${python}/bin/python manage.py register_instance "\$MACHINE_SIGNATURE"

# Configure instance
${python}/bin/python manage.py configure_instance

# Create default bucket
${python}/bin/python manage.py create_bucket

# Clear cache
${python}/bin/python manage.py clear_cache

# Start gunicorn server
exec ${python.pkgs.gunicorn}/bin/gunicorn \\
  -w "\$\{GUNICORN_WORKERS:-4\}" \\
  -k uvicorn.workers.UvicornWorker \\
  plane.asgi:application \\
  --bind 0.0.0.0:"\$\{PORT:-8000\}" \\
  --max-requests 1200 \\
  --max-requests-jitter 1000 \\
  --access-logfile -
EOF
    chmod +x $out/bin/plane-api

    cat > $out/bin/plane-worker << EOF
#!/usr/bin/env bash
set -e
cd $out/share/plane/backend
export PYTHONPATH=$out/share/plane/backend:${python.pkgs.makePythonPath propagatedBuildInputs}:\$PYTHONPATH


exec ${python.pkgs.celery}/bin/celery \\
  -A plane.celery worker \\
  -l info \\
  --max-memory-per-child 200000
EOF
    chmod +x $out/bin/plane-worker

    cat > $out/bin/plane-beat << EOF
#!/usr/bin/env bash
set -e
cd $out/share/plane/backend
export PYTHONPATH=$out/share/plane/backend:${python.pkgs.makePythonPath propagatedBuildInputs}:\$PYTHONPATH


exec ${python.pkgs.celery}/bin/celery \\
  -A plane.celery beat \\
  -l info \\
  --scheduler django_celery_beat.schedulers:DatabaseScheduler
EOF
    chmod +x $out/bin/plane-beat

    cat > $out/bin/plane-migrate << EOF
#!/usr/bin/env bash
set -e
cd $out/share/plane/backend
export PYTHONPATH=$out/share/plane/backend:${python.pkgs.makePythonPath propagatedBuildInputs}:\$PYTHONPATH


echo "Running Django migrations..."

# Check Django installation
${python}/bin/python -c "import django; print(f'Django version: {django.get_version()}')"

# Run basic Django commands
${python}/bin/python manage.py check --deploy 2>/dev/null || ${python}/bin/python manage.py check

# Run migrations
${python}/bin/python manage.py migrate

echo "Migrations completed successfully"
EOF
    chmod +x $out/bin/plane-migrate

    # Create compatibility symlinks for old names
    ln -s $out/bin/plane-api $out/bin/api
    ln -s $out/bin/plane-worker $out/bin/worker  
    ln -s $out/bin/plane-beat $out/bin/beat
    ln -s $out/bin/plane-migrate $out/bin/migrate
  '';

  meta = with pkgs.lib; {
    description = "Plane backend (Django + Celery)";
    homepage = "https://plane.so";
    license = licenses.agpl3Plus;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
