{
  description = "Development environment for git-tips";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            go-task
            gitleaks
            markdownlint-cli
            pre-commit
            shellcheck
            yamllint
          ];

          shellHook = ''
            pre-commit install --install-hooks >/dev/null
          '';
        };
      });
}
