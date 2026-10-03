{
  description = "Web Artisan Pro, packaged from its release archives";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      sources = lib.importJSON ./sources.json;
      hasStable = sources ? stable;
      build = pkgs: source: pkgs.callPackage ./package.nix { inherit source; };

      # Flake outputs share these names with the overlay, because `nix profile`
      # names an entry after its output.
      channels =
        pkgs:
        {
          web-artisan-pro-beta = build pkgs sources.beta;
        }
        // lib.optionalAttrs hasStable { web-artisan-pro = build pkgs sources.stable; };
    in
    {
      # Installing from this flake is consent to the unfree license, so its
      # packages allow it. The overlay and the module leave that to the user.
      packages = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        channels (
          import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          }
        )
        // lib.optionalAttrs hasStable { default = self.packages.${system}.web-artisan-pro; }
      );

      checks = self.packages;

      overlays.default = final: _: channels final;

      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.web-artisan-pro;
        in
        {
          options.programs.web-artisan-pro = {
            enable = lib.mkEnableOption "Web Artisan Pro";
            package = lib.mkOption (
              {
                type = lib.types.package;
                example = lib.literalExpression "pkgs.web-artisan-pro-beta";
                description = "The package to install. The overlay provides `web-artisan-pro-beta` for the beta channel.";
              }
              // lib.optionalAttrs hasStable {
                default = build pkgs sources.stable;
                defaultText = lib.literalMD "the stable release of this flake";
              }
            );
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
          };
        };
    };
}
