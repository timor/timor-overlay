{stdenv, lib, pkgconfig, gdk_pixbuf, gtk2, fetchFromGitHub }:

let version = "3.3"; in

stdenv.mkDerivation {
  pname = "gatotray";
  inherit version ;

  src = fetchFromGitHub {
    owner = "gatopeich";
    repo = "gatotray";
    rev = "v${version}";
    sha256 = "08hy1zyq0nkrhmp599x6k0sn93a4484yi2lfgl0xf25lwdsrsyr5";
  };

  postPatch = ''
    # Substitute hard-coded install destinations
    substituteInPlace Makefile --replace /usr/local/bin $out/bin --replace /usr/share/ $out/share/

    # Leave stripping to fixup phase
    sed -i "/strip/d" Makefile

    # fix #4 for latest stable version
    patch -p1 <<EOF
--- a/settings.c
+++ b/settings.c
@@ -144,9 +144,9 @@
     for(PrefString* s=pref_strings; s < pref_strings+G_N_ELEMENTS(pref_strings); s++)
     {
         GError* gerror = NULL;
-        *s->value = s->default_value;
         gchar* value = g_key_file_get_string(pref_file, "Options", s->description, &gerror);
-        if(!gerror) *s->value = value;
+        if (!gerror) *s->value = value;
+        else *s->value = g_strdup(s->default_value);
     }
     preferences_changed();
 }
EOF
  '';

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ gdk_pixbuf gtk2 ];

  dontConfigure = true;

  preInstall = ''
    mkdir -p $out/bin
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons
  '';

  meta = {
    description = "A minimalistic graphical system tray CPU monitor";
    homepage = "https://github.com/gatopeich/gatotray";
    license = lib.licenses.cc-by-30;
    maintainers = [ lib.maintainers.timor ];
    platforms = lib.platforms.linux;
  };
}
