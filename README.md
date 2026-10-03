# Web Artisan Pro for Nix

Nix flake for the upcoming version 2 of Web Artisan Pro on x86_64 and aarch64 Linux,
built from the release archives on `cdn.web-artisan.pro`.
The app is proprietary: `meta.license` is `unfree`.

If you're here, it's your lucky day! Please don't tell your friends (yet).

| Channel | Flake output and overlay attribute |
|---|---|
| stable | `web-artisan-pro`, also the `default` output |
| beta | `web-artisan-pro-beta` |

`web-artisan-pro` and `default` appear with the first stable release.

## Profile

```sh
nix profile install github:VyacheArt/web-artisan-pro2-nix#web-artisan-pro-beta
nix profile upgrade web-artisan-pro-beta
```

The flake's own packages allow the unfree license, so no flags are needed.

To run without installing:

```sh
nix run github:VyacheArt/web-artisan-pro2-nix#web-artisan-pro-beta
```

## NixOS

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    web-artisan-pro = {
      url = "github:VyacheArt/web-artisan-pro2-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, web-artisan-pro, ... }:
    {
      nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
          web-artisan-pro.nixosModules.default
          (
            { lib, pkgs, ... }:
            {
              nixpkgs.overlays = [ web-artisan-pro.overlays.default ];
              nixpkgs.config.allowUnfreePredicate =
                pkg: builtins.elem (lib.getName pkg) [ "web-artisan-pro" ];
              programs.web-artisan-pro = {
                enable = true;
                package = pkgs.web-artisan-pro-beta;
              };
            }
          )
        ];
      };
    };
}
```

The overlay and the module build the package with your nixpkgs, so your
`allowUnfree` settings apply. `programs.web-artisan-pro.package` defaults to
the stable release; until the first one it has no default.

To update:

```sh
nix flake update web-artisan-pro
sudo nixos-rebuild switch
```

With home-manager, add the same overlay and predicate and put
`pkgs.web-artisan-pro-beta` into `home.packages`.

## Other distributions

Outside NixOS, Nix packages do not see the system GPU drivers; run the app
through [nixGL](https://github.com/nix-community/nixGL).

## Maintenance

`update.sh` rebuilds `sources.json` from the release manifests; it needs
`curl`, `jq` and `nix`. The Update workflow runs it after each release,
updates `flake.lock` and commits both once the x86_64 and aarch64 builds
pass.

## License

The Nix expressions here are under the MIT License, see [LICENSE](LICENSE).
Web Artisan Pro itself is proprietary software of PE Goriunov Viacheslav.
