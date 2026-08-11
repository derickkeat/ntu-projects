import os
import csv
import torch
import numpy as np
import albumentations as A
from albumentations.pytorch import ToTensorV2
from torch.utils.data import DataLoader
from src.models.unet import UNet
from src.models.resnet34_unet import ResNet34UNet
from src.oxford_pet import PetSegmentationDataset
from src.utils import pad_for_model


def rle_encode(mask):
    """Run-length encode a binary mask (H, W) -> RLE string.

    Pixels are traversed in column-major (Fortran) order, as required for submission.
    """
    pixels = mask.flatten(order="F")
    pixels = np.concatenate([[0], pixels, [0]])
    runs = np.where(pixels[1:] != pixels[:-1])[0] + 1
    runs[1::2] -= runs[::2]
    return " ".join(str(x) for x in runs)


def inference(args):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")

    split = "test_res_unet" if args.model == "resnet34_unet" else "test_unet"

    test_transform = A.Compose([
        A.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)),
        ToTensorV2(),
    ])

    test_dataset = PetSegmentationDataset(args.data_root, args.split_dir, split, transform=test_transform)
    test_loader = DataLoader(test_dataset, batch_size=1, shuffle=False, num_workers=4)

    # Load model
    if args.model == "resnet34_unet":
        model = ResNet34UNet(in_channels=3, out_channels=2).to(device)
    else:
        model = UNet(in_channels=3, out_channels=2).to(device)
    checkpoint = torch.load(args.model_path, map_location=device)
    if isinstance(checkpoint, dict) and "model_state_dict" in checkpoint:
        model.load_state_dict(checkpoint["model_state_dict"])
    else:
        model.load_state_dict(checkpoint)
    model.eval()

    # Read image names
    split_file = os.path.join(args.split_dir, f"{split}.txt")
    with open(split_file) as f:
        image_names = [line.strip() for line in f if line.strip()]

    results = []
    sample_idx = 0

    with torch.no_grad():
        for images, masks in test_loader:
            images = images.to(device)

            pad_factor = 32 if args.model == "resnet34_unet" else 16
            images, (orig_h, orig_w), (pad_top, pad_left) = pad_for_model(images, factor=pad_factor)
            outputs = model(images)
            preds = outputs.argmax(dim=1)[:, pad_top:pad_top + orig_h, pad_left:pad_left + orig_w]

            for i in range(preds.shape[0]):
                pred_mask = preds[i].cpu().numpy().astype(np.uint8)
                name = image_names[sample_idx]
                results.append((name, rle_encode(pred_mask)))
                sample_idx += 1

    # Write CSV
    os.makedirs(os.path.dirname(args.output_csv) or ".", exist_ok=True)
    with open(args.output_csv, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["image_id", "encoded_mask"])
        writer.writerows(results)

    print(f"Test samples: {len(results)}")
    print(f"Saved to {args.output_csv}")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, choices=["unet", "resnet34_unet"], required=True)
    parser.add_argument("--data_root", type=str, default="dataset/oxford-iiit-pet")
    parser.add_argument("--split_dir", type=str, default="dataset/taica")
    parser.add_argument("--model_path", type=str, default=None)
    parser.add_argument("--output_csv", type=str, default="predictions.csv")
    args = parser.parse_args()
    if args.model_path is None:
        args.model_path = f"saved_models/{args.model}_best.pth"

    inference(args)
