{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };
  nix-homebrew = {
    enable = true;
    inherit user;
    # cyril's /opt/homebrew was installed by the official script; let nix-homebrew
    # adopt it while keeping every installed formula and cask.
    autoMigrate = true;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    # steipete/tap provides the imsg formula; kunchenguid/tap provides the
    # pi-launcher cask; keep both declared or zap would untap them.
    taps = [
      { name = "steipete/tap"; }
      { name = "kunchenguid/tap"; }
    ];
    # Everything on this machine must be listed here - zap removes anything that isn't.
    brews = [
      # from the original author's setup
      "herdr"
      # cyril's existing formulas, preserved so zap doesn't uninstall them
      "cliclick"
      "cmake"
      "ffmpeg"
      "gh"
      "git-lfs"
      "mas"
      "neovim"
      "ripgrep"
      "rubberband"
      "steipete/tap/imsg"
      "tesseract-lang"
      "tmux"
      "xcodegen"
      "xcodes"
      "zeroclaw"
    ];
    casks = [
      # from the original author's setup
      "wezterm"
      "claude-code"
      # cyril's existing casks, preserved so zap doesn't uninstall them
      "1password-cli"
      "cc-switch"
      "codex"
      "ghostty"
      "hammerspoon"
      "orbstack"
      "pi-launcher"
    ];
  };
}
