class Toslibc < Formula
  desc "TOS/libc is a 32-bit C standard library to compile programs for Atari TOS."
  homepage "https://github.com/frno7/toslibc"
  head "https://github.com/kareandersen/toslibc.git", branch: "Fix_aes_last_triangle"
  license "LGPL-2.1"

  depends_on "gcc" => :build    #Homebrew gcc, needed for endian extensions
  depends_on "pkg-config"
  depends_on "m68k-elf-binutils"
  depends_on "m68k-elf-gcc"

  def install
    gcc_major = Formula["gcc"].any_installed_version.major
    host_cc = Formula["gcc"].opt_bin/"gcc-#{gcc_major}"

    system "make", "CC=#{host_cc}", "TARGET_COMPILE=m68k-elf-"

    (prefix/"usr/include").install Dir["include/toslibc/*"]
    (prefix/"usr/lib").install "lib/toslibc.a" => "libtoslibc.a"
    (prefix/"script").install "script/prg.ld"
    bin.install "tool/toslink"

    gcc_include = Utils.safe_popen_read(Formula["m68k-elf-gcc"].opt_bin/"m68k-elf-gcc", "-print-file-name=include").chomp

    (pkgconfig = lib/"pkgconfig").mkpath
    (pkgconfig/"toslibc.pc").write <<~EOS
  prefix=#{opt_prefix}
  exec_prefix=${prefix}
  includedir=${prefix}/usr/include
  libdir=${prefix}/usr/lib
  ldscriptdir=${prefix}/script
  ldscript=${ldscriptdir}/prg.ld
  required_ldflags=-nostdlib --relocatable --gc-sections --strip-all --entry _start

  Name: toslibc
  Description: 32-bit C standard library for Atari TOS
  Version: HEAD
  Cflags: -nostdinc -I${includedir} -isystem #{gcc_include}
  Libs: -L${libdir} -ltoslibc ${required_ldflags}
EOS
    end

    test do
      (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include <stdlib.h>
      #include <tos/gemdos.h>

      int main(int argc, char** argv) {
        printf("Hello TOS!\\r\\n");
        return 0;
      }
EOS

      cc = Formula["m68k-elf-gcc"].opt_bin/"m68k-elf-gcc"
      ld = Formula["m68k-elf-binutils"].opt_bin/"m68k-elf-ld"
      toslink = bin/"toslink"
      pkg = Formula["pkg-config"].opt_bin/"pkg-config"

      cflags   = Utils.safe_popen_read(pkg, "--cflags", "toslibc").chomp.split
      ldflags  = Utils.safe_popen_read(pkg, "--libs", "toslibc").chomp.split
      ldscript = Utils.safe_popen_read(pkg, "--variable=ldscript", "toslibc").chomp

      raise "Compilation failed" unless system(cc, *cflags, "-c", "test.c", "-o", "test.o")
      raise "Linking failed" unless system(ld, *ldflags, "-T", ldscript, "test.o", "-o", "test.r.o")
      rainse "TOS conversion failed" unless system(toslink, "-o", "test.prg", "test.r.o")
      assert_predicate testpath/"test.prg", :exist?

      output = shell_output("file test.prg")
      puts "resulting test binary: #{output}"
      assert_match "Atari ST M68K contiguous executable", output
    end
end
