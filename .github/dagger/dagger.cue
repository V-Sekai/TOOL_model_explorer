// MIT License

// Copyright (c) 2022 K. S. Ernest (iFire) Lee

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// # How to use?
// scoop install rancher-desktop
// Enable moby mode
// scoop install dagger
// dagger do build

package main

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

godot: {
	core.#GitPull & {
		keepGitDir: true
		remote: "https://github.com/V-Sekai/godot.git"
		ref:    "9d2f4ad098fa1ad1f8022f4f652cb3ef02a6472b"
	}
}
godot_groups_modules: {
	core.#GitPull & {
		keepGitDir: true
		remote: "https://github.com/V-Sekai/godot-modules-groups"
		ref:    "a8e3a7888b9e00f38dab8829e325b4a562a64f0e"
	}
}

fetch_godot: {
	docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "rockylinux:8"
			},
			docker.#Set & {
				config: {
					user:    "root"
					workdir: "/"
					entrypoint: ["sh"]
				}
			},
			bash.#Run & {
				script: contents: #"""
					dnf install -y epel-release
					dnf config-manager --set-enabled powertools
					yum install unzip mingw32-binutils gcc-toolset-9 gcc-toolset-9-libatomic-devel git-lfs automake autoconf libtool clang glibc-devel.i686 libgcc.i686 libstdc++.i686 python3-pip bash libX11-devel libXcursor-devel libXrandr-devel libXinerama-devel libXi-devel mesa-libGL-devel alsa-lib-devel pulseaudio-libs-devel freetype-devel openssl-devel libudev-devel mesa-libGLU-devel libpng-devel llvm-devel clang llvm-devel libxml2-devel libuuid-devel openssl-devel bash patch make git bzip2 xz xorg-x11-server-Xvfb pkgconfig mesa-dri-drivers ncurses-compat-libs unzip which gcc gcc-c++ libatomic -y
					"""#
			},
			bash.#Run & {
				script: contents: #"""
					yum group install -y "Development Tools"
					"""#
			},
			bash.#Run & {
				workdir: "/usr/local/bin"
				script: contents: #"""
					curl -L -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default && unzip butler.zip && rm butler.zip && butler -V && butler -V && cd && butler -V
					"""#
			},
			bash.#Run & {
				workdir: "/godot_game/godot"
				script: contents: #"""
					alternatives --set ld /usr/bin/ld.gold && git lfs install && pip3 install scons
					"""#
			},
			bash.#Run & {
				workdir: "/godot_game/godot"
				script: contents: #"""
					mkdir /opt/llvm-mingw && curl -L https://github.com/mstorsjo/llvm-mingw/releases/download/20220323/llvm-mingw-20220323-ucrt-ubuntu-18.04-x86_64.tar.xz | tar -Jxf - --strip 1 -C /opt/llvm-mingw
					"""#
			},
			bash.#Run & {
				workdir: "/"
				script: contents: #"""
					adduser v-sekai-game
					"""#
			},
			docker.#Copy & {
				contents: godot_groups_modules.output
				dest:     "/godot_game/godot_groups_modules"
			},
			docker.#Copy & {
				contents: godot.output
				dest:     "/godot_game/godot"
			},
			bash.#Run & {
				workdir: "/"
				script: contents: #"""
					chown -R v-sekai-game /godot_game
					"""#
			},
			bash.#Run & {
				workdir: "/godot_game/godot"
				script: contents: #"""
					git submodule update --recursive --init
					"""#
			},
			bash.#Run & {
				workdir: "/godot_game/godot_groups_modules"
				script: contents: #"""
					git submodule update --recursive --init
					"""#
			},
			docker.#Set & {
				config: {
					user:    "v-sekai-game"
					workdir: "/godot_game"
					entrypoint: ["sh"]
				}
			},
		]
	}
}

build_godot_windows:
	bash.#Run & {
		input:   fetch_godot.output
		workdir: "/godot_game/godot"
		script: contents: #"""
			mkdir -p /godot_game/build/.scons_cache
			SCONS_CACHE=/godot_game/build/.scons_cache PATH=/opt/llvm-mingw/bin:$PATH scons optimize=size werror=no platform=windows target=template_release use_fastlto=no deprecated=no use_mingw=yes use_llvm=yes LINKFLAGS=-Wl,-pdb= CCFLAGS='-Wall -Wno-tautological-compare -g -gcodeview' debug_symbols=no custom_modules=../godot_groups_modules
			"""#
		export:
			files:
				"/godot_game/build": dagger.#FS
		export:
			directories:
				"/godot_game/godot/bin": dagger.#FS
	}
build_godot_linux_cicd:
	bash.#Run & {
		input:   build_godot_windows.output
		workdir: "/godot_game/godot"
		script: contents: #"""
			mkdir -p /godot_game/build/.scons_cache			
			SCONS_CACHE=/godot_game/build/.scons_cache PATH=/opt/llvm-mingw/bin:$PATH scons optimize=speed LINKFLAGS=-L/opt/rh/gcc-toolset-9/root/usr/lib/gcc/x86_64-redhat-linux/9/ werror=no platform=linuxbsd target=editor use_fastlto=no deprecated=no use_static_cpp=yes use_llvm=yes builtin_freetype=yes custom_modules=../godot_groups_modules
			"""#
		export:
			files:
				"/godot_game/build": dagger.#FS
		export:
			directories:
				"/godot_game/godot/bin": dagger.#FS
	}
build_godot:
	bash.#Run & {
		input:   build_godot_linux_cicd.output
		workdir: "/godot_game/godot"
		script: contents: #"""
			ls /godot_game/godot/bin
			"""#
		export:
			directories:
				"/godot_game/godot/bin": dagger.#FS
	}

dagger.#Plan & {
	client: {
		filesystem: "../../": 
			read: {
				contents: dagger.#FS,
        		exclude: [".github/", ".godot/"]
			}
		filesystem: {
			"../../build": write: contents: actions.build.export.directories."/godot_game/build"
		}
	}

	actions: {
		build:
			bash.#Run & {
				user: "root"
				mounts:
					"Local FS": {
						contents: client.filesystem."../../".read.contents
						dest:     "/godot_game/project"
					}
				input:
					build_godot.output
				script: contents: #"""
					mkdir -p /godot_game/build/.scons_cache /godot_game/project/build/.scons_cache
					cd /godot_game/godot
					ls bin
					cp bin/godot.windows.template_release.x86_64.llvm.exe bin/windows_release_x86_64.exe 
					mingw-strip --strip-debug bin/windows_release_x86_64.exe
					cp bin/godot.windows.template_release.x86_64.llvm.pdb bin/windows_release_x86_64.pdb 
					cp bin/godot.linuxbsd.editor.x86_64.llvm bin/linux_editor.x86_64
					mkdir -p /godot_game/build/
					rm -rf /godot_game/.local/share/godot/export_templates/
					mkdir -p /godot_game/.local/share/godot/export_templates/
					cd /godot_game/.local/share/godot/export_templates/
					eval `sed -e "s/ = /=/" /godot_game/godot/version.py` && echo $major.$minor.$status > /godot_game/build/version.txt
					export VERSION=`cat /godot_game/build/version.txt`
					export BASE_DIR=/godot_game/.local/share/godot/export_templates/ 
					export TEMPLATEDIR=$BASE_DIR/$VERSION/
					mkdir -p $TEMPLATEDIR
					cp /godot_game/godot/bin/windows_release_x86_64.exe $TEMPLATEDIR/windows_release_x86_64.exe
					cp /godot_game/godot/bin/windows_release_x86_64.exe $TEMPLATEDIR/windows_debug_x86_64.exe
					cp /godot_game/build/version.txt $TEMPLATEDIR/version.txt
					if [[ -z "${REPO_NAME}" ]]; then
						export GODOT_ENGINE_GAME_NAME="VSK_model_explorer_"
					fi
					rm -rf /godot_game/.godot
					cp /godot_game/godot/bin/windows_release_x86_64.exe /godot_game/build/windows_release_x86_64.exe
					mkdir -p /godot_game/build/windows_release_x86_64/ && mkdir -p /godot_game/project/.godot/editor && mkdir -p /godot_game/project/.godot/imported && chmod +x /godot_game/godot/bin/linux_editor.x86_64 && XDG_DATA_HOME=/godot_game/.local/share/ /godot_game/godot/bin/linux_editor.x86_64 --headless --export-release "Windows Desktop" /godot_game/build/windows_release_x86_64/${GODOT_ENGINE_GAME_NAME}windows.exe --path /godot_game/project && [ -f /godot_game/build/windows_release_x86_64/${GODOT_ENGINE_GAME_NAME}windows.exe ]
					cp /godot_game/godot/bin/windows_release_x86_64.pdb /godot_game/build/windows_release_x86_64/${GODOT_ENGINE_GAME_NAME}windows.pdb					
					"""#
				export:
					directories:
						"/godot_game/build": dagger.#FS
			}
	}
}
