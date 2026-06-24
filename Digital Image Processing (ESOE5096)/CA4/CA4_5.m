%% Load image
img = im2double(imread('barbara.tif'));   % ensure double

%% Four-scale forward wavelet transform (Antonini–Barlaud–Mathieu–Daubechies)
[cm, sm] = wavefast(img, 4, 'jpeg9.7');

%% (a) Display wavelet coefficients
figure;
wavedisplay(cm, sm, 8);
title('Wavelet Coefficients (4-scale JPEG 9.7)');

%% (a) Progressive reconstruction for 5 resolutions
cm_curr = cm;
sm_curr = sm;

figure;
for k = 1:5
    % Extract approximation image at current level
    yi = wavecopy('a', cm_curr, sm_curr);

    subplot(2,3,k);
    imshow(mat2gray(yi));
    title(sprintf('Reconstruction Level %d', k));

    % Go one-scale back (except after final level)
    if k < 5
        [cm_curr, sm_curr] = waveback(cm_curr, sm_curr, 'jpeg9.7', 1);
    end
end

%% (b) Final reconstruction
final_recon = yi;  % yi from last iteration above

% Difference image
diff_img = img - final_recon;

figure;
imshow(mat2gray(diff_img));
title('Difference Image (Original - Final Reconstruction)');

%% Examine max absolute error
maxError = max(abs(diff_img(:)));
disp(['Max absolute error = ' num2str(maxError)]);
