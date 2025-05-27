class Toslibc < Formula
  desc "TOS/libc is a 32-bit C standard library to compile programs for Atari TOS"
  homepage "https://github.com/frno7/toslibc"
  license "LGPL-2.1-only"
  head "https://github.com/frno7/toslibc.git", branch: "main"

  depends_on "gcc" => :build
  depends_on "m68k-elf-binutils"
  depends_on "m68k-elf-gcc"
  depends_on "pkg-config"

  def install
    examples_src = buildpath/"example"
    examples_dst = pkgshare/"examples"
    examples_dst.mkpath

    cp_r examples_src.children, examples_dst, preserve: true
    #Temporary step as we converge on a single makefile
    (examples_dst/"Makefile.brew").atomic_write <<~EOS
      #  SPDX-License-Identifier: LGPL-2.1

      PRGS\t= alert.prg cookie.tos hello.tos window.prg xbra.prg

      # Derive source files
      SRCS\t= $(patsubst %.prg,%.c,$(patsubst %.tos,%.c,$(PRGS)))
      OBJS\t= $(SRCS:.c=.o)
      ROBJS\t= $(OBJS:.o=.r.o)

      CC\t= m68k-elf-gcc
      LD\t= m68k-elf-ld
      TOSLINK\t= m68k-atari-tos-gnu-toslink

      CFLAGS   = $(shell pkg-config --cflags toslibc)
      LDLIBS   = $(shell pkg-config --libs toslibc)
      LDFLAGS  = $(shell pkg-config --variable=TOSLIBC_LDFLAGS toslibc)

      .PHONY: all clean

      all: $(PRGS)

      %.o: %.c
      \t$(CC) $(CFLAGS) -c -o $@ $<

      %.r.o: %.o
      \t$(LD) $< $(LDLIBS) $(LDFLAGS) -o $@

      %.prg: %.r.o
      \t$(TOSLINK) -o $@ $<

      %.tos: %.r.o
      \t$(TOSLINK) -o $@ $<

      clean:
      \trm -f *.o *.r.o *.prg *.tos
    EOS

    odie "Failed to write example/Makefile.brew" unless File.exist?(examples_dst/"Makefile.brew")

    gcc_major = Formula["gcc"].any_installed_version.major
    host_cc = Formula["gcc"].opt_bin/"gcc-#{gcc_major}"

    system "make", "CC=#{host_cc}", "TARGET_COMPILE=m68k-elf-"

    (prefix/"usr/include").install Dir["include/toslibc/*"]
    (prefix/"usr/lib").install "lib/libc.a" => "libtoslibc.a"
    (prefix/"script").install "script/prg.ld"
    bin.install "tool/m68k-atari-tos-gnu-toslink"

    m68k_gcc = Formula["m68k-elf-gcc"]
    gcc_bin = m68k_gcc.opt_bin/"m68k-elf-gcc"
    gcc_include = Utils.safe_popen_read(
      gcc_bin, "-print-file-name=include"
    ).chomp

    (pkgconfig = lib/"pkgconfig").mkpath
    (pkgconfig/"toslibc.pc").write <<~EOS
      prefix=#{opt_prefix}
      includedir=${prefix}/usr/include
      libdir=${prefix}/usr/lib
      ldscript=${prefix}/script/prg.ld

      Name: toslibc
      Description: 32-bit C standard library for Atari TOS
      Version: HEAD
      Cflags: -m68000 -isystem ${includedir} -fno-PIC
      Libs: -L${libdir} -ltoslibc
      TOSLIBC_LDFLAGS = -nostdlib --relocatable --gc-sections --strip-all --entry _start -T ${ldscript}
    EOS
  end

  def caveats
    <<~EOS
      Example programs have been installed to:
        #{opt_pkgshare}/examples

      To build them:
        cd #{opt_pkgshare}/examples
        make

      You must have `m68k-elf-gcc` and `pkg-config` in your PATH.

      If you encounter build errors referencing macOS SDK paths,
      make sure to unset environment variables like `CFLAGS` and `CPATH`
      which may interfere with cross-compilation.
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
    ldlibs   = Utils.safe_popen_read(pkg, "--libs", "toslibc").chomp.split
    ldflags  = Utils.safe_popen_read(pkg, "--variable=TOSLIBC_LDFLAGS", "toslibc").chomp.split

    with_env(   #macOS likes to bring in a lot of junk here
      "CFLAGS" => nil,
      "CPATH" => nil,
      "C_INCLUDE_PATH" => nil,
    ) do
      raise "Compilation failed" unless system(cc, *cflags, "-c", "test.c", "-o", "test.o")
    end

    raise "Linking failed" unless system(ld, *ldlibs, *ldflags, "test.o", "-o", "test.r.o")

    raise "TOS conversion failed" unless system(toslink, "-o", "test.prg", "test.r.o")

    assert_path_exists testpath/"test.prg"

    output = shell_output("file test.prg")
    puts "resulting test binary: #{output}"
    assert_match "Atari ST M68K contiguous executable", output
  end
end
