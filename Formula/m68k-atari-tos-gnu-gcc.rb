class M68kAtariTosGnuGcc < Formula
  desc "32-bit C compiler for Atari TOS"
  homepage "https://github.com/frno7/toslibc"
  license any_of: ["GPL-2.0-only", "LGPL-2.1-only", "MIT"]
  head "https://github.com/frno7/toslibc.git", branch: "main"

  depends_on "gcc" => :build
  depends_on "kareandersen/toslibc/toslibc"
  depends_on "m68k-elf-gcc"

  def install
    ENV.delete("CPATH")
    ENV.delete("SDKROOT")
    ENV.remove "CFLAGS", "-isysroot"
    ENV.remove "CPPFLAGS", "-isysroot"

    stage_dir = buildpath/"stage"
    sysroot = opt_prefix
    gcc_major = Formula["gcc"].any_installed_version.major
    host_cc = Formula["gcc"].opt_bin/"gcc-#{gcc_major}"
    toslibc_prefix = Formula["kareandersen/toslibc/toslibc"].opt_prefix

    system "make",
      "install-compiler",
      "install-binutils",
      "prefix=#{toslibc_prefix}",
      "exec-prefix=#{sysroot}",
      "bindir=#{opt_bin}",
      "datarootdir=#{pkgshare}",
      "exampledir=#{pkgshare}/example",
      "includedir=#{toslibc_prefix}/usr/include",
      "libdir=#{toslibc_prefix}/usr/lib",
      "ldscriptdir=#{toslibc_prefix}/lib/script",
      "DESTDIR=#{stage_dir}",
      "TARGET_COMPILE=m68k-elf-",
      "CC=#{host_cc}"

    staged_root = stage_dir/sysroot.relative_path_from(Pathname.new("/"))

    bin.install Dir[staged_root/"bin/*"]
    include.install Dir[staged_root/"include/*"] if (staged_root/"include").exist?
    lib.install Dir[staged_root/"lib/*"] if (staged_root/"lib").exist?
  end

  test do
    system bin/"m68k-atari-tos-gnu-gcc", "--version"
    system bin/"m68k-atari-tos-gnu-cc", "--version"
    system bin/"m68k-atari-tos-gnu-ld", "--version"
    system bin/"m68k-atari-tos-gnu-toslink", "--version"
  end
end
