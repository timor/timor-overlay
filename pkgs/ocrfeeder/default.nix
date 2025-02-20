{stdenv, lib, fetchFromGitLab, python27, python27Packages, tesseract, ocrad, cuneiform, zbar
, gobject-introspection, wrapGAppsHook, unpaper, gtkspell3, autoreconfHook
, gnome-doc-utils, pkg-config, gnome3, intltool, automake, autoconf, sane-backends
, goocanvas2, makeWrapper, isocodes }:

let inherit (lib) makeBinPath;
python-sane = python27Packages.buildPythonPackage rec {
  pname = "python-sane";
  version = "2.8.2";

  src = python27Packages.fetchPypi {
    inherit pname version;
    sha256 = "0sri01h9sld6w7vgfhwp29n5w19g6idz01ba2giwnkd99k1y2iqg";
  };

  buildInputs = [ sane-backends ];

  propagatedBuildInputs = [ python27Packages.pillow ];
};

in
python27Packages.buildPythonApplication rec {
  name = "ocrfeeder-${version}";
  version = "0.8.1";

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    owner = "GNOME";
    repo = "ocrfeeder";
    rev = "release_${version}";
    sha256 = "0dv55p1l2qwf87ddvyg7yv3xc4ccw54giqag20y0rmfms4m2738h";
  };

  format = "other";

  nativeBuildInputs = [ wrapGAppsHook pkg-config gobject-introspection automake autoconf gnome3.gnome-common intltool gnome-doc-utils
    goocanvas2 makeWrapper];

  buildInputs = [ # tesseract ocrad gocr zbar
  gtkspell3 isocodes ];

  preConfigure = ''
    cp ${gnome-doc-utils}/share/gnome-doc-utils/gnome-doc-utils.make .
    substituteInPlace src/ocrfeeder/util/constants.py.in \
      --replace /usr/share/xml/iso-codes ${isocodes}/share/xml/iso-codes
    ./autogen.sh $configureFlags --prefix=$out
  '';

  postInstall = ''
    wrapProgram $out/bin/ocrfeeder \
      --prefix PATH : ${makeBinPath [ tesseract ocrad zbar cuneiform ]}
  '';


  pythonPath = with python27Packages; [ lxml pygtk pillow pygobject3 reportlab pyenchant odfpy python-sane ];
}
