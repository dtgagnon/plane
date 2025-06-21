{ pkgs, python ? pkgs.python312 }:

let
  inherit (python.pkgs) buildPythonPackage fetchPypi;
in
{
  # Django-crum: Django utilities for handling current request/user
  django-crum = buildPythonPackage rec {
    pname = "django-crum";
    version = "0.7.9";
    
    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-Zem8DwcKZj+vxNnjV/Rf1ObwGDiyCp4vt2cPVwZ1Qog=";
    };
    
    nativeBuildInputs = with python.pkgs; [
      setuptools
    ];
    
    propagatedBuildInputs = with python.pkgs; [
      django
    ];
    
    # Skip tests and set build requirements
    doCheck = false;
    
    # Fix setuptools-twine requirement
    setuptools_requires = [];
    
    meta = with pkgs.lib; {
      description = "Django utilities for handling current request/user";
      homepage = "https://github.com/ninemoreminutes/django-crum";
      license = licenses.bsd3;
      maintainers = [ ];
    };
  };
  
  # Scout APM: Application Performance Monitoring for Python
  scout-apm = buildPythonPackage rec {
    pname = "scout-apm";
    version = "3.1.0";
    
    src = fetchPypi {
      inherit pname version;
      sha256 = "1xiifbbk793xpha8a30kpry2kfbknm1839m1d3n9ncc4pvwpvgaj";
    };
    
    propagatedBuildInputs = with python.pkgs; [
      requests
      psutil
    ];
    
    # Skip tests for now
    doCheck = false;
    
    meta = with pkgs.lib; {
      description = "Scout Application Performance Monitoring Agent";
      homepage = "https://github.com/scoutapp/scout_apm_python";
      license = licenses.mit;
      maintainers = [ ];
    };
  };
}