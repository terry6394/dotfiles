{ user, machine, ... }:

let
  # Software split into two tiers:
  # - common*: every machine gets these (core workflow, agents, security).
  # - machine*: only the named machine gets these (dev toolchains, media, etc.).
  # Add a new machine by extending the attrsets below and setting `machine` in
  # flake.nix on that machine. Nothing here is removed by zap unless it falls
  # out of both tiers on that machine.
  commonBrews = [
    "herdr"
    "gh"
    "neovim"
  ];

  commonCasks = [
    "wezterm"
    "claude-code"
    "1password-cli"
    "codex"
    "pi-launcher"
  ];

  commonTaps = [
    { name = "kunchenguid/tap"; trusted = true; }
  ];

  machineBrews = {
    desk = [
      "cliclick"
      "cmake"
      "ffmpeg"
      "git-lfs"
      "mas"
      "rubberband"
      "sdl2-compat"  # required by ffmpeg; zap would otherwise uninstall it every switch
      "sshpass"
      "steipete/tap/imsg"
      "tesseract-lang"
      "xcodegen"
      "xcodes"
    ];
  };

  machineCasks = {
    desk = [
      "cc-switch"
      "ghostty"
      "orbstack"
    ];
  };

  machineTaps = {
    desk = [
      # steipete/tap provides imsg; farion1231/ccswitch provides cc-switch;
      # hudochenkov/sshpass provides sshpass. Keep them declared (or zap would
      # untap them) and trusted (Homebrew 6.0 requires tap trust).
      { name = "steipete/tap"; trusted = true; }
      { name = "farion1231/ccswitch"; trusted = true; }
      { name = "hudochenkov/sshpass"; trusted = true; }
    ];
  };
in

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
    dock.autohide = false;   # keep the Dock always visible (user preference)
    dock.tilesize = 39;      # small Dock icons (user's current size)
    dock.magnification = false;  # no icon zoom on hover (user preference)
    finder.AppleShowAllFiles = true;       # show hidden files
    finder.ShowPathbar = true;             # path bar at bottom of Finder windows
    finder.ShowStatusBar = true;           # item count / disk space at bottom
    finder.FXDefaultSearchScope = "SCcf";  # search the current folder by default
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
    # Homebrew 6.0 requires third-party taps to be trusted (see taps above).
    taps = commonTaps ++ (machineTaps.${machine} or []);
    # Everything on this machine must be listed here - zap removes anything that isn't.
    brews = commonBrews ++ (machineBrews.${machine} or []);
    casks = commonCasks ++ (machineCasks.${machine} or []);
  };
}
