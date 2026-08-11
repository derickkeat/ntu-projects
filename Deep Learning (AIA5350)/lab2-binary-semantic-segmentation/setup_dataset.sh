#!/bin/bash
set -e

DEST="dataset/oxford-iiit-pet"

if [ -d "$DEST/images" ] && [ -d "$DEST/annotations" ]; then
    echo "Dataset already exists at $DEST, skipping."
    exit 0
fi

mkdir -p "$DEST"

echo "Downloading images..."
curl -L https://thor.robots.ox.ac.uk/~vgg/data/pets/images.tar.gz -o /tmp/pet_images.tar.gz

echo "Downloading annotations..."
curl -L https://thor.robots.ox.ac.uk/~vgg/data/pets/annotations.tar.gz -o /tmp/pet_annotations.tar.gz

echo "Extracting..."
tar -xzf /tmp/pet_images.tar.gz -C "$DEST" --strip-components=1
tar -xzf /tmp/pet_annotations.tar.gz -C "$DEST" --strip-components=1

rm /tmp/pet_images.tar.gz /tmp/pet_annotations.tar.gz

echo "Done. Dataset ready at $DEST"
