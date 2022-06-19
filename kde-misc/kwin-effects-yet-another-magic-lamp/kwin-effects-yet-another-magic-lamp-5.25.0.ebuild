# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake

DESCRIPTION="Just Yet Another Magic Lamp effect for KWin"
HOMEPAGE="https://github.com/zzag/kwin-effects-yet-another-magic-lamp"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/zzag/kwin-effects-yet-another-magic-lamp.git"
	KEYWORDS=""
else
	SRC_URI="https://github.com/zzag/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
fi

LICENSE="GPL-2"
SLOT="0"

DEPEND="dev-qt/qtcore:5=
	kde-plasma/kwin:5=
	kde-frameworks/kconfig:5=
	kde-frameworks/kcoreaddons:5=
	kde-frameworks/kwindowsystem:5="
RDEPEND="${DEPEND}"
BDEPEND="dev-util/cmake
	kde-frameworks/extra-cmake-modules:5="

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_INSTALL_PREFIX=/usr
	)
	cmake_src_configure
}
