# Harfbuzz

## INFO

Block that wraps the [Harfbuzz](https://www.freedesktop.org/wiki/Software/HarfBuzz/) OpenType text shaping engine. Includes an installation script for building on multiple platforms.

## INSTALLATION

- First, `git clone git@github.com:ryanbartley/Cinder-Harfbuzz.git`. Also, make sure you've pulled [this](https://github.com/ryanbartley/Cinder/tree/CairoUpdate) branch of Cinder, which currently contains the needed Cairo build dependencies. Follow the instructions [here](https://github.com/ryanbartley/Cinder/blob/CairoUpdate/blocks/Cairo/README.md) to build the libraries for your current platform. This will hopefully be merged soon, making this step unneeded.
- You'll notice that this block doesn't contain the normal `lib/` and `include/` folders, as much of this is still in the experimental phase and supports building on multiple platforms. This support is found in the `install/` folder.
- On Mac and Linux, `cd install && ./install.sh [platform]` to build the Harfbuzz library. Possible choices for [platform] are `linux`, `macosx`, `ios`.
- On Windows, open a visual studio command prompt for the platform you'd like to build for. Then `cd path\to\Cinder-Harfbuzz\install && install.bat`. 
- These scripts will build for a while, not too long and you'll be left with Harfbuzz libraries and includes in the normal Cinder block format of `lib/[platform]` and `include/[platform]`.
- Like the cairo block, after the build, there'll be a `tmp/` folder left in the install folder containing the final install folders built from the script and useable for other libraries that depend on this one, such as pango.

