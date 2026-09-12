Name:           claude-code
Version:        2.1.269
Release:        1%{?dist}
Summary:        Claude Code - Anthropic's official agentic CLI tool

License:        Commercial
URL:            https://code.claude.com

# Define architecture-specific sources dynamically
%ifarch x86_64
Source0:        https://downloads.claude.ai/claude-code-releases/%{version}/linux-x64/claude#/claude-%{_arch}
%endif
%ifarch aarch64
Source0:        https://downloads.claude.ai/claude-code-releases/%{version}/linux-arm64/claude#/claude-%{_arch}
%endif

# Turn off the debug package generation and automated binary stripping 
# since this is a pre-compiled, minified third-party binary.
%define debug_package %{nil}
%define __strip /bin/true

%description
Claude Code is a command-line interface tool by Anthropic that allows you 
to interact directly with Claude from your terminal. It can understand 
your codebase, edit files, execute terminal commands, and handle complex 
git/development workflows.

%prep
# No source tarball extraction is needed. 
# Create the build directory and copy the single raw binary manually.
%setup -q -c -T
cp %{SOURCE0} .

%build
# No compilation required for pre-built binaries.

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p %{buildroot}%{_bindir}

# Install the binary into /usr/bin/ and ensure it is executable
install -p -m 0755 claude-%{_arch} %{buildroot}%{_bindir}/claude

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_bindir}/claude

%changelog
* Sat Sep 12 2026 Package Maintainer <maintainer@example.com> - 2.1.269-1
- Updated to official Claude Code release version 2.1.269.
* Sat Aug 01 2026 Package Maintainer <maintainer@example.com> - 2.1.220-1
- Updated to official Claude Code release version 2.1.220 for Linux ARM64.

