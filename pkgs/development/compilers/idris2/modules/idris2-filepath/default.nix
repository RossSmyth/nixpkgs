{
  buildIdrisPackage,
  fetchFromGitHub,
}:
buildIdrisPackage {
  pname = "idris-filepath";
  version = "0-2023-12-04";

  src = fetchFromGitHub {
    owner = "stefan-hoeck";
    repo = "idris2-filepath";
    rev = "eac02d51b631633f32330c788bcebeb24221fa09";
    hash = "sha256-noylxQvT2h50H0xmAiwe/cI6vz5gkbOhSD7mXuhJGfU=";
  };

  buildTarget = "filepath";
}
