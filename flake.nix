{

  description =
    "Cabal plugin for the Universiteit Utrecht Attribute Grammar System";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/master"; };
  outputs = inputs@{ self, nixpkgs, ... }:
    let
      homepage = "https://github.com/UU-ComputerScience/uuagc";
      license = nixpkgs.lib.licenses.bsd3;
      # GENERAL
      supportedSystems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = system: nixpkgs.legacyPackages.${system};

      mkDevEnv = system:
        let pkgs = nixpkgsFor system;
        in pkgs.stdenv.mkDerivation {
          name = "Standard-Dev-Environment-with-Utils";
          buildInputs = (with pkgs; [ ]);
        };

      haskell = rec {
        projectFor = system:
          let
            pkgs = nixpkgsFor system;
            stdDevEnv = mkDevEnv system;
            haskell-pkgs = pkgs.haskellPackages;
            #      Nix will automatically read the build-depends field in the *.cabal file to get the name of the dependencies
            # and use the haskell packages provided in the configured package set provided by nix
            project = haskell-pkgs.developPackage {
              name = "uuagc-cabal-1.3.0.0";
              root = ./uuagc/trunk/cabal-plugin/.;

              modifier = drv:
                pkgs.haskell.lib.addBuildTools drv (stdDevEnv.buildInputs);
            };

          in project;
      };

    in {
      haskell = perSystem (system: (haskell.projectFor system));

      devShells = perSystem (system: {
        # Enter shell by "nix develop"
        default = let project = self.haskell.${system};
        in project.env.overrideAttrs (oldAttrs: {

          shellHook = ''
            ${oldAttrs.shellHook}
            export PATH=$PATH:${project}/bin
          '';
        });
      });

      # To be executed by"nix build"
      packages = perSystem (system: { default = self.haskell.${system}; });

    };
}
