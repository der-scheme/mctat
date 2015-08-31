# mctat – A tool for Minecraft resource artists

Mctat will help you build and pack your resource packs for Minecraft.

When I was creating my very own texture pack for Minecraft I quickly realized that the following workflow could be improved:

1. Modify the texture with the GIMP.
2. Save the texture and export.
3. Switch windows.
4. Create a zip file with all the required contents.
5. Move the zip file to the right directory.
6. (Launch Minecraft)

I decided to write a script that could automate that workflow.

## Workflow

Create your texture in one of the following formats: xcf (GIMP file), psd (Adobe Photoshop file), mcmeta. Mctat will automatically detect which files have changed, compile them into a Minecraft texture pack and move them to the right directory, so you can start testing your changes right away.

### Usage

Create a project with the following layout (mctat currently will not do that for you):

    ./pack.mcmeta
    ./assets
    ./assets/minecraft
    ./assets/minecraft/textures
    ./assets/minecraft/textures/blocks
    ./assets/minecraft/textures/colormap
    ./assets/minecraft/textures/misc
    ./LICENSE

Run `mctat.sh watch -m` and start building your textures. As soon as a file changes, mctat will utilize the GIMP to compile your textures, pack them into a zip archive, and move them to Minecraft's resource pack directory.

## Prerequisites

Mctat was developed and tested on Linux (Fedora 17-21), but is believed to also run on other Unixoids like OS X, and possibly on compatibility layers for Windows such as Cygwin.

### Tools

- gimp-console (CLI version of the GIMP)
- zip
- The usual suspects like awk, diff and grep

## Disclaimer

- Minecraft is a Sandbox Game by Mojang.
  Minecraft Website: http://www.minecraft.net/
- The term "Minecraft" is a trademark of Mojang.
  Mojang Website: http://www.mojang.com/
