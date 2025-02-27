{ src
, domain
, gnupg
, stdenv
}:

stdenv.mkDerivation {
  name = "wkd-${domain}";

  nativeBuildInputs = [ gnupg ];

  inherit src;

  buildPhase = ''
    export GNUPGHOME=''${PWD}/.gnupg
    mkdir -m 700 -p $GNUPGHOME
    gpg --import *

    mkdir -p .well-known/openpgpkey
    touch .well-known/openpgpkey/policy
    pushd .well-known
    gpg --list-options show-only-fpr-mbox -k "@${domain}" | \
      gpg-wks-client --install-key
    popd
  '';

  installPhase = ''
    mkdir $out
    cp -a .well-known $out
  '';
}