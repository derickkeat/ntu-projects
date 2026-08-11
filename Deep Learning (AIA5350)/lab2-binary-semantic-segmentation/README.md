# Lab 2 - Binary Semantic Segmentation

## Dataset Setup

The `dataset/oxford-iiit-pet/` directory is not tracked by git due to its size. The `dataset/taica/` split files are tracked.

### Oxford-IIIT Pet Dataset

Download from the official source:

1. Download images and annotations from https://www.robots.ox.ac.uk/~vgg/data/pets/
2. Extract into `dataset/oxford-iiit-pet/`

Expected structure:

```
dataset/oxford-iiit-pet/
├── images/          # Pet images (*.jpg)
└── annotations/
    ├── trimaps/     # Segmentation masks (*.png)
    ├── xmls/        # Bounding box annotations
    ├── list.txt
    ├── trainval.txt
    └── test.txt
```