img = imread("zoneplate.tif");

[cm, sm] = wavefast(img, 2, 'haar');

%% (a) Default scale
figure;
wavedisplay(cm, sm);
title("Wavelet Coefficients – Default");

%% (b) scale = 8
figure;
scale = 8;
wavedisplay(cm, sm, scale);
title("Wavelet Coefficients – scale = 8");

%% (c) scale = -8 (absolute value scaling)
figure;
scale = -8;
wavedisplay(cm, sm, scale);
title("Wavelet Coefficients – scale = -8 (abs scale)");
