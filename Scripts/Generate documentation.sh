set -eu
here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$here/../"

jazzy -g https://github.com/Dev1an/Swift-Atem --github-file-prefix https://github.com/Dev1an/Swift-Atem/tree/`git rev-parse HEAD` -m Atem
