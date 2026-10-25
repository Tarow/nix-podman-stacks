{pkgs}:
pkgs.writeShellApplication {
  name = "nps-inspect";
  runtimeInputs = [pkgs.nix];
  text = ''
    usage() {
      cat >&2 <<'USAGE'
    Usage: nps-inspect <home-configuration-installable> [--stack NAME] [--format summary|json|dot]

    Examples:
      nps-inspect .#homeConfigurations.myhost
      nps-inspect .#homeConfigurations.myhost --stack paperless
      nps-inspect .#homeConfigurations.myhost --format dot
    USAGE
    }

    if [[ $# -eq 1 && ( $1 == -h || $1 == --help ) ]]; then
      usage
      exit 0
    fi

    if [[ $# -lt 1 ]]; then
      usage
      exit 2
    fi

    target=$1
    shift
    format=summary
    stack=

    while [[ $# -gt 0 ]]; do
      case $1 in
        --stack)
          if [[ $# -lt 2 || -z $2 ]]; then
            echo "nps-inspect: --stack requires a name" >&2
            exit 2
          fi
          stack=$2
          shift 2
          ;;
        --format)
          if [[ $# -lt 2 ]]; then
            echo "nps-inspect: --format requires summary, json, or dot" >&2
            exit 2
          fi
          format=$2
          shift 2
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        *)
          echo "nps-inspect: unknown argument: $1" >&2
          usage
          exit 2
          ;;
      esac
    done

    case $format in
      summary|json|dot) ;;
      *)
        echo "nps-inspect: unsupported format '$format' (choose summary, json, or dot)" >&2
        exit 2
        ;;
    esac

    attribute=render
    if [[ -n $stack ]]; then
      if [[ ! $stack =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "nps-inspect: invalid stack name '$stack'" >&2
        exit 2
      fi
      attribute+=".stacks.$stack"
    fi
    attribute+=".$format"

    exec nix eval --raw "''${target}.config.nps.inspection.''${attribute}"
  '';
}
