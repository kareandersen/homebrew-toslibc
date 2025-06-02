class Toslibc < Formula
  desc "32-bit C standard library for Atari TOS"
  homepage "https://github.com/frno7/toslibc"
  license any_of: ["GPL-2.0-only", "LGPL-2.1-only", "MIT"]
  head "https://github.com/frno7/toslibc.git", branch: "main"

  depends_on "gcc" => :build
  depends_on "m68k-elf-binutils"
  depends_on "m68k-elf-gcc"
  depends_on "pkg-config"

  def install
    ENV.delete("CPATH")
    ENV.delete("SDKROOT")
    ENV.remove "CFLAGS", "-isysroot"
    ENV.remove "CPPFLAGS", "-isysroot"

    gcc_major = Formula["gcc"].any_installed_version.major
    host_cc = Formula["gcc"].opt_bin/"gcc-#{gcc_major}"
    stage_dir = buildpath/"stage"

    system "make",
      "install-lib",
      "install-example",
      "install-prg.ld-script",
      "prefix=#{opt_prefix}",
      "bindir=#{opt_bin}",
      "datarootdir=#{opt_prefix}/share",
      "libdir=#{opt_prefix}/usr/lib",
      "includedir=#{opt_prefix}/usr/include",
      "ldscriptdir=#{opt_prefix}/lib/script",
      "exampledir=#{opt_pkgshare}/example",
      "pkgconfigdir=#{opt_prefix}/lib/pkgconfig",
      "DESTDIR=#{stage_dir}",
      "TARGET_COMPILE=m68k-elf-",
      "CC=#{host_cc}"

    staged_root = stage_dir/opt_prefix.relative_path_from(Pathname.new("/"))
    prefix.install Dir[staged_root/"*"]
  end

  def caveats
    <<~EOS
      Example programs have been installed to:
        #{opt_pkgshare}/example

      To build them:
        cd #{opt_pkgshare}/example
        make clean && make

      You must have `m68k-atari-tos-gnu-gcc` in your PATH.

      Alternatively, you can use `pkg-config` with m68k-elf-gcc:
        pkg-config toslibc --cflags --libs

      Linker script note:
        The `prg.ld` installed by this formula is provided for use with
        `m68k-elf-gcc` via `toslibc.pc`. A separate copy is installed by
        the `m68k-atari-tos-gnu-binutils` formula for use with
        `m68k-atari-tos-gnu-ld`.

      Troublehooting:
        If you encounter build errors referencing macOS SDK paths,
        make sure to unset environment variables like `CFLAGS` and `CPATH`
        which may interfere with cross-compilation.
    EOS
  end

  test do
    cflags = shell_output("pkg-config --cflags toslibc")
    include_path = cflags[/-isystem\s+(\S+)/, 1]
    assert_path_exists Pathname.new(include_path)

    libs = shell_output("pkg-config --libs toslibc")
    lib_path = libs[/-L(\S+)/, 1]
    assert_path_exists Pathname.new(lib_path)

    script_path = libs[/--script=(\S+)/, 1]
    assert_path_exists Pathname.new(script_path)
  end
end
