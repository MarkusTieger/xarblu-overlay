# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	adler@1.0.2
	ansi_colours@1.2.2
	anstream@0.6.4
	anstyle-parse@0.2.2
	anstyle-query@1.0.0
	anstyle-wincon@3.0.1
	anstyle@1.0.4
	autocfg@1.1.0
	base64@0.21.5
	bit_field@0.10.2
	bitflags@1.3.2
	bitflags@2.4.1
	bytemuck@1.14.0
	byteorder@1.5.0
	cfg-if@1.0.0
	clap@4.4.8
	clap_builder@4.4.8
	clap_lex@0.6.0
	color_quant@1.1.0
	colorchoice@1.0.0
	console@0.15.7
	crc32fast@1.3.2
	crossbeam-deque@0.8.3
	crossbeam-epoch@0.9.15
	crossbeam-utils@0.8.16
	crossterm@0.27.0
	crossterm_winapi@0.9.1
	crunchy@0.2.2
	ctrlc@3.4.1
	either@1.9.0
	encode_unicode@0.3.6
	errno@0.3.7
	exr@1.71.0
	fastrand@2.0.1
	fdeflate@0.3.1
	flate2@1.0.28
	flume@0.11.0
	gif@0.12.0
	half@2.2.1
	image@0.24.7
	jpeg-decoder@0.3.0
	lazy_static@1.4.0
	lebe@0.5.2
	libc@0.2.150
	linux-raw-sys@0.4.11
	lock_api@0.4.11
	log@0.4.20
	make-cmd@0.1.0
	memoffset@0.9.0
	miniz_oxide@0.7.1
	mio@0.8.9
	nix@0.27.1
	num-integer@0.1.45
	num-rational@0.4.1
	num-traits@0.2.17
	parking_lot@0.12.1
	parking_lot_core@0.9.9
	png@0.17.10
	qoi@0.4.1
	rayon-core@1.12.0
	rayon@1.8.0
	redox_syscall@0.4.1
	rgb@0.8.37
	rustix@0.38.25
	scopeguard@1.2.0
	signal-hook-mio@0.2.3
	signal-hook-registry@1.4.1
	signal-hook@0.3.17
	simd-adler32@0.3.7
	sixel-rs@0.3.3
	sixel-sys@0.3.1
	smallvec@1.11.2
	spin@0.9.8
	strsim@0.10.0
	tempfile@3.8.1
	termcolor@1.4.0
	tiff@0.9.0
	utf8parse@0.2.1
	viuer@0.7.1
	wasi@0.11.0+wasi-snapshot-preview1
	weezl@0.1.7
	winapi-i686-pc-windows-gnu@0.4.0
	winapi-util@0.1.6
	winapi-x86_64-pc-windows-gnu@0.4.0
	winapi@0.3.9
	windows-sys@0.45.0
	windows-sys@0.48.0
	windows-targets@0.42.2
	windows-targets@0.48.5
	windows_aarch64_gnullvm@0.42.2
	windows_aarch64_gnullvm@0.48.5
	windows_aarch64_msvc@0.42.2
	windows_aarch64_msvc@0.48.5
	windows_i686_gnu@0.42.2
	windows_i686_gnu@0.48.5
	windows_i686_msvc@0.42.2
	windows_i686_msvc@0.48.5
	windows_x86_64_gnu@0.42.2
	windows_x86_64_gnu@0.48.5
	windows_x86_64_gnullvm@0.42.2
	windows_x86_64_gnullvm@0.48.5
	windows_x86_64_msvc@0.42.2
	windows_x86_64_msvc@0.48.5
	zune-inflate@0.2.54
"

inherit cargo

DESCRIPTION="Terminal image viewer with native support for iTerm and Kitty"
HOMEPAGE="https://github.com/atanunq/viu"
SRC_URI="
	https://github.com/atanunq/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

IUSE="sixel"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="sixel? ( media-libs/libsixel )"
RDEPEND="${DEPEND}"
BDEPEND="${DEPEND}"

# rust does not use *FLAGS from make.conf, silence portage warning
# update with proper path to binaries this crate installs, omit leading /
QA_FLAGS_IGNORED="usr/bin/${PN}"

src_configure() {
	local myfeatures=(
		$(usev sixel)
	)
	cargo_src_configure
}
