import argparse
from pathlib import Path

import torch
from torchvision.utils import save_image
from tqdm import tqdm

from src.dataset import ICLEVRConditionDataset
from src.diffusion import DDPM, denormalize
from src.model import ConditionalUNet


def parse_args():
    parser = argparse.ArgumentParser(description="Generate i-CLEVR images with DDPM.")
    parser.add_argument("--checkpoint", required=True)
    parser.add_argument("--condition-json", required=True)
    parser.add_argument("--objects-json", default="objects.json")
    parser.add_argument("--output-dir", required=True)

    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--timesteps", type=int, default=None)
    parser.add_argument("--image-size", type=int, default=None)
    parser.add_argument("--base-channels", type=int, default=None)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--classifier-guidance-scale", type=float, default=0.0)
    return parser.parse_args()


def load_model_from_checkpoint(args, device):
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
def generate_once(ddpm, dataset, args, device, output_dir):
    image_index = 0
    for start in tqdm(range(0, len(dataset), args.batch_size), desc="Generating"):
        end = min(start + args.batch_size, len(dataset))
        labels = torch.stack([dataset[i][0] for i in range(start, end)]).to(device)

        generated = ddpm.sample(
            labels,
            classifier_guidance_scale=args.classifier_guidance_scale,
        )
        generated = denormalize(generated.detach().cpu())

        for image in generated:
            save_image(image, output_dir / f"{image_index}.png")
            image_index += 1

    return image_index


def main():
    args = parse_args()
    torch.manual_seed(args.seed)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    dataset = ICLEVRConditionDataset(
        condition_json=args.condition_json,
        objects_json=args.objects_json,
    )
    ddpm = load_model_from_checkpoint(args, device)

    image_index = generate_once(ddpm, dataset, args, device, output_dir)

    print(f"saved {image_index} images to {output_dir}")


if __name__ == "__main__":
    main()
