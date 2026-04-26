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
    ciHook = ''
      set -euo pipefail
      # Install vendored Mermaid bundle next to book.toml (required by book.toml additional-js)
      mdbook-mermaid install
      mdbook build
      exit
    '';
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
          echo "CI-style build (exit):    nix develop .#ci"
          echo ""
        '';
      };

      ci = pkgs.mkShell {
        packages = mdBookDeps pkgs;
        shellHook = ciHook;
      };
    });
  };
}
