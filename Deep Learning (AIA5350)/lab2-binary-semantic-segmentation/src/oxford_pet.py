import os
import numpy as np
import torch
from torch.utils.data import Dataset
from PIL import Image


class PetSegmentationDataset(Dataset):
    def __init__(self, data_root, split_dir, split, transform=None):
        split_file = os.path.join(split_dir, f"{split}.txt")
        with open(split_file) as f:
            names = [line.strip() for line in f if line.strip()]

        self.image_paths = [os.path.join(data_root, "images", f"{n}.jpg") for n in names]
        self.mask_paths = [os.path.join(data_root, "annotations", "trimaps", f"{n}.png") for n in names]
        self.transform = transform

    def __len__(self):
        return len(self.image_paths)

    def __getitem__(self, idx):
        image = np.array(Image.open(self.image_paths[idx]).convert("RGB"))
        mask = np.array(Image.open(self.mask_paths[idx]))

        # Remap mask: {1 -> 1 (pet), 2 -> 0 (background), 3 -> 0 (background)}
        remapped = np.zeros_like(mask, dtype=np.int64)
        remapped[mask == 1] = 1
        mask = remapped

        if self.transform:
            transformed = self.transform(image=image, mask=mask)
            image = transformed["image"]
            mask = transformed["mask"]

        # With transform (ToTensorV2): image=float32 CHW tensor, mask=int64 tensor
        # Without transform: image=uint8 HWC numpy array, mask=int64 numpy array
        return image, mask
