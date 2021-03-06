#!/bin/bash
set -e

. ./scripts/env.sh
. ./build/tfs/common/common.sh

export ARCH="$1"
export VSCODE_MIXIN_PASSWORD="$2"
VSO_PAT="$3"

echo "machine monacotools.visualstudio.com password $VSO_PAT" > ~/.netrc

step "Install dependencies" \
	npm install --arch=$ARCH --unsafe-perm

step "Mix in repository from vscode-distro" \
	npm run gulp -- mixin

step "Get Electron" \
	npm run gulp -- "electron-$ARCH"

step "Install distro dependencies" \
	node build/tfs/common/installDistro.js --arch=$ARCH

step "Build minified" \
	npm run gulp -- --max_old_space_size=4096 "vscode-linux-$ARCH-min"

step "Configure environment" \
	id -u testuser || (useradd -m testuser; echo -e "testpassword\ntestpassword" | passwd testuser)
	su testuser
	cd $BUILD_REPOSITORY_LOCALPATH
	git config --global user.name "Michel Kaporin"
	git config --global user.email "monacotools@microsoft.com"

step "Run smoke test" \
	pushd test/smoke
	npm install
	npm run compile
	xvfb-run -a -s "-screen 0 1024x768x8" node src/main.js --latest "$AGENT_BUILDDIRECTORY/VSCode-linux-ia32/code-insiders"
	popd
