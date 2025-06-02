class M68kAtariTosGnuGcc < Formula
  desc "32-bit C compiler for Atari TOS"
  homepage "https://github.com/frno7/toslibc"
  license any_of: ["GPL-2.0-only", "LGPL-2.1-only", "MIT"]
  url "https://github.com/frno7/toslibc/archive/refs/tags/v0.3.tar.gz"
  sha256 "f9a83bc67c05abf72001e1ed7ac013fcf01701789a44173edb9d0e0e67bbceb5"
  head "https://github.com/frno7/toslibc.git", branch: "main"

  depends_on "gcc" => :build
  depends_on "kareandersen/toslibc/m68k-atari-tos-gnu-binutils"
  depends_on "kareandersen/toslibc/toslibc"
  depends_on "m68k-elf-gcc"

  def install
    ENV.delete("CPATH")
    ENV.delete("SDKROOT")
    ENV.remove "CFLAGS", "-isysroot"
    ENV.remove "CPPFLAGS", "-isysroot"

    gcc_major = Formula["gcc"].any_installed_version.major
    host_cc = Formula["gcc"].opt_bin/"gcc-#{gcc_major}"
    toslibc_prefix = Formula["kareandersen/toslibc/toslibc"].opt_prefix
    binutils_prefix = Formula["kareandersen/toslibc/m68k-atari-tos-gnu-binutils"].opt_prefix

    stage_dir = buildpath/"stage"

    system "make",
      "install-compiler",
      "prefix=#{prefix}",
      "exec-prefix=#{prefix}",
      "bindir=#{opt_bin}",
      "datarootdir=#{pkgshare}",
      "exampledir=#{pkgshare}/example",
      "includedir=#{toslibc_prefix}/usr/include",
      "libdir=#{toslibc_prefix}/usr/lib",
      "ldscriptdir=#{binutils_prefix}/lib/script",
      "binutilsbindir=#{binutils_prefix}/bin",
      "DESTDIR=#{stage_dir}",
      "TARGET_COMPILE=m68k-elf-",
      "CC=#{host_cc}"

    staged_root = stage_dir/opt_prefix.relative_path_from(Pathname.new("/"))
    prefix.install Dir[staged_root/"*"]
  end

  def caveats
    <<~EOS
      Depends on `toslibc` for headers, libraries, and linker scripts,
      and uses `m68k-atari-tos-gnu-binutils` for assembling and linking.
    EOS
  end

  test do
    system bin/"m68k-atari-tos-gnu-gcc", "--version"
    system bin/"m68k-atari-tos-gnu-cc", "--version"
  end
end
