Name:       harbour-countryquiz
Summary:    Country Quiz is a fun way to learn to identify flags, maps and capitals all around the world
Version:    0.4.1
Release:    1
License:    MIT
URL:        https://github.com/tomin-apps/countryquiz
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   qt5-qtdeclarative-import-xmllistmodel
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.3
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils
BuildRequires:  librsvg
BuildRequires:  librsvg-tools
BuildRequires:  python3-cairo
BuildRequires:  python3-gobject
BuildRequires:  python3-yaml
BuildRequires:  qt5-qttools-linguist

%description
%{summary}.

Country Quiz is a quiz game about states in the world. You can practise
identification of flags, maps and capitals. Results are collected into local
database for you to see your own progress.

You can also play Country Quiz with a friend competitively. Just enable Party
or Shared device mode and you can find out who knows the countries the best.

%prep
%autosetup -n %{name}-%{version}

%build

%ifarch i486
%qmake5 CONFIG+=no_multiprocessing
%else
%qmake5
%endif

%make_build

%install
%qmake5_install

desktop-file-install --delete-original --dir %{buildroot}%{_datadir}/applications %{buildroot}%{_datadir}/applications/%{name}.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
