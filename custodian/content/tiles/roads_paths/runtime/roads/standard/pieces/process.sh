cd /home/braydenchaffee/Projects/CUSTODIAN/custodian/content/tiles/roads_paths/runtime/roads/standard/pieces

mkdir -p no_outline_runtime

for f in *.png; do
	read w h < <(magick identify -format "%w %h" "$f")

	magick "$f" \
		-shave 1x1 \
		-filter Lanczos \
		-resize "${w}x${h}!" \
		"no_outline_runtime/$f"

	echo "processed $f -> no_outline_runtime/$f (${w}x${h})"
done
