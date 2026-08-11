import time
import torch
import albumentations as A
from albumentations.pytorch import ToTensorV2
from torch.utils.data import DataLoader
from src.models.unet import UNet
from src.models.resnet34_unet import ResNet34UNet
from src.oxford_pet import PetSegmentationDataset
from src.utils import dice_score, pad_for_model


def evaluate(args):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    val_transform = A.Compose([
        A.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)),
        ToTensorV2(),
    ])

    val_dataset = PetSegmentationDataset(args.data_root, args.split_dir, "val", transform=val_transform)
    val_loader = DataLoader(val_dataset, batch_size=1, shuffle=False, num_workers=4)

    # Load model
    if args.model == "resnet34_unet":
        model = ResNet34UNet(in_channels=3, out_channels=2).to(device)
    else:
        model = UNet(in_channels=3, out_channels=2).to(device)
    checkpoint = torch.load(args.model_path, map_location=device)
    if isinstance(checkpoint, dict) and "model_state_dict" in checkpoint:
        model.load_state_dict(checkpoint["model_state_dict"])
        print(f"Loaded checkpoint from epoch {checkpoint.get('epoch', '?')} (dice: {checkpoint.get('dice', '?')})")
    else:
        model.load_state_dict(checkpoint)
    model.eval()

    print(f"Using device: {device}")
    print(f"Model: {args.model_path}")
    print(f"Validation samples: {len(val_dataset)}")
    print("-" * 60)

    total_dice = 0.0
    num_samples = 0
    start_time = time.time()

    with torch.no_grad():
        for images, masks in val_loader:
            images = images.to(device)
            masks = masks.to(device).long()

            pad_factor = 32 if args.model == "resnet34_unet" else 16
            images, (orig_h, orig_w), (pad_top, pad_left) = pad_for_model(images, factor=pad_factor)
            outputs = model(images)
            preds = outputs.argmax(dim=1)[:, pad_top:pad_top + orig_h, pad_left:pad_left + orig_w]

            for i in range(preds.shape[0]):
                total_dice += dice_score(preds[i], masks[i]).item()
                num_samples += 1

    elapsed = time.time() - start_time
    avg_dice = total_dice / num_samples
    print("-" * 60)
    print(f"Samples evaluated: {num_samples}")
    print(f"Dice score:        {avg_dice:.4f}")
    print(f"Total time:        {elapsed:.1f}s ({elapsed / num_samples:.2f}s/sample)")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, choices=["unet", "resnet34_unet"], required=True)
    parser.add_argument("--data_root", type=str, default="dataset/oxford-iiit-pet")
    parser.add_argument("--split_dir", type=str, default="dataset/taica")
    parser.add_argument("--model_path", type=str, default=None)
    args = parser.parse_args()
    if args.model_path is None:
        args.model_path = f"saved_models/{args.model}_best.pth"

    evaluate(args)
