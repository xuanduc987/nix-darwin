{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cachix-agent;
in {
  options.services.cachix-agent = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable to run Cachix Agent as a system service.
        
        Read <link xlink:href="https://docs.cachix.org/deploy/">Cachix Deploy</link> documentation for more information.
      '';
    };

    name = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = ''
        Agent name, usually the same as the hostname.
      '';
    };

    package = mkOption {
      description = ''
        Package containing cachix executable.
      '';
      type = types.package;
      default = pkgs.cachix;
      defaultText = literalExample "pkgs.cachix";
    };

    credentialsFile = mkOption {
      type = types.path;
      default = "/etc/cachix-agent.token";
      description = ''
        Required file that needs to contain CACHIX_AGENT_TOKEN=...
      '';
    };

    logFile = mkOption {
      type = types.nullOr types.path;
      default = "/var/log/cachix-agent.log";
      description = "Absolute path to log all stderr and stdout";
    };
  };

  config = mkIf cfg.enable {
    launchd.daemons.cachix-agent = {
      script = ''
        . ${cfg.credentialsFile}

        exec ${cfg.package}/bin/cachix deploy agent ${cfg.name}
      '';

      path = [ config.nix.package pkgs.coreutils ];

      environment = {
        NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        USER = "root";
      };

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
      serviceConfig.ProcessType = "Interactive";
      serviceConfig.StandardErrorPath = cfg.logFile;
      serviceConfig.StandardOutPath = cfg.logFile;
      serviceConfig.WatchPaths = [
        cfg.credentialsFile
      ];
    };
  };
}
