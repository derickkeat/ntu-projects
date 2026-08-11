import argparse
from pathlib import Path

import torch
from torch.optim import AdamW
from torch.utils.data import DataLoader
from tqdm import tqdm

from evaluator import evaluation_model
from src.dataset import ICLEVRConditionDataset, ICLEVRTrainDataset
from src.diffusion import DDPM
from src.model import ConditionalUNet


def parse_args():
    parser = argparse.ArgumentParser(description="Train conditional DDPM on i-CLEVR.")
    parser.add_argument("--image-dir", default="iclevr")
    parser.add_argument("--train-json", default="train.json")
    parser.add_argument("--objects-json", default="objects.json")
    parser.add_argument("--save-dir", default="checkpoints")
    parser.add_argument("--resume", default=None)
    parser.add_argument("--val-json", default=None)

    parser.add_argument("--epochs", type=int, default=100)
    parser.add_argument("--batch-size", type=int, default=64)
    parser.add_argument("--lr", type=float, default=2e-4)
    parser.add_argument("--weight-decay", type=float, default=1e-4)
    parser.add_argument("--num-workers", type=int, default=4)
    parser.add_argument("--timesteps", type=int, default=1000)
    parser.add_argument("--image-size", type=int, default=64)
    parser.add_argument("--base-channels", type=int, default=64)
    parser.add_argument("--save-every", type=int, default=10)
    parser.add_argument("--eval-every", type=int, default=10)
    parser.add_argument("--eval-batch-size", type=int, default=32)
    parser.add_argument("--classifier-guidance-scale", type=float, default=0.0)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--amp", action="store_true")
    return parser.parse_args()


def save_checkpoint(path, ddpm, optimizer, epoch, global_step, args, best_score=-1.0):
    checkpoint = {
        "model": ddpm.model.state_dict(),
        "optimizer": optimizer.state_dict(),
        "epoch": epoch,
        "global_step": global_step,
        "best_score": best_score,
        "args": vars(args),
    }
    torch.save(checkpoint, path)


def load_checkpoint(path, ddpm, optimizer, device):
    checkpoint = torch.load(path, map_location=device)
    ddpm.model.load_state_dict(checkpoint["model"])
    optimizer.load_state_dict(checkpoint["optimizer"])
    return (
        checkpoint["epoch"] + 1,
        checkpoint.get("global_step", 0),
        checkpoint.get("best_score", -1.0),
    )


@torch.no_grad()
def evaluate_generated(ddpm, evaluator, dataset, batch_size, guidance_scale, device):
    ddpm.eval()
    total_correct = 0.0
    total_labels = 0

    for start in tqdm(range(0, len(dataset), batch_size), desc="Evaluating"):
        end = min(start + batch_size, len(dataset))
        labels = torch.stack([dataset[i][0] for i in range(start, end)]).to(device)
        generated = ddpm.sample(
            labels,
            classifier_guidance_scale=guidance_scale,
        ).clamp(-1, 1)

        batch_acc = evaluator.eval(generated, labels)
        batch_labels = labels.sum().item()
        total_correct += batch_acc * batch_labels
        total_labels += batch_labels

    ddpm.train()
    return total_correct / total_labels


def main():
    args = parse_args()
    torch.manual_seed(args.seed)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    save_dir = Path(args.save_dir)
    save_dir.mkdir(parents=True, exist_ok=True)

    dataset = ICLEVRTrainDataset(
        image_dir=args.image_dir,
        train_json=args.train_json,
        objects_json=args.objects_json,
    )
    dataloader = DataLoader(
        dataset,
        batch_size=args.batch_size,
        shuffle=True,
        num_workers=args.num_workers,
        pin_memory=device.type == "cuda",
        drop_last=True,
    )

    model = ConditionalUNet(base_channels=args.base_channels)
    ddpm = DDPM(
        model=model,
        image_size=args.image_size,
        timesteps=args.timesteps,
    ).to(device)

    optimizer = AdamW(
        ddpm.model.parameters(),
        lr=args.lr,
        weight_decay=args.weight_decay,
    )
    scaler = torch.cuda.amp.GradScaler(enabled=args.amp and device.type == "cuda")

    start_epoch = 1
    global_step = 0
    best_score = -1.0
    if args.resume:
        start_epoch, global_step, best_score = load_checkpoint(
            args.resume,
            ddpm,
            optimizer,
            device,
        )

    val_dataset = None
    evaluator = None
    if args.val_json:
        if not torch.cuda.is_available():
            raise RuntimeError("Training-time evaluation requires CUDA.")
        val_dataset = ICLEVRConditionDataset(args.val_json, args.objects_json)
        evaluator = evaluation_model()
        if args.classifier_guidance_scale > 0:
            ddpm.classifier = evaluator
            for parameter in ddpm.classifier.resnet18.parameters():
                parameter.requires_grad_(False)

    for epoch in range(start_epoch, args.epochs + 1):
        ddpm.train()
        running_loss = 0.0
        progress = tqdm(dataloader, desc=f"Epoch {epoch}/{args.epochs}")

        for images, labels in progress:
            images = images.to(device, non_blocking=True)
            labels = labels.to(device, non_blocking=True)

            optimizer.zero_grad(set_to_none=True)

            with torch.cuda.amp.autocast(enabled=args.amp and device.type == "cuda"):
                loss = ddpm.training_loss(images, labels)

            scaler.scale(loss).backward()
            scaler.step(optimizer)
            scaler.update()

            global_step += 1
            running_loss += loss.item()
            progress.set_postfix(loss=f"{loss.item():.4f}")

        avg_loss = running_loss / len(dataloader)
        print(f"epoch={epoch} avg_loss={avg_loss:.6f}")

        latest_path = save_dir / "latest.pth"
        save_checkpoint(
            latest_path,
            ddpm,
            optimizer,
            epoch,
            global_step,
            args,
            best_score=best_score,
        )

        if epoch % args.save_every == 0 or epoch == args.epochs:
            epoch_path = save_dir / f"ddpm_epoch_{epoch:03d}.pth"
            save_checkpoint(
                epoch_path,
                ddpm,
                optimizer,
                epoch,
                global_step,
                args,
                best_score=best_score,
            )

        should_eval = (
            val_dataset is not None
            and (epoch % args.eval_every == 0 or epoch == args.epochs)
        )
        if should_eval:
            score = evaluate_generated(
                ddpm,
                evaluator,
                val_dataset,
                args.eval_batch_size,
                args.classifier_guidance_scale,
                device,
            )
            print(f"epoch={epoch} eval_accuracy={score:.6f} best={best_score:.6f}")

            if score > best_score:
                best_score = score
                best_path = save_dir / "best.pth"
                save_checkpoint(
                    best_path,
                    ddpm,
                    optimizer,
                    epoch,
                    global_step,
                    args,
                    best_score=best_score,
                )
                print(f"saved new best checkpoint to {best_path}")


if __name__ == "__main__":
    main()
