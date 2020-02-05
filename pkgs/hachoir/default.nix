{stdenv, lib, fetchFromGitHub, python3Packages }:

let version = "3.1.1";

in

python3Packages.buildPythonApplication {
  pname = "hachoir";
  inherit version;

  src = fetchFromGitHub {
    owner = "vstinner";
    repo = "hachoir";
    rev = version;
    sha256 = "1qx6n20j93c692pykqdajl7bc7q7pdc65hv58r9nkzfvji32ky49";
  };

  pythonPath = with python3Packages; [ six wxPython_4_0 ];

  doCheck = false;

}
