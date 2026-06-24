img = im2double(imread('hurricane-katrina.tif'));
levels = [1 2 3 4];
wname = 'bior6.8';

figure;
for i = 1:length(levels)
    level = levels(i);

    % Wavelet transform
    [cm, sm] = wavefast(img, 4, wname);

    % Zeroing detail coefficients up to 'level'
    [nc, g8] = wavezero(cm, sm, level, wname);
    g8 = im2double(g8);

    % (a) Show smoothed image
    subplot(4,4,(i-1)*4+1);
    imshow(g8, []);
    title(sprintf('Level %d Smoothed', level));

    % (b) Difference image
    diff_img = img - g8;
    subplot(4,4,(i-1)*4+2);
    imshow(diff_img, []);
    title(sprintf('Level %d Difference', level));

end

%%
% ==============================================================
% Repeat with Gaussian noise added
% ==============================================================

noisy = imnoise(img, 'gaussian', 0, 0.15);

PSNR_values = zeros(1,length(levels));

figure;
for i = 1:length(levels)
    level = levels(i);

    % Wavelet transform on noisy image
    [cm, sm] = wavefast(noisy, 4, wname);

    % Zeroing
    [nc, g8n] = wavezero(cm, sm, level, wname);
    g8n = im2double(g8n);

    % Show smoothed noisy result
    subplot(4,4,(i-1)*4+1);
    imshow(g8n, []);
    title(sprintf('Noisy Level %d Smoothed', level));

    % Difference
    diff_img = noisy - g8n;
    subplot(4,4,(i-1)*4+2);
    imshow(diff_img, []);
    title(sprintf('Noisy Level %d Difference', level));

    % Compute PSNR w.r.t. ORIGINAL CLEAN IMAGE
    PSNR_values(i) = psnr(g8n, img);
end

%%
% Report the best level
[bestPSNR, bestLevelIdx] = max(PSNR_values);
bestLevel = levels(bestLevelIdx);

fprintf('Best level = %d with PSNR = %.4f dB\n', bestLevel, bestPSNR);
