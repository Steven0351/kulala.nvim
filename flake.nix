{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        { self', pkgs, ... }:
        let
          version = self.rev or self.dirtyShortRev or self.lastModifiedDate;
        in
        {

          packages.kulala-nvim = pkgs.vimUtils.buildVimPlugin {
            inherit version;
            pname = "kulala-nvim";
            src = ./.;

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
            src = ./lua/tree-sitter;
            generate = true;
          };

          packages.default = self'.packages.kulala-nvim;
        };
    };
}
