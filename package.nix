{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  wrapGAppsHook3,
  gtk3,
  libepoxy,
  fontconfig,
  xclip,
  wl-clipboard,
  source,
}:

stdenv.mkDerivation {
  pname = "web-artisan-pro";
  inherit (source) version;

  src = fetchurl {
    inherit (source.${stdenv.hostPlatform.system}) url hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    libepoxy
    fontconfig
    stdenv.cc.cc.lib
  ];

  dontWrapGApps = true;

  # Flutter loads data/ and lib/ from the directory of its executable.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt/web-artisan-pro
    cp -r web-artisan-pro data lib $out/opt/web-artisan-pro/
    cp -r share $out/share
    runHook postInstall
  '';

  # Reading and writing the clipboard runs xclip on X11 and wl-copy/wl-paste
  # on Wayland.
  postFixup = ''
    makeWrapper $out/opt/web-artisan-pro/web-artisan-pro $out/bin/web-artisan-pro \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${
        lib.makeBinPath [
          xclip
          wl-clipboard
        ]
      }
  '';

  meta = {
    description = "Everyday developer utilities, composable into flows";
    homepage = "https://web-artisan.pro";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "web-artisan-pro";
  };
}
