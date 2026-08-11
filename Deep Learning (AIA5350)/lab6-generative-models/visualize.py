import argparse
from pathlib import Path

import torch
from PIL import Image
from torchvision import transforms
from torchvision.utils import make_grid, save_image

from src.dataset import encode_labels, load_object_mapping
from src.diffusion import DDPM, denormalize
from src.model import ConditionalUNet


REQUIRED_DENOISING_LABELS = ["red sphere", "cyan cylinder", "cyan cube"]


def parse_args():
    parser = argparse.ArgumentParser(description="Create Lab 6 visualization grids.")
    parser.add_argument("--checkpoint", required=True)
    parser.add_argument("--test-image-dir", default="outputs/test")
    parser.add_argument("--new-test-image-dir", default="outputs/new_test")
    parser.add_argument("--objects-json", default="objects.json")
    parser.add_argument("--output-dir", default="outputs/grids")

    parser.add_argument("--timesteps", type=int, default=None)
    parser.add_argument("--image-size", type=int, default=None)
    parser.add_argument("--base-channels", type=int, default=None)
    parser.add_argument("--process-steps", type=int, default=8)
    parser.add_argument("--seed", type=int, default=42)
    return parser.parse_args()


def load_generated_images(image_dir, count=32):
    image_dir = Path(image_dir)
    transform = transforms.ToTensor()
    images = []
    for index in range(count):
        image_path = image_dir / f"{index}.png"
        image = Image.open(image_path).convert("RGB")
        images.append(transform(image))
    return torch.stack(images)


def save_generated_grid(image_dir, output_path):
    images = load_generated_images(image_dir)
    grid = make_grid(images, nrow=8)
    save_image(grid, output_path)


def load_ddpm(args, device):
    checkpoint = torch.load(args.checkpoint, map_location=device)
    train_args = checkpoint.get("args", {})

    image_size = args.image_size or train_args.get("image_size", 64)
    timesteps = args.timesteps or train_args.get("timesteps", 1000)
    base_channels = args.base_channels or train_args.get("base_channels", 64)

    model = ConditionalUNet(base_channels=base_channels)
    ddpm = DDPM(model=model, image_size=image_size, timesteps=timesteps).to(device)
    ddpm.model.load_state_dict(checkpoint["model"])
    ddpm.eval()
    return ddpm


@torch.no_grad()
def save_denoising_grid(args, output_path, device):
    object_to_idx = load_object_mapping(args.objects_json)
    label = encode_labels(REQUIRED_DENOISING_LABELS, object_to_idx)
    label = label.unsqueeze(0).to(device)

    ddpm = load_ddpm(args, device)
    _, process = ddpm.sample(
        label,
        return_process=True,
        process_steps=args.process_steps,
    )

    images = torch.cat(process, dim=0)
    images = denormalize(images)
    grid = make_grid(images, nrow=args.process_steps)
    save_image(grid, output_path)


def main():
    args = parse_args()
    torch.manual_seed(args.seed)

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    save_generated_grid(args.test_image_dir, output_dir / "test_grid.png")
    save_generated_grid(args.new_test_image_dir, output_dir / "new_test_grid.png")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    save_denoising_grid(args, output_dir / "denoising_process.png", device)

    print(f"saved grids to {output_dir}")


if __name__ == "__main__":
    main()
