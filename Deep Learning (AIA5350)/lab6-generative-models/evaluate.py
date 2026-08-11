import argparse
from pathlib import Path

import torch
from PIL import Image
from torch.utils.data import DataLoader, Dataset
from torchvision import transforms

from evaluator import evaluation_model
from src.dataset import ICLEVRConditionDataset


class GeneratedImageDataset(Dataset):
    def __init__(self, image_dir, condition_json, objects_json="objects.json"):
        self.image_dir = Path(image_dir)
        self.conditions = ICLEVRConditionDataset(condition_json, objects_json)
        self.transform = transforms.Compose(
            [
                transforms.Resize((64, 64)),
                transforms.ToTensor(),
                transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5)),
            ]
        )

    def __len__(self):
        return len(self.conditions)

    def __getitem__(self, index):
        image_path = self.image_dir / f"{index}.png"
        image = Image.open(image_path).convert("RGB")
        image = self.transform(image)
        label, _ = self.conditions[index]
        return image, label


def parse_args():
    parser = argparse.ArgumentParser(description="Evaluate generated i-CLEVR images.")
    parser.add_argument("--image-dir", required=True)
    parser.add_argument("--condition-json", required=True)
    parser.add_argument("--objects-json", default="objects.json")
    parser.add_argument("--batch-size", type=int, default=32)
    return parser.parse_args()


def main():
    args = parse_args()

    if not torch.cuda.is_available():
        raise RuntimeError(
            "The provided evaluator.py moves the model to CUDA. "
            "Run this script on a CUDA machine."
        )

    dataset = GeneratedImageDataset(
        image_dir=args.image_dir,
        condition_json=args.condition_json,
        objects_json=args.objects_json,
    )
    dataloader = DataLoader(dataset, batch_size=args.batch_size, shuffle=False)
    evaluator = evaluation_model()

    total_correct = 0.0
    total_labels = 0

    for images, labels in dataloader:
        images = images.cuda(non_blocking=True)
        labels = labels.cuda(non_blocking=True)

        batch_acc = evaluator.eval(images, labels)
        batch_labels = labels.sum().item()
        total_correct += batch_acc * batch_labels
        total_labels += batch_labels

    accuracy = total_correct / total_labels
    print(f"accuracy: {accuracy:.6f}")


if __name__ == "__main__":
    main()
