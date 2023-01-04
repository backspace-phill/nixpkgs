{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh.ohMyZsh;

  mkLinkFarmEntry = name: dir:
    let
      env = pkgs.buildEnv {
        name = "zsh-${name}-env";
        paths = cfg.customPkgs;
        pathsToLink = "/share/zsh/${dir}";
      };
    in
      { inherit name; path = "${env}/share/zsh/${dir}"; };

  mkLinkFarmEntry' = name: mkLinkFarmEntry name name;

  custom =
    if cfg.custom != null then cfg.custom
    else if length cfg.customPkgs == 0 then null
    else pkgs.linkFarm "oh-my-zsh-custom" [
      (mkLinkFarmEntry' "themes")
      (mkLinkFarmEntry "completions" "site-functions")
      (mkLinkFarmEntry' "plugins")
    ];

in
  {
    imports = [
      (mkRenamedOptionModule [ "programs" "zsh" "oh-my-zsh" "enable" ] [ "programs" "zsh" "ohMyZsh" "enable" ])
      (mkRenamedOptionModule [ "programs" "zsh" "oh-my-zsh" "theme" ] [ "programs" "zsh" "ohMyZsh" "theme" ])
      (mkRenamedOptionModule [ "programs" "zsh" "oh-my-zsh" "custom" ] [ "programs" "zsh" "ohMyZsh" "custom" ])
      (mkRenamedOptionModule [ "programs" "zsh" "oh-my-zsh" "plugins" ] [ "programs" "zsh" "ohMyZsh" "plugins" ])
    ];

    options = {
      programs.zsh.ohMyZsh = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc ''
            Enable oh-my-zsh.
          '';
        };

        package = mkOption {
          default = pkgs.oh-my-zsh;
          defaultText = literalExpression "pkgs.oh-my-zsh";
          description = lib.mdDoc ''
            Package to install for `oh-my-zsh` usage.
          '';

          type = types.package;
        };

        plugins = mkOption {
          default = [];
          type = types.listOf(types.str);
          description = lib.mdDoc ''
            List of oh-my-zsh plugins
          '';
        };

        custom = mkOption {
          default = null;
          type = with types; nullOr str;
          description = lib.mdDoc ''
            Path to a custom oh-my-zsh package to override config of oh-my-zsh.
            (Can't be used along with `customPkgs`).
          '';
        };

        customPkgs = mkOption {
          default = [];
          type = types.listOf types.package;
          description = lib.mdDoc ''
            List of custom packages that should be loaded into `oh-my-zsh`.
          '';
        };

        theme = mkOption {
          default = "";
          type = types.str;
          description = lib.mdDoc ''
            Name of the theme to be used by oh-my-zsh.
          '';
        };

        cacheDir = mkOption {
          default = "$HOME/.cache/oh-my-zsh";
          type = types.str;
          description = lib.mdDoc ''
            Cache directory to be used by `oh-my-zsh`.
            Without this option it would default to the read-only nix store.
          '';
        };
      };
    };

    config = mkIf cfg.enable {

      # Prevent zsh from overwriting oh-my-zsh's prompt
      programs.zsh.promptInit = mkDefault "";

      environment.systemPackages = [ cfg.package ];

      programs.zsh.interactiveShellInit = ''
        # oh-my-zsh configuration generated by NixOS
        export ZSH=${cfg.package}/share/oh-my-zsh

        ${optionalString (length(cfg.plugins) > 0)
          "plugins=(${concatStringsSep " " cfg.plugins})"
        }

        ${optionalString (custom != null)
          "ZSH_CUSTOM=\"${custom}\""
        }

        ${optionalString (stringLength(cfg.theme) > 0)
          "ZSH_THEME=\"${cfg.theme}\""
        }

        ${optionalString (cfg.cacheDir != null) ''
          if [[ ! -d "${cfg.cacheDir}" ]]; then
            mkdir -p "${cfg.cacheDir}"
          fi
          ZSH_CACHE_DIR=${cfg.cacheDir}
        ''}

        source $ZSH/oh-my-zsh.sh
      '';

      assertions = [
        {
          assertion = cfg.custom != null -> cfg.customPkgs == [];
          message = "If `cfg.custom` is set for `ZSH_CUSTOM`, `customPkgs` can't be used!";
        }
      ];

    };

    # Don't edit the docbook xml directly, edit the md and generate it:
    # `pandoc oh-my-zsh.md -t docbook --top-level-division=chapter --extract-media=media -f markdown+smart --lua-filter ../../../../doc/build-aux/pandoc-filters/myst-reader/roles.lua --lua-filter ../../../../doc/build-aux/pandoc-filters/docbook-writer/rst-roles.lua > oh-my-zsh.xml`
    meta.doc = ./oh-my-zsh.xml;
  }
