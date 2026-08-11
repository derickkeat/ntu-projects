import torch
import torch.nn as nn
import torchvision.transforms.functional as TF


class BasicBlock(nn.Module):
    def __init__(self, in_channels, out_channels, stride=1):
        super().__init__()
        self.conv1 = nn.Conv2d(in_channels, out_channels, 3, stride=stride, padding=1, bias=False)
        self.bn1 = nn.BatchNorm2d(out_channels)
        self.relu = nn.ReLU(inplace=True)
        self.conv2 = nn.Conv2d(out_channels, out_channels, 3, stride=1, padding=1, bias=False)
        self.bn2 = nn.BatchNorm2d(out_channels)

        # Shortcut connection when dimensions change
        if stride != 1 or in_channels != out_channels:
            self.shortcut = nn.Sequential(
                nn.Conv2d(in_channels, out_channels, 1, stride=stride, bias=False),
                nn.BatchNorm2d(out_channels),
            )
        else:
            self.shortcut = nn.Identity()

    def forward(self, x):
        out = self.relu(self.bn1(self.conv1(x)))
        out = self.bn2(self.conv2(out))
        out = self.relu(out + self.shortcut(x))
        return out


class ResNet34Encoder(nn.Module):
    def __init__(self, in_channels=3):
        super().__init__()

        # Initial conv: in_channels → 64, /2
        self.conv1 = nn.Conv2d(in_channels, 64, 7, stride=2, padding=3, bias=False)
        self.bn1 = nn.BatchNorm2d(64)
        self.relu = nn.ReLU(inplace=True)
        self.maxpool = nn.MaxPool2d(3, stride=2, padding=1)  # /4

        # ResNet34 block config: [3, 4, 6, 3]
        self.layer1 = self._make_layer(64, 64, 3, stride=1)    # 64 ch,  /4
        self.layer2 = self._make_layer(64, 128, 4, stride=2)   # 128 ch, /8
        self.layer3 = self._make_layer(128, 256, 6, stride=2)  # 256 ch, /16
        self.layer4 = self._make_layer(256, 512, 3, stride=2)  # 512 ch, /32

    def _make_layer(self, in_channels, out_channels, num_blocks, stride):
        layers = [BasicBlock(in_channels, out_channels, stride)]
        for _ in range(1, num_blocks):
            layers.append(BasicBlock(out_channels, out_channels, stride=1))
        return nn.Sequential(*layers)

    def forward(self, x):
        e1 = self.relu(self.bn1(self.conv1(x)))  # (64, 128, 128)
        e2 = self.layer1(self.maxpool(e1))        # (64, 64, 64)
        e3 = self.layer2(e2)                      # (128, 32, 32)
        e4 = self.layer3(e3)                      # (256, 16, 16)
        e5 = self.layer4(e4)                      # (512, 8, 8)
        return e1, e2, e3, e4, e5


class DoubleConv(nn.Module):
    def __init__(self, in_channels, out_channels):
        super().__init__()
        self.conv = nn.Sequential(
            nn.Conv2d(in_channels, out_channels, 3, padding=1, bias=False),
            nn.BatchNorm2d(out_channels),
            nn.ReLU(inplace=True),
            nn.Conv2d(out_channels, out_channels, 3, padding=1, bias=False),
            nn.BatchNorm2d(out_channels),
            nn.ReLU(inplace=True),
        )

    def forward(self, x):
        return self.conv(x)


class ResNet34UNet(nn.Module):
    def __init__(self, in_channels=3, out_channels=2):
        super().__init__()

        # Encoder
        self.encoder = ResNet34Encoder(in_channels)

        # Decoder
        self.up5 = nn.ConvTranspose2d(512, 256, 2, stride=2)
        self.dec5 = DoubleConv(512, 256)

        self.up4 = nn.ConvTranspose2d(256, 128, 2, stride=2)
        self.dec4 = DoubleConv(256, 128)

        self.up3 = nn.ConvTranspose2d(128, 64, 2, stride=2)
        self.dec3 = DoubleConv(128, 64)

        self.up2 = nn.ConvTranspose2d(64, 64, 2, stride=2)
        self.dec2 = DoubleConv(128, 64)

        self.up1 = nn.ConvTranspose2d(64, 32, 2, stride=2)
        self.dec1 = DoubleConv(32, 32)

        self.final = nn.Conv2d(32, out_channels, 1)

    def _crop_and_cat(self, upsampled, skip):
        """Crop upsampled tensor to match skip connection size, then concatenate."""
        h, w = skip.shape[2], skip.shape[3]
        upsampled = TF.center_crop(upsampled, [h, w])
        return torch.cat([upsampled, skip], dim=1)

    def forward(self, x):
        # Encoder
        e1, e2, e3, e4, e5 = self.encoder(x)

        # Decoder with skip connections
        d5 = self.dec5(self._crop_and_cat(self.up5(e5), e4))
        d4 = self.dec4(self._crop_and_cat(self.up4(d5), e3))
        d3 = self.dec3(self._crop_and_cat(self.up3(d4), e2))
        d2 = self.dec2(self._crop_and_cat(self.up2(d3), e1))
        d1 = self.dec1(self.up1(d2))

        return self.final(d1)
