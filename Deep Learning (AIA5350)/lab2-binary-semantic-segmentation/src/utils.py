import random
import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from PIL import Image


def init_weights(m):
    """He initialization: Gaussian(std=sqrt(2/N)) for conv layers."""
    if isinstance(m, (nn.Conv2d, nn.ConvTranspose2d)):
        n = m.kernel_size[0] * m.kernel_size[1] * m.in_channels
        nn.init.normal_(m.weight, mean=0, std=(2.0 / n) ** 0.5)
        if m.bias is not None:
            nn.init.zeros_(m.bias)


def pad_for_model(image, factor=16):
    """
    Pad image so H and W are divisible by `factor`.
    Returns (padded_image, (orig_h, orig_w), (pad_top, pad_left)).
    """
    _, _, h, w = image.shape
    padded_h = h + (factor - h % factor) % factor
    padded_w = w + (factor - w % factor) % factor
    pad_h = padded_h - h
    pad_w = padded_w - w
    pad_top, pad_bottom = pad_h // 2, pad_h - pad_h // 2
    pad_left, pad_right = pad_w // 2, pad_w - pad_w // 2
    padded = F.pad(image, (pad_left, pad_right, pad_top, pad_bottom), mode="reflect")
    return padded, (h, w), (pad_top, pad_left)


def dice_score(pred, target, smooth=1e-6):
    """Dice score: 2*TP / (|pred_fg| + |target_fg|)."""
    tp = ((pred == 1) & (target == 1)).float().sum()
    pred_fg = (pred == 1).float().sum()
    target_fg = (target == 1).float().sum()
    return (2 * tp + smooth) / (pred_fg + target_fg + smooth)


def dice_loss(logits, target, smooth=1e-6):
    """Differentiable dice loss for training. Returns 1 - soft_dice."""
    probs = torch.softmax(logits, dim=1)[:, 1]  # foreground probability
    target_f = (target == 1).float()
    inter = (probs * target_f).sum(dim=(1, 2))
    denom = probs.sum(dim=(1, 2)) + target_f.sum(dim=(1, 2))
    return 1 - ((2 * inter + smooth) / (denom + smooth)).mean()


def smart_crop(image, mask, crop_size=524):
    """
    Subject-aware random crop: biased toward foreground (pet) pixels.

    Args:
        image: PIL Image (RGB)
        mask: np.ndarray (H, W) with values {1=pet, 0=background}
        crop_size: output crop size

    Returns:
        (PIL Image, np.ndarray) — cropped image and mask, both crop_size x crop_size
    """
    cs = crop_size
    img_arr = np.array(image)
    h, w = mask.shape

    # Pad if smaller than crop_size
    if h < cs or w < cs:
        pad_h = max(cs - h, 0)
        pad_w = max(cs - w, 0)
        img_arr = np.pad(img_arr, ((0, pad_h), (0, pad_w), (0, 0)), mode="constant", constant_values=0)
        mask = np.pad(mask, ((0, pad_h), (0, pad_w)), mode="constant", constant_values=0)
        h, w = mask.shape

    # Find foreground pixels (pet = 1)
    fg_ys, fg_xs = np.where(mask == 1)

    if len(fg_ys) > 0:
        # Pick a random pet pixel as the crop center anchor
        anchor_idx = random.randint(0, len(fg_ys) - 1)
        cy, cx = fg_ys[anchor_idx], fg_xs[anchor_idx]
        # Add random jitter so the pet isn't always dead-center in the crop
        cy += random.randint(-128, 128)
        cx += random.randint(-128, 128)
    else:
        # No pet pixels found — fall back to a random crop center
        cy = random.randint(cs // 2, h - cs // 2)
        cx = random.randint(cs // 2, w - cs // 2)

    # Convert anchor to top-left corner and clamp
    y0 = max(0, min(cy - cs // 2, h - cs))
    x0 = max(0, min(cx - cs // 2, w - cs))

    img_crop = img_arr[y0:y0 + cs, x0:x0 + cs]
    mask_crop = mask[y0:y0 + cs, x0:x0 + cs]

    return Image.fromarray(img_crop), mask_crop


def sliding_window_inference(model, image_tensor, crop_size=512, stride=256, device=None):
    """
    Run sliding window inference over a full-resolution image.

    Args:
        model: trained segmentation model
        image_tensor: (3, H, W) normalized image tensor
        crop_size: size of each sliding window patch
        stride: step size between patches
        device: computation device

    Returns:
        (H, W) predicted class map with values {0, 1}
    """
    model.eval()
    if device is None:
        device = image_tensor.device
    _, h, w = image_tensor.shape
    num_classes = 2

    # Compute output size reduction from unpadded convolutions
    with torch.no_grad():
        dummy = torch.zeros(1, 3, crop_size, crop_size, device=device)
        dummy_out = model(dummy)
        out_size = dummy_out.shape[2]
    margin = (crop_size - out_size) // 2

    # Pad image if smaller than crop_size
    pad_h = max(crop_size - h, 0)
    pad_w = max(crop_size - w, 0)
    padded_h, padded_w = h + pad_h, w + pad_w
    if pad_h > 0 or pad_w > 0:
        # reflect requires pad < dimension; fall back to replicate if too small
        pad_mode = "reflect" if pad_h < h and pad_w < w else "replicate"
        image_tensor = F.pad(image_tensor, (0, pad_w, 0, pad_h), mode=pad_mode)

    # Accumulation tensors
    sum_preds = torch.zeros(num_classes, padded_h, padded_w, device=device)
    count = torch.zeros(1, padded_h, padded_w, device=device)

    # Generate patch positions ensuring full coverage
    y_positions = list(range(0, padded_h - crop_size + 1, stride))
    x_positions = list(range(0, padded_w - crop_size + 1, stride))

    # Ensure right/bottom edges are covered
    if len(y_positions) == 0 or y_positions[-1] + crop_size < padded_h:
        y_positions.append(max(0, padded_h - crop_size))
    if len(x_positions) == 0 or x_positions[-1] + crop_size < padded_w:
        x_positions.append(max(0, padded_w - crop_size))

    y_positions = sorted(set(y_positions))
    x_positions = sorted(set(x_positions))

    with torch.no_grad():
        for y0 in y_positions:
            for x0 in x_positions:
                patch = image_tensor[:, y0:y0 + crop_size, x0:x0 + crop_size].unsqueeze(0).to(device)
                output = model(patch)
                probs = F.softmax(output, dim=1).squeeze(0)

                # Place output in the center region (accounting for margin)
                oy = y0 + margin
                ox = x0 + margin
                sum_preds[:, oy:oy + out_size, ox:ox + out_size] += probs
                count[:, oy:oy + out_size, ox:ox + out_size] += 1

    # Average predictions
    count = count.clamp(min=1)
    avg_preds = sum_preds / count

    # Crop back to original size
    avg_preds = avg_preds[:, :h, :w]

    return avg_preds.argmax(dim=0)  # (H, W)
