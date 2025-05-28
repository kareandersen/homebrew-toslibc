class M68kAtariTosGnu < Formula
  desc "32-bit C compiler for Atari TOS"
  homepage "https://github.com/frno7/toslibc"
  head "https://github.com/frno7/toslibc.git", branch: "main"
  license "GPL-2"

  depends_on "gcc" => :build
  depends_on "m68k-elf-gcc"
  depends_on "m68k-elf-binutils"
  depends_on "kareandersen/toslibc/toslibc"

  def install
    ENV.delete("CPATH")
    ENV.delete("SDKROOT")
    ENV.remove "CFLAGS", "-isysroot"
    ENV.remove "CPPFLAGS", "-isysroot"
    gcc_major = Formula["gcc"].any_installed_version.major
    host_cc = Formula["gcc"].opt_bin/"gcc-#{gcc_major}"

    sysroot = "/usr/m68k-atari-tos-gnu"
    stage_dir = buildpath/"stage"

    system "make", "install-compiler",
      "prefix=#{sysroot}",
      "exec-prefix=#{sysroot}/bin",
      "toolchain-prefix=#{sysroot}",
      "bindir=#{sysroot}/bin",
      "DESTDIR=#{stage_dir}",
      "TARGET_COMPILE=m68k-elf-",
      "CC=#{host_cc}"

    bin_path = stage_dir/"usr/m68k-atari-tos-gnu/bin"
    bin.install Dir[bin_path/"m68k-atari-tos-gnu-*"]

    (prefix/"sysroot").install Dir[stage_dir/"usr/m68k-atari-tos-gnu/*"]
  end

  test do
    system "#{bin}/m68k-atari-tos-gnu-gcc", "--version"
  end
end

