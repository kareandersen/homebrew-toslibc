# TOS/libc Homebrew Tap

![Build status](https://github.com/kareandersen/homebrew-toslibc/actions/workflows/build.yml/badge.svg)

> This Homebrew formula packages the excellent [TOS/libc](https://github.com/frno7/toslibc) project by **Fredrik Noring** — a modern C standard library tailored for Atari TOS development. All credit for the library and the tools goes to [Fredrik](https://github.com/frno7). This tap simply makes it easier to install and use on macOS via Homebrew.

## Installation

```sh
brew tap kareandersen/toslibc
brew install --HEAD toslibc
```

> **Note:** Required dependencies, including `m68k-elf-gcc` and `m68k-elf-binutils`, will be installed automatically by Homebrew.

## Usage

To compile programs using `TOS/libc`, utilize `pkg-config` to retrieve the necessary compiler and linker flags.

### Compile Flags

```sh
pkg-config --cflags toslibc
```

### Linker Flags

```sh
pkg-config --libs toslibc
```

### Additional Linker Flags

Some linker flags need to be specified separately:

```sh
pkg-config --variable=TOSLIBC_LDFLAGS toslibc
```

In your `Makefile`, you might integrate these as follows:

```make
CFLAGS += $(shell pkg-config --cflags toslibc)
LDFLAGS += $(shell pkg-config --libs toslibc)
EXTRA_LDFLAGS += $(shell pkg-config --variable=TOSLIBC_LDFLAGS toslibc)
```

> ⚠️ **Important:** `TOSLIBC_LDFLAGS` must appear last in the final link command to avoid section garbage collection issues.

## TOSLink

This formula installs the `toslink` utility — a custom linker that converts ELF object files into Atari TOS executable files.

To use `toslink`, you must first generate a relocatable object file (`.r.o`) from your compiled `.o` file using `m68k-elf-ld`. This step requires a custom linker script (`prg.ld`), which is automatically referenced when using the flags provided by `pkg-config`.

```sh
m68k-elf-ld myprog.o $(pkg-config --libs toslibc) $(pkg-config --variable=TOSLIBC_LDFLAGS toslibc) -o myprog.r.o
```

Then invoke `toslink` to produce the final Atari TOS executable:

```sh
toslink -o myprog.prg myprog.r.o
```

The linker script (`prg.ld`) ensures proper memory layout and section alignment for TOS compatibility. It is installed alongside the library and referenced via the `TOSLIBC_LDFLAGS` variable, so you typically don’t need to reference it manually.

`toslink` is placed in your `PATH` for easy access after installation.

## Examples

Example source files and a working `Makefile` are installed to:

```
$(brew --prefix)/share/toslibc/examples
```

To build the examples:

```sh
cd $(brew --prefix)/share/toslibc/examples
make
```

## Testing

To verify the installation:

```sh
brew test toslibc
```

This compiles and links a small test program using all relevant `pkg-config` flags, and checks that it generates a valid TOS executable.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your enhancements.

## License

This formula and its packaging metadata are distributed under the terms of the [LGPL-2.1 License](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html), consistent with the upstream `TOS/libc` licensing model.

Upstream `TOS/libc` is triple-licensed under:

- **GPL-2.0**
- **LGPL-2.1**
- **MIT**

See the upstream project for full licensing details.

