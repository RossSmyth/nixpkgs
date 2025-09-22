{
  fetchFromGitHub,
  buildIdrisPackage,
}:
buildIdrisPackage {
  pname = "lsp-lib";
  version = "0-2024-01-21";

  src = fetchFromGitHub {
    owner = "idris-community";
    repo = "LSP-lib";
    rev = "03851daae0c0274a02d94663d8f53143a94640da";
    hash = "sha256-ICW9oOOP70hXneJFYInuPY68SZTDw10dSxSPTW4WwWM=";
  };
}
