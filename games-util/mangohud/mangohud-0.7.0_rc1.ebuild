# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..11} )

inherit python-r1 meson-multilib

DESCRIPTION="Vulkan and OpenGL overlay for monitoring FPS, sensors, system load and more"
HOMEPAGE="https://github.com/flightlessmango/MangoHud"

MY_PV=$(ver_cut 1-3)
[[ -n "$(ver_cut 4-)" ]] && MY_PV_REV="-$(ver_cut 4-)"

# required subprojects
# spdlog only required until
# dev-libs/spdlog support multilib builds
declare -A subprojectv=(
	[vkheaders]="1.2.158"
	[vkheaders_meson]="1.2.158-2"
	[imgui]="1.81"
	[imgui_meson]="1.81-1"
	[spdlog]="1.8.5"
	[spdlog_meson]="1.8.5-1"
)

SRC_URI="
	https://github.com/flightlessmango/MangoHud/archive/v${MY_PV}${MY_PV_REV}.tar.gz -> ${P}.tar.gz
	https://github.com/KhronosGroup/Vulkan-Headers/archive/v${subprojectv[vkheaders]}.tar.gz -> vulkan-headers-${subprojectv[vkheaders]}.tar.gz
	https://wrapdb.mesonbuild.com/v2/vulkan-headers_${subprojectv[vkheaders_meson]}/get_patch#/vulkan-headers-${subprojectv[vkheaders_meson]}-wrap.zip -> vulkan-headers-${subprojectv[vkheaders_meson]}-wrap.zip
	https://github.com/ocornut/imgui/archive/v${subprojectv[imgui]}.tar.gz -> imgui-${subprojectv[imgui]}.tar.gz
	https://wrapdb.mesonbuild.com/v2/imgui_${subprojectv[imgui_meson]}/get_patch#/imgui-${subprojectv[imgui_meson]}-wrap.zip -> imgui-${subprojectv[imgui_meson]}-wrap.zip
	!system-spdlog? (
		https://github.com/gabime/spdlog/archive/v${subprojectv[spdlog]}.tar.gz -> spdlog-${subprojectv[spdlog]}.tar.gz
		https://wrapdb.mesonbuild.com/v2/spdlog_${subprojectv[spdlog_meson]}/get_patch#spdlog-${subprojectv[spdlog_meson]}-wrap.zip -> spdlog-${subprojectv[spdlog_meson]}-wrap.zip
	)
"

KEYWORDS="~amd64"
LICENSE="MIT"
SLOT="0"
IUSE="+dbus debug doc mangoapp mangohudctl mangoplot +system-spdlog test wayland video_cards_nvidia +X xnvctrl"

# HACK: system-spdlog only works with native abi
# since native ABI is always selected selecting 'exactly one of all ABIs'
# implicitly means 'only select native'
MULTILIB_ALL="${MULTILIB_USEDEP//'(-)?,'/ }"
MULTILIB_ALL="${MULTILIB_ALL//'(-)?'/}"
REQUIRED_USE="
	|| ( X wayland )
	xnvctrl? ( video_cards_nvidia )
	system-spdlog? ( ^^ ( ${MULTILIB_ALL} ) )
	${PYTHON_REQUIRED_USE}
"

RESTRICT="!test? ( test )"

BDEPEND="
	app-arch/unzip
	test? ( dev-util/cmocka[${MULTILIB_USEDEP}] )
	$(python_gen_any_dep 'dev-python/mako[${PYTHON_USEDEP}]')
"

DEPEND="
	dev-cpp/nlohmann_json
	dev-util/glslang[${MULTILIB_USEDEP}]
	media-libs/vulkan-loader[${MULTILIB_USEDEP}]
	media-libs/libglvnd[${MULTILIB_USEDEP}]
	x11-libs/libdrm[${MULTILIB_USEDEP}]
	dbus? ( sys-apps/dbus[${MULTILIB_USEDEP}] )
	mangoapp? (
		media-libs/glew[${MULTILIB_USEDEP}]
		media-libs/glfw[-wayland-only,${MULTILIB_USEDEP}]
	)
	mangoplot? (
		$(python_gen_cond_dep '
			dev-python/numpy[${PYTHON_USEDEP}]
			dev-python/matplotlib[${PYTHON_USEDEP}]
		')
	)
	system-spdlog? ( dev-libs/spdlog )
	video_cards_nvidia? (
		x11-drivers/nvidia-drivers[${MULTILIB_USEDEP}]
		xnvctrl? ( x11-drivers/nvidia-drivers[static-libs] )
	)
	wayland? ( dev-libs/wayland[${MULTILIB_USEDEP}] )
	X? ( x11-libs/libX11[${MULTILIB_USEDEP}] )
	${PYTHON_DEPS}
"

RDEPEND="${DEPEND}"

python_check_deps() {
	python_has_version "dev-python/mako[${PYTHON_USEDEP}]"
}

S="${WORKDIR}/MangoHud-${PV}"

src_unpack() {
	default
	[[ -n "${MY_PV_REV}" ]] && ( mv "${WORKDIR}/MangoHud-${MY_PV}${MY_PV_REV}" "${WORKDIR}/MangoHud-${PV}" || die )

	# symlink subprojects
	local projects=( Vulkan-Headers-${subprojectv[vkheaders]}
					 imgui-${subprojectv[imgui]}
					 $(usex system-spdlog '' spdlog-${subprojectv[spdlog]})
					)

	for subproject in "${projects[@]}"; do
		einfo "Symlinking subproject ${subproject}"
		ln -sfv "${WORKDIR}/${subproject}" "${S}/subprojects/" || die "Couldn't symlink ${subproject}"
	done
}

multilib_src_configure() {
	local emesonargs=(
		-Dappend_libdir_mangohud=false
		$(meson_feature system-spdlog use_system_spdlog)
		$(meson_use doc include_doc)
		$(meson_feature video_cards_nvidia with_nvml)
		$(meson_feature xnvctrl with_xnvctrl)
		$(meson_feature X with_x11)
		$(meson_feature wayland with_wayland)
		$(meson_feature dbus with_dbus)
		$(meson_use mangoapp mangoapp)
		$(meson_use mangoapp mangoapp_layer)
		$(meson_use mangohudctl mangohudctl)
		$(meson_feature test tests)
	)
	meson_src_configure
}

multilib_src_install_all() {
	# make mangoplot optional
	# to avoid hard numpy & matplot deps
	# (mostly for benchmarking)
	if ! use mangoplot; then
		rm "${ED}/usr/bin/mangoplot"
	fi

	einstalldocs
}

pkg_postinst() {
	if ! use xnvctrl; then
		elog ""
		elog "If mangohud can't get GPU load, or other GPU information,"
		elog "and you may have an older Nvidia device."
		elog ""
		elog "Try enabling the 'xnvctrl' useflag."
		elog ""
	fi
}
