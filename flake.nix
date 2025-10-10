{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # flake-parts.flakeModules.easyOverlay
        # To import an internal flake module: ./other.nix
        # To import an external flake module:
        #   1. Add foo to inputs
        #   2. Add foo as a parameter to the outputs function
        #   3. Add here: foo.flakeModule

      ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: 
        let version = self.rev or self.dirtyShortRev or self.lastModifiedDate;
        in
        {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.
        packages.kulala-nvim = pkgs.vimUtils.buildVimPlugin {
          inherit version;
          pname = "kulala-nvim";
          # version = self.rev or self.dirtyShortRev or self.lastModified;
          src = ./.;

          dependencies = with pkgs.vimPlugins; [
            nvim-treesitter
            nvim-treesitter-parsers.http
          ];

          buildInputs = [ pkgs.curl ];
          postPatch = ''
            substituteInPlace lua/kulala/config/defaults.lua \
              --replace-fail 'curl_path = "curl"' 'curl_path = "${pkgs.lib.getExe pkgs.curl}"'
          '';

          nvimSkipModules = [
            "cli.kulala_cli"
          ];
        };
 
        packages.kulala-grammar = pkgs.tree-sitter.buildGrammar {
          inherit version;
          language = "kulala_http";
          # version = self'.rev;
          src = ./lua/tree-sitter;
          generate = true;
        };

        packages.default = self'.packages.kulala-nvim;
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
