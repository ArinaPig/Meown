%define __requires_exclude ^libfreetype\\.so.*|.*libxkbcommon\\.so.*$
%define __provides_exclude_from ^%{_datadir}/%{name}/lib/.*\\.so.*$
Name: ru.arinapig.meown
Summary: Meown - pixel-art cat adventure
Version: 0.1.0
Release: 1
License: Proprietary
%global debug_package %{nil}
%define __os_install_post %{nil}
%description
Meown - пиксельное приключение о котёнке.
%prep
%build
%install
PROJECT_DIR="$(pwd)"
if [ ! -d "${PROJECT_DIR}/icons" ]; then PROJECT_DIR="$(cd ../.. && pwd)"; fi
for size in 86 108 128 172; do
    install -m 0644 -D "${PROJECT_DIR}/icons/${size}.png" "%{buildroot}%{_datadir}/icons/hicolor/${size}x${size}/apps/%{name}.png"
done
install -m 0644 -D "${PROJECT_DIR}/build/game.pck" "%{buildroot}%{_datadir}/%{name}/resources.pck"
install -m 0644 -D "${PROJECT_DIR}/rpm/%{name}.desktop" "%{buildroot}%{_datadir}/applications/%{name}.desktop"
install -m 0755 -D "${PROJECT_DIR}/build/godot-template" "%{buildroot}%{_bindir}/%{name}"
"${PROJECT_DIR}/build/patchelf" --force-rpath --set-rpath "%{_datadir}/%{name}/lib" "%{buildroot}%{_bindir}/%{name}"
SYSROOT=""
for candidate in /opt/cross/%{_target_platform}/sys-root /opt/cross/%{_target_cpu}-*/sys-root; do
    if [ -d "${candidate}" ]; then SYSROOT="${candidate}"; break; fi
done
mkdir -p "%{buildroot}%{_datadir}/%{name}/lib"
for library in libfreetype libxkbcommon; do
    if [ -n "${SYSROOT}" ]; then
        for library_file in "${SYSROOT}"/usr/lib64/${library}.so.* "${SYSROOT}"/usr/lib/${library}.so.*; do
            if [ -f "${library_file}" ]; then install -m 0755 -D "${library_file}" -t "%{buildroot}%{_datadir}/%{name}/lib/"; fi
        done
    fi
done
%files
%{_datadir}/icons/hicolor/86x86/apps/%{name}.png
%{_datadir}/icons/hicolor/108x108/apps/%{name}.png
%{_datadir}/icons/hicolor/128x128/apps/%{name}.png
%{_datadir}/icons/hicolor/172x172/apps/%{name}.png
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_bindir}/%{name}
