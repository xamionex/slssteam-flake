{
  description = "SLSsteam flake for LD_AUDIT with Steam";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;  # Needed for Steam dependencies
        };
      in
      {
        formatter = pkgs.nixfmt-rfc-style;
        
        packages.default = pkgs.pkgsi686Linux.stdenv.mkDerivation rec {
          pname = "SLSsteam";
          version = "0.1.0";

          # Clone directly from GitHub
          src = pkgs.fetchFromGitHub {
            owner = "AceSLS";
            repo = "SLSsteam";
            rev = "master";  # Or specific commit/tag
            sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Use fake hash first
          };

          # Get the correct hash with:
          # nix-prefetch-url --unpack https://github.com/AceSLS/SLSsteam/archive/master.tar.gz
          # Then replace above

          nativeBuildInputs = with pkgs.pkgsi686Linux; [
            gnumake  # Use gnumake instead of make
          ];

          buildInputs = with pkgs.pkgsi686Linux; [
            openssl
          ];

          buildPhase = ''
            make
          '';

          installPhase = ''
            mkdir -p $out/lib
            cp bin/SLSsteam.so $out/lib/
          '';

          meta = {
            description = "LD_AUDIT module for Steam";
            homepage = "https://github.com/AceSLS/SLSsteam";
            license = with pkgs.lib.licenses; [ agpl3Only ];
          };
        };

        # Add an app to run Steam with SLSsteam
        apps.default = {
          type = "app";
          program = let
            sls = self.packages.${system}.default;
            steam = pkgs.steam;
          in
            pkgs.writeScript "slssteam-run" ''
              #!${pkgs.runtimeShell}
              export LD_AUDIT="${sls}/lib/SLSsteam.so"
              exec ${steam}/bin/steam "$@"
            '';
        };
      }
    );
}
