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
          config.allowUnfree = true;
        };
        i686 = pkgs.pkgsi686Linux;
      in
      {
        formatter = pkgs.nixfmt-rfc-style;
        
        packages.default = i686.stdenv.mkDerivation rec {
          pname = "SLSsteam";
          version = "0.1.0";

          src = pkgs.fetchFromGitHub {
            owner = "AceSLS";
            repo = "SLSsteam";
            rev = "master";
            sha256 = "sha256-Fj2chghqMYq0qz0sN7Pz3eFsUpcHmzhTIDgu7fCzqKY="; # Update with actual hash
          };

          nativeBuildInputs = with i686; [
            gnumake
            patchelf
          ];

          buildInputs = with i686; [
            openssl
          ];

          hardeningDisable = ["format"];

          buildPhase = ''
            make
          '';

          installPhase = ''
            mkdir -p $out/lib
            cp bin/SLSsteam.so $out/lib/
            
            # Set proper RPATH
            patchelf --set-rpath "${i686.lib.makeLibraryPath buildInputs}" \
              $out/lib/SLSsteam.so
          '';

          meta = {
            description = "LD_AUDIT module for Steam";
            homepage = "https://github.com/AceSLS/SLSsteam";
            license = with pkgs.lib.licenses; [ agpl3Only ];
          };
        };

        # Fixed app definition
        apps.default = let
          sls = self.packages.${system}.default;
          steam = pkgs.steam;
        in {
          type = "app";
          program = toString (pkgs.writeScript "slssteam-run" ''
            #!${pkgs.runtimeShell} -e
            export LD_AUDIT="${sls}/lib/SLSsteam.so"
            exec ${steam}/bin/steam "$@"
          '');
        };
      }
    );
}
