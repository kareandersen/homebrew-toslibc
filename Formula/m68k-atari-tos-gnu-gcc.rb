class M68kAtariTosGnuGcc < Formula
  desc "32-bit C compiler for Atari TOS"
  homepage "https://github.com/frno7/toslibc"
  head "https://github.com/frno7/toslibc.git", branch: "main"
  license "GPL-2"

  depends_on "gcc" => :build
  depends_on "m68k-elf-gcc"
  depends_on "kareandersen/toslibc/toslibc"

  def install
    ENV.delete("CPATH")
    ENV.delete("SDKROOT")
    ENV.remove "CFLAGS", "-isysroot"
    ENV.remove "CPPFLAGS", "-isysroot"

  stage_dir = buildpath/"stage"
  toolchain_prefix = "m68k-atari-tos-gnu"
  sysroot = opt_prefix
  gcc_major = Formula["gcc"].any_installed_version.major
  host_cc = Formula["gcc"].opt_bin/"gcc-#{gcc_major}"
  toslibc_prefix = Formula["kareandersen/toslibc/toslibc"].opt_prefix

  system "make",
    "install-compiler",
    "install-binutils",
    "prefix=#{toslibc_prefix}",
    "exec-prefix=#{sysroot}",
    "toolchain-prefix=#{toolchain_prefix}",
    "bindir=#{opt_bin}",
    "includedir=#{toslibc_prefix}/usr/include",
    "libdir=#{toslibc_prefix}/usr/lib",
    "ldscriptdir=#{toslibc_prefix}/lib/script",
    "DESTDIR=#{stage_dir}",
    "TARGET_COMPILE=m68k-elf-",
    "CC=#{host_cc}"

    staged_root = stage_dir/sysroot.relative_path_from(Pathname.new("/"))

    bin.install Dir[staged_root/"bin/#{toolchain_prefix}-*"]
    include.install Dir[staged_root/"include/*"] if (staged_root/"include").exist?
    lib.install Dir[staged_root/"lib/*"] if (staged_root/"lib").exist?
  end

  test do
    system "#{bin}/m68k-atari-tos-gnu-gcc", "--version"
    system "#{bin}/m68k-atari-tos-gnu-cc", "--version"
  end
end

