# Get array of all icons installed
#
# Args:
#   1. prefix
#   2. Array to collect into
collectInstalledIcons() {
  local -r prefix="$1"
  local -n collection="$2"

  # Where we are looking
  local -r path="$prefix/share/icons/hicolor"

  # Only look at png and svg, not whatever else someone might have
  # mistakenly put in there
  readarray -td '' collection < (find "$path" -iwholename "$path/*/app/*.png" -o -iwholename "$path/*/app/*.svg" -print0)
}

resampleIconsHook() {
  # Required so that we can install icons once we
  # create them.
  if [[ "$(type -t installIcon)" != "function" ]]; then
    echo "resameplIconsHook: ERROR: installIconsHook must be used"
    exit 1
  fi

  # If the user defined the sizes to generate
  if [[ -v resampleIconSizes ]]; then
    local -rai RASTER_SIZES=("${resampleIconSizes[@]}")
  else
    local -rai RASTER_SIZES=(
      8
      16
      32
      46
      64
      96
      128
      256
      512
    )
  fi

  # Get the current icons installed
  local -a iconsInstalled=()
  collectInstalledIcons "$prefix" iconsInstalled

  # Track what sizes have already been installed.
  # We never want to overwrite something.
  local -A iconsGenerated=()
  for icon in "${iconsInstalled[@]}"; do
    # Seperate the path at the slashes
    IFS="/" read -ra parts <<< "$path"

    #   1    2        3        4     5      6     7    8    9
    # /nix/store/aaaaa-thing/share/icons/hicolor/{NxN, scalable}/apps/icon.png
    #
    # Extract the icon type
    local -r iconType="${parts[7],,}"

    if [[ "$iconType" = "scalable" ]]; then
      iconsInstalled["svg"]="$icon"
    else
      # Extract the path segement "NxN" to a number
      iconsInstalled["${type%%x*}"]="$icon"
    fi
  done

  # The optimal icon that is already installed for resampling
  if [[ -v iconsInstalled["svg"] ]]; then
    # SVG is always the "largest"
    local -r bestScaler="${iconsInstalled["svg"]}"
  else
    # Get the largest raster size
    local -r largestSize="$(printf "%s\n" "${!iconsInstalled[@]}" | sort -n | tail -1)"
    local -r bestScaler="${iconsInstalled["$largestSize"]}"
  fi

  # Use the user supplied icon if set
  local -r scalingIcon="${iconToResample:-"$bestScaler"}"
  echo "resampleIconsHook: '$scalingIcon' to be resampled"


  # Create a dir to place these scaled icons in
  local -r scalingDir="$(mktemp -d)"

  # Identify whether the scaler is an SVG or not.
  #
  # Note this could be user-supplied (aka outside the output path) and not have an svg extension
  if [[ "$(magick identify -format "%m" "$scalingIcon" 2>/dev/null)" = "SVG" ]]; then
    # If it is an SVG, then just set it to something larger than any icon we will find
    local -ri scalingSize=2048
  else
    # If not an SVG, get the largest dimenion of the image via imagemagick identify
    local -ri scalingSize="$(magick identify -format "%[fx:w>h?w:h]" "$scalingIcon")"
  fi

  for size in "${RASTER_SIZES[@]}"; do
    if (( scalingSize < $size )); then
      # If our scaling image is smaller than the raster size,
      # exit the loop
      echo "resampleIconsHook: size limit reached at $size, stopping."
      break
    fi

    if [[ ! -v iconsInstalled["$size"] ]]; then
      # Only create a new icon if there is not one for the respective size yet.

      # Use imagemagick to make exact fit icons
      #
      # 1. Resize to fit inside bounding box
      # 2. Set bg to transparent
      # 3. Center the icon
      # 4. Make the icon exactly the correct size
      magick "$scalingIcon" \
        -resize "$size" \
        -background none \
        -gravity center \
        -extent "$size" \
        "$scalingDir/$size.png"

      echo "resampleIconsHook: '${size}x${size}' icon created"

      # Install the newly created icon
      installIcon "$prefix" "$scalingDir/$size.png" "${iconInstallName:-$NIX_MAIN_PROGRAM}" "${size}x${size}"
      iconsInstalled["$size"]="$scalingDir/$size.png"
    fi
  done
}

fixupOutputHooks+=( resampleIconsHook )
