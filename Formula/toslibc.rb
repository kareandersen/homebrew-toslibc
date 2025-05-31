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
      "prefix=#{prefix}",
      "bindir=#{opt_bin}",
      "datarootdir=#{pkgshare}",
      "libdir=#{prefix}/usr/lib",
      "includedir=#{prefix}/usr/include",
      "ldscriptdir=#{lib}/script",
      "exampledir=#{pkgshare}/example",
      "DESTDIR=#{stage_dir}",
      "TARGET_COMPILE=m68k-elf-",
      "CC=#{host_cc}"

    example_src = stage_dir/pkgshare.relative_path_from(Pathname.new("/"))/"example"
    (pkgshare/"example").install Dir[example_src/"*"]

    (prefix/"usr/include").install Dir["include/toslibc/*"]
    (prefix/"usr/lib").install "lib/libc.a"
    (prefix/"lib/script").install "script/prg.ld"

    system "make",
      "install-pkg-config",
      "prefix=#{prefix}",
      "libdir=#{opt_prefix}/usr/lib",
      "includedir=#{opt_prefix}/usr/include",
      "ldscriptdir=#{opt_prefix}/lib/script",
      "DESTDIR=#{stage_dir}"

    staged_pc = stage_dir/opt_prefix.relative_path_from(Pathname.new("/"))/"usr/lib/pkgconfig/toslibc.pc"
    inreplace staged_pc do |s|
      s.gsub! prefix, opt_prefix
    end
    (lib/"pkgconfig").install staged_pc
  end

  def caveats
    <<~EOS
      Example programs have been installed to:
        #{opt_pkgshare}/example

      To build them:
        cd #{opt_pkgshare}/example
        make clean all

      You must have `m68k-atari-tos-gnu-gcc` in your PATH.

      You can use `pkg-config` to query compiler and linker flags:
        pkg-config toslibc --cflags --libs
      (Note: `m68k-atari-tos-gnu-gcc` applies these flags by default.)

      If you encounter build errors referencing macOS SDK paths,
      make sure to unset environment variables like `CFLAGS` and `CPATH`
      which may interfere with cross-compilation.
    EOS
  end

  test do
    assert_path_exists prefix/"usr/include/stdio.h", :exist?
    assert_path_exists prefix/"usr/lib/libc.a", :exist?
    assert_path_exists lib/"script/prg.ld", :exist?

    output = shell_output("pkg-config toslibc --cflags --libs")
    assert_match "-isystem", output
    assert_match "-L#{opt_prefix}/usr/lib", output
    assert_match "--script=#{opt_prefix}/usr/lib/script/prg.ld", output
  end
end
