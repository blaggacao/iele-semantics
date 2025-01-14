{ checkMaterialization ? false
, system ? builtins.currentSystem
}:

let
  sources = import ../nix/sources.nix { inherit system; };

  pkgs =
    let
      haskell-nix = import sources."haskell.nix" { inherit system; };
      inherit (haskell-nix) nixpkgsArgs;
      args = nixpkgsArgs // { inherit system; };
    in import haskell-nix.sources.nixpkgs args;
  inherit (pkgs) lib haskell-nix;

  project = (args: haskell-nix.stackProject args) {
    inherit checkMaterialization;
    materialized = ../nix/iele-assemble.nix.d;
    src = haskell-nix.haskellLib.cleanGit { src = ./..; subDir = "iele-assemble"; };
  };

  rematerialize = pkgs.writeScript "rematerialize.sh" ''
    #!/bin/sh
    ${project.stack-nix.passthru.updateMaterialized}
  '';

  default =
    {
      inherit pkgs project;
      inherit rematerialize;
      inherit (project.iele-assemble.components.exes) iele-assemble;
    };

in default
