import os
import time
import torch
import torch.nn as nn
import torchvision.transforms.functional as TF
import albumentations as A
from albumentations.pytorch import ToTensorV2
from torch.utils.data import DataLoader
from src.models.unet import UNet
from src.models.resnet34_unet import ResNet34UNet
from src.oxford_pet import PetSegmentationDataset
from tqdm import tqdm
from src.utils import init_weights, dice_score, dice_loss, pad_for_model


def train(args):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    _norm = A.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225))
    _totensor = ToTensorV2()

    train_transform = A.Compose([
        A.LongestMaxSize(max_size=args.crop_size),
        A.PadIfNeeded(min_height=args.crop_size, min_width=args.crop_size),
        A.HorizontalFlip(),
        A.RandomBrightnessContrast(p=0.5),
        A.Rotate(limit=15, p=0.5),
        A.RandomScale(scale_limit=0.2, p=0.5),
        A.PadIfNeeded(min_height=args.crop_size, min_width=args.crop_size),
        A.RandomCrop(height=args.crop_size, width=args.crop_size),
        A.RGBShift(p=0.3),
        _norm,
        _totensor,
    ])

    val_transform = A.Compose([
        _norm,
        _totensor,
    ])

    # Datasets and dataloaders
    train_dataset = PetSegmentationDataset(args.data_root, args.split_dir, "train", transform=train_transform)
    val_dataset = PetSegmentationDataset(args.data_root, args.split_dir, "val", transform=val_transform)

    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True, num_workers=4, drop_last=True)
    val_loader = DataLoader(val_dataset, batch_size=1, shuffle=False, num_workers=4)

    # Model, loss, optimizer
    if args.model == "resnet34_unet":
        model = ResNet34UNet(in_channels=3, out_channels=2)
    else:
        model = UNet(in_channels=3, out_channels=2)
    model.apply(init_weights)
    model.to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=args.weight_decay)
    warmup_epochs = min(args.warmup_epochs, args.epochs)
    if warmup_epochs > 0:
        warmup = torch.optim.lr_scheduler.LinearLR(optimizer, start_factor=0.1, total_iters=warmup_epochs)
        cosine = torch.optim.lr_scheduler.CosineAnnealingLR(
            optimizer,
            T_max=max(1, args.epochs - warmup_epochs),
        )
        scheduler = torch.optim.lr_scheduler.SequentialLR(
            optimizer,
            schedulers=[warmup, cosine],
            milestones=[warmup_epochs],
        )
    else:
        scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=args.epochs)

    # Print out the config
    num_params = sum(p.numel() for p in model.parameters())
    print(f"Model parameters: {num_params:,}")
    print(f"Training samples: {len(train_dataset)} | Validation samples: {len(val_dataset)}")
    print(f"Crop size: {args.crop_size} | Batch size: {args.batch_size} | LR: {args.lr}")
    print(f"Epochs: {args.epochs} | Optimizer: AdamW(weight_decay={args.weight_decay})")
    print(f"Scheduler: {warmup_epochs}-epoch warmup + CosineAnnealingLR")
    print(f"Loss: CE + per-sample dice | Conv init: He normal (std=sqrt(2/N), N=k*k*in_ch); BN: default")
    print("-" * 70)

    # Best validation dice for saving best model
    best_dice = 0.0
    train_start = time.time()

    # Training loop
    for epoch in range(args.epochs):
        # Training
        model.train()
        train_loss = 0.0
        train_progress = tqdm(train_loader, colour="cyan")
        for images, masks in train_progress:
            images = images.to(device) # img - B, C, H, W
            masks = masks.to(device).long() # label - B, H, W (CE expects int64)

            optimizer.zero_grad()
            outputs = model(images) # B, 1, H, W
            # Center-crop masks to match output size (unpadded convs shrink spatial dims)
            masks = TF.center_crop(masks, [outputs.shape[2], outputs.shape[3]])

            loss = criterion(outputs, masks) + dice_loss(outputs, masks)

            loss.backward()
            optimizer.step()
            train_progress.set_description("TRAIN | Epoch: {}/{}| Loss: {:0.4f}".format(epoch, args.epochs, loss))

            train_loss += loss.item() * images.size(0)

        train_loss /= len(train_dataset)
        print("TRAIN | Loss: {:0.4f}".format(train_loss))

        # Validation
        model.eval()
        total_dice = 0.0
        num_samples = 0

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

        dice = total_dice / num_samples
        scheduler.step()

        lr = optimizer.param_groups[0]['lr']
        print("VAL  | Dice: {:0.5f} | LR: {:.2e}".format(dice, lr))
        print("-" * 70)

        # Create checkpoint
        checkpoint = {
            "model_state_dict": model.state_dict(),
            "epoch": epoch, 
            "optimizer_state_dict": optimizer.state_dict(),
            "dice": dice
        }

        # Save last checkpoint
        torch.save(checkpoint, os.path.join(args.save_dir, f"{args.model}_last.pth"))

        if dice > best_dice:
            best_dice = dice
            os.makedirs(args.save_dir, exist_ok=True)
            torch.save(model.state_dict(), os.path.join(args.save_dir, f"{args.model}_best.pth"))
            print(f"  -> Best model saved (Dice: {best_dice:.5f})")

    print("-" * 70)
    print(f"Training complete | Best Val Dice: {best_dice:.4f} | Total time: {time.time() - train_start:.0f}s")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, choices=["unet", "resnet34_unet"], required=True)
    parser.add_argument("--data_root", type=str, default="dataset/oxford-iiit-pet")
    parser.add_argument("--split_dir", type=str, default="dataset/taica")
    parser.add_argument("--save_dir", type=str, default="saved_models")
    parser.add_argument("--epochs", type=int, default=100)
    parser.add_argument("--batch_size", type=int, default=8)
    parser.add_argument("--lr", type=float, default=3e-4)
    parser.add_argument("--weight_decay", type=float, default=1e-4)
    parser.add_argument("--warmup_epochs", type=int, default=5)
    parser.add_argument("--crop_size", type=int, default=256)
    args = parser.parse_args()

    train(args)
