{
  buildIdrisPackage,
  fetchFromGitHub,
}:
buildIdrisPackage {
  pname = "toml-idr";
  version = "0-2022-05-05";

  src = fetchFromGitHub {
    owner = "cuddlefishie";
    repo = "toml-idr";
    rev = "b4f5a4bd874fa32f20d02311a62a1910dc48123f";
    hash = "sha256-+bqfCE6m0aJ+S65urT+zQLuZUtUkC1qcuSsefML/fAE=";
  };

  buildTarget = "toml";
}
