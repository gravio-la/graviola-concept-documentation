{
  description = "Graviola conceptual documentation — mdBook toolchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
  let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    mdBookDeps = pkgs: with pkgs; [ mdbook mdbook-mermaid mdbook-toc ];
  in
  {
    devShells = forEachSystem (pkgs: {
      default = pkgs.mkShell {
        packages = mdBookDeps pkgs;
        shellHook = ''
          echo ""
          echo "Graviola conceptual documentation — mdBook"
          echo "=============================================="
          echo "One-time Mermaid assets:  mdbook-mermaid install"
          echo "Build:                    mdbook build"
          echo "Serve:                    mdbook serve --open"
          echo "Non-interactive build:    nix develop --command bash -euo pipefail -c 'mdbook-mermaid install && mdbook build'"
          echo ""
        '';
      };
    });
  };
}
