
#### `iconToResample` {#install-icons-icon-to-resample}

If this attribute is set, it implies `resampleIcons` to be true.

This attribute takes in a path to an icon, relative to the current working directory.

This icon is then resampled to all icon dimensions that are smaller than its native dimension.

See []($instal-icons-hook-resample-icons) for more information, all information is applicable to this attribute.

#### `resampleIcons` {#install-icons-hook-resample-icons}

:::{.note}
This hook WILL NOT overwrite any detected or provided raster images with a resampled image.
If `iconsToInstall."64x64"` is set to a path, and an SVG file is provided to `iconToResample`,
a new icon 64x64 in size will not be created, and the provided or detected icon will be installed.
:::

This attribute informs the hook that it should resample an icon to create any missing icons of lower dimensions.
This the icon provided is an SVG file, then all icon dimensions will be created.

The order this hook looks for icons to resample is the following:

1. [`iconToResample`](#install-icons-icon-to-resample)
2. [`iconsToInstall.svg`](#install-icons-hook-icons-to-install)
3. A detected SVG file

If none of the above are found, the hook will exit with an error.

:::{.note}
This hook will only create icons of lower dimensions than provided. So if `iconToResample` is set
to the path of a 128x128 icon, it will not create an icon that is 256x256. SVG files will create any missing icons.
:::
