{
  description = "k8s_gateway test with cert-manager";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    inputs@{ self, ... }:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            dig
            go_1_24
            gnumake
            kubectl
            kubernetes-helm
            kind
            tilt
            yq
          ];
        };
      }
    );
}
