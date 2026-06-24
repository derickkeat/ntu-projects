img = imread('test_pattern.tif');

%% (a) 4th order Symlets wavelet transform
[cm, sm] = wavefast(img, 1, 'sym4');
figure;
wavedisplay(cm, sm, -6);
title("4th order Symlets wavelet transform");

%% (b) wavecut
[nc, ym] = wavecut('a', cm, sm);
figure;
wavedisplay(nc, sm, -6);
title("WAVECUT zero coefficient");

%% (c) waveback
out = waveback(nc, sm, 'sym4');
outimg = mat2gray(out);
figure;
imshow(outimg);
title("Inverse FWT");
