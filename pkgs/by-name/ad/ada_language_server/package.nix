{ gmp, autoPatchelfHook, stdenvNoCC, fetchzip}:
let
inherit (stdenvNoCC.hostPlatform) system;
  throwSystem = throw "Unsupported system: ${system}";

  plat = {
    x86_64-linux = "amd64";
    aarch64-linux = "aarch64";
  }.${system} or throwSystem;
  sha256 = {
    x86_64-linux = "sha256-MtdtTTwKkU8HdWOldwRUykMsrtb7gksmleaPlaPuE2c=";
    aarch64-linux = "";
  }.${system} or throwSystem;

in
stdenvNoCC.mkDerivation rec {
    pname = "ada_language_server";
    version = "24.0.4";
    src = fetchzip {
        url = "https://github.com/AdaCore/ada_language_server/releases/download/24.0.5/als-24.0.5-Linux_${plat}.zip";
        hash = sha256;
  };
    nativeBuildInputs = [ gmp autoPatchelfHook ];
    installPhase = ''
    outdir="$out/share/$pname"
    mkdir -p "$out/bin"
    cp "$src/linux/ada_language_server" "$out/bin"
    '';

}
