final: prev: {
  slack-sdk = prev.slack-sdk.overrideAttrs (oldAttrs: {
    doCheck = false;
  });
}