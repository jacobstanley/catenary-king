#!/bin/sh
while inotifywait -r src/; do
    fay --pretty --output js/catking.js --include src/ src/CatenaryKing.hs
done
