#!/bin/bash

# Check if a path argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <kubernetes_app_name>"
  exit 1
fi

target_path="$1"
mkdir -p "$target_path"

pushd $target_path
cat > "jsonnetfile.json" <<EOF
{
  "version": 1,
  "dependencies": [
    {
      "source": {
        "local": {
          "directory": "../utils"
        }
      }
    }
  ],
  "legacyImports": true
}
EOF

mkdir -p "env"

/usr/local/bin/jb install

popd

echo "Successfully created kubernetes app at $target_path"
