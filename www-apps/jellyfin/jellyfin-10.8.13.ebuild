# Copyright 2022-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit pax-utils systemd tmpfiles

DESCRIPTION="Jellyfin puts you in control of managing and streaming your media"
HOMEPAGE="https://jellyfin.org/"

IUSE="intro-skipper jellyscrub"

SRC_URI="
	arm64? (
		https://repo.jellyfin.org/releases/server/linux/versions/stable/combined/${PV}/${PN}_${PV}_arm64.tar.gz
	)
	amd64? (
		https://repo.jellyfin.org/releases/server/linux/versions/stable/combined/${PV}/${PN}_${PV}_amd64.tar.gz
	)
	intro-skipper? (
		https://github.com/jellyfin/jellyfin-web/archive/v${PV}.tar.gz -> jellyfin-web-${PV}.tar.gz
	)
"

# npm needs net access
RESTRICT="mirror network-sandbox test"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
DEPEND="
	acct-user/jellyfin
	media-libs/fontconfig
	sys-libs/zlib
"
RDEPEND="${DEPEND}
	dev-libs/icu
	media-video/ffmpeg[vpx,x264]
	sys-libs/glibc
	intro-skipper? ( media-video/ffmpeg[chromaprint] )
"
BDEPEND="
	acct-user/jellyfin
	intro-skipper? ( net-libs/nodejs[npm] )
"

INST_DIR="/opt/${PN}"
QA_PREBUILT="${INST_DIR#/}/*.so ${INST_DIR#/}/jellyfin ${INST_DIR#/}/createdump"

pkg_pretend() {
	if use jellyscrub; then
		ewarn "If your Jellyfin server uses a baseurl you need to set JF_BASEURL=<baseurl>."
		ewarn "Otherwise the Jellyscrub plugin won't work."
	fi
}

src_unpack() {
	unpack ${A}
	mv "${PN}_${PV}" "${P}" || die
}

src_prepare() {
	default

	# https://github.com/jellyfin/jellyfin/issues/7471
	# https://github.com/dotnet/runtime/issues/57784
	rm libcoreclrtraceptprovider.so || die

	#Patch jellyfin-web for intro-skipper
	if use intro-skipper; then
		pushd "${WORKDIR}/jellyfin-web-${PV}"
		eapply "${FILESDIR}/10.8.9-intro-skipper-web.patch"
		popd
	fi
}

src_compile() {
	default

	#Build custom jellyfin-web for intro-skipper
	if use intro-skipper; then
		pushd "${WORKDIR}/jellyfin-web-${PV}"
		npm install || die "npm failed"
		popd
	fi
}

src_install() {
	#Install custom jellyfin-web for intro-skipper
	if use intro-skipper; then
		rm -r "${S}/jellyfin-web"/* || die "switching to modded jellyfin-web failed"
		mv "${WORKDIR}/jellyfin-web-${PV}/dist"/* "${S}/jellyfin-web/" || die "switching to modded jellyfin-web failed"
	fi

	#Add jellyscrub plugin to index.html
	if use jellyscrub; then
		sed -i -e "s|</body>|<script plugin=\"Jellyscrub\" version=\"1.0.0.0\" src=\"${JF_BASEURL#/}/Trickplay/ClientScript\"></script>&|" "${S}/jellyfin-web/index.html" || die "Failed modifying index.html"
	fi

	keepdir /var/log/jellyfin
	fowners jellyfin:jellyfin /var/log/jellyfin
	keepdir /etc/jellyfin
	fowners jellyfin:jellyfin /etc/jellyfin
	insinto "${INST_DIR}"
	dodir "${INST_DIR}"
	doins -r "${S}"/*
	newtmpfiles - jellyfin.conf <<<"d /var/cache/jellyfin 0775 jellyfin jellyfin -"
	chmod 755 "${D}${INST_DIR}/jellyfin"
	newinitd "${FILESDIR}/${PN}.init-r1" "${PN}"
	newconfd "${FILESDIR}"/${PN}.confd "${PN}"
	systemd_dounit "${FILESDIR}/${PN}.service"
	pax-mark -m "${ED}${INST_DIR}/jellyfin"
}

pkg_postinst() {
	tmpfiles_process jellyfin.conf
}
