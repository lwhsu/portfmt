#!/bin/sh
set -eu
: "${BASEDIR:=/usr/src}"
: "${PORTSDIR:=${HOME}/ports/head}"
TARGET="generated_rules.c"
TMP="generated_rules.tmp"
OSRELS="11 12 13"

export LC_ALL=C

_make() {
	if [ "$1" = "Mk" ]; then
		flags="-f bsd.port.mk"
	else
		flags=""
	fi
	make -C "${PORTSDIR}/$1" ${flags} PORTSDIR="${PORTSDIR}" "$@" | tr ' ' '\n' | awk 'NF' | sort -u
}

exec 1>"${TARGET}"
echo "/* Generated by generate_rules.sh; do not edit */"

printf '#define VAR_FOR_EACH_ARCH(block, var, flags) \\\n'
(
	make -C "${BASEDIR}" targets
	# Some arches are retired in FreeBSD 13 but still valid in other releases
	echo "/arm"
	echo "/sparc64"
	echo "/powerpcspe"
) | awk -F/ 'NR > 1 { lines[NR] = $2 }
END {
	for (i in lines) {
		printf "%s\t{ block, var \"%s\", flags }", start, lines[i]
		start = ", \\\n";
	}
	print ""
}' | sort -u

printf '#define VAR_FOR_EACH_FREEBSD_VERSION_AND_ARCH(block, var, flags) \\\n'
printf '	{ block, var "FreeBSD", flags }, \\\n'
for ver in ${OSRELS}; do
	printf '	{ block, var "FreeBSD_%s", flags }, \\\n' "${ver}"
	printf '	VAR_FOR_EACH_ARCH(block, var "FreeBSD_%s_", flags), \\\n' "${ver}"
done
printf '	VAR_FOR_EACH_ARCH(block, var "FreeBSD_", flags)\n'
printf '#define VAR_FOR_EACH_FREEBSD_VERSION(block, var, flags) \\\n'
printf '	{ block, var "FreeBSD", flags }'
for ver in ${OSRELS}; do
	printf ', \\\n	{ block, var "FreeBSD_%s", flags }' "${ver}"
done
echo

echo 'static const char *use_gnome_rel[] = {'
_make "Mk" USES=gnome -V _USE_GNOME_ALL >"${TMP}"
sed -e 's/^/	"/' -e 's/$/",/' "${TMP}"
# USES=gnome silently allows for bogus component:build args etc,
# but we do not.
while read -r comp; do
	build=$(_make "Mk" USES=gnome -V "${comp}_BUILD_DEPENDS")
	if [ -n "${build}" ]; then
		echo "${comp}" | sed -e 's/^/	"/' -e 's/$/:build",/'
	fi
done <"${TMP}"
while read -r comp; do
	build=$(_make "Mk" USES=gnome -V "${comp}_RUN_DEPENDS")
	if [ -n "${build}" ]; then
		echo "${comp}" | sed -e 's/^/	"/' -e 's/$/:run",/'
	fi
done <"${TMP}"
echo '};'

echo 'static const char *use_kde_rel[] = {'
_make "Mk" CATEGORIES=devel USES=kde:5 -V _USE_KDE5_ALL >"${TMP}"
sed -e 's/^/	"/' -e 's/$/",/' "${TMP}"
sed -e 's/^/	"/' -e 's/$/_build",/' "${TMP}"
sed -e 's/^/	"/' -e 's/$/_run",/' "${TMP}"
echo '};'

echo 'static const char *use_qt_rel[] = {'
_make "Mk" USES=qt:5 -V _USE_QT_ALL >"${TMP}"
sed -e 's/^/	"/' -e 's/$/",/' "${TMP}"
sed -e 's/^/	"/' -e 's/$/_build",/' "${TMP}"
sed -e 's/^/	"/' -e 's/$/_run",/' "${TMP}"
echo '};'

echo 'static const char *use_pyqt_rel[] = {'
_make "Mk" USES=pyqt:5 -V _USE_PYQT_ALL >"${TMP}"
sed -e 's/^/	"/' -e 's/$/",/' "${TMP}"
sed -e 's/^/	"/' -e 's/$/_build",/' "${TMP}"
sed -e 's/^/	"/' -e 's/$/_run",/' "${TMP}"
sed -e 's/^/	"/' -e 's/$/_test",/' "${TMP}"
echo '};'

printf '#define VAR_FOR_EACH_SSL(block, var, flags) \\\n'
valid_ssl=$(awk '/^# Possible values: / { values = $0; gsub(/(^# Possible values: |,)/, "", values); }
/SSL_DEFAULT/ { print values; exit }' "${PORTSDIR}/Mk/bsd.default-versions.mk")
start=""
for ssl in ${valid_ssl}; do
	[ -n "${start}" ] && echo "${start}"
	printf '	{ block, var "%s", flags }' "${ssl}"
	start=", \\"
done
echo

echo "static const char *static_flavors_[] = {"
(
	_make "Mk" USES=lazarus:flavors -V FLAVORS
	_make "Mk" USES=php:flavors -V FLAVORS
	_make "devel/py-setuptools" BUILD_ALL_PYTHON_FLAVORS=yes -V FLAVORS
) | sed -e 's/^/	"/' -e 's/$/",/'
echo "};"

rm -f "${TMP}"
