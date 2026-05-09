mkdir -p tileable_out

for f in *.png; do
  w=$(magick identify -format "%w" "$f")
  h=$(magick identify -format "%h" "$f")

  magick "$f" \
    \( +clone -flop \) +append \
    \( "$f" -flip \) \
    \( "$f" -flop -flip \) +append \
    -append \
    -gravity center \
    -crop "${w}x${h}+0+0" +repage \
    "tileable_out/${f%.png}_tileable.png"
done
