final: prev: {
  python312Packages = prev.python312Packages // {
    slack-sdk = prev.python312Packages.slack-sdk.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
  };
}