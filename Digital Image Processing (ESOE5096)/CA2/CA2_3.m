% Read image
img = imread('lena.bmp');
img = im2double(img);

% Fourier transform and shift
imgfft = fft2(img);
imgshift = fftshift(imgfft);
imgspectrum = log(1 + abs(imgshift));

% Get image size
[M, N] = size(img);

% Create Gaussian filters with sigma = 10 and 30
sigma_values = [10, 30];

for k = 1:length(sigma_values)
    sigma = sigma_values(k);

    % Create Gaussian filter (frequency domain)
    % fspecial creates a 2D Gaussian in spatial domain, but we can use it here for frequency weighting
    H = fspecial('gaussian', [M, N], sigma);
    H = H / max(H(:)); % normalize to range [0,1]
    H = 1 - H; % high-pass

    % Apply the Gaussian low-pass filter
    imgfiltered_shift = imgshift .* H;

    % Compute log spectrum of filtered FFT
    imgspectrum_filtered = log(1 + abs(imgfiltered_shift));

    % Inverse transform to get filtered image
    imgfiltered = real(ifft2(ifftshift(imgfiltered_shift)));

    % Display results
    figure('Name', sprintf('Gaussian LPF (sigma = %d)', sigma));

    subplot(2, 2, 1);
    imshow(img, []);
    title('(a) Original Image');

    subplot(2, 2, 2);
    imshow(imgspectrum, []);
    title('(b) Spectrum');

    subplot(2, 2, 3);
    imshow(imgspectrum_filtered, []);
    title(sprintf('(c) Spectrum after LP (σ = %d)', sigma));

    subplot(2, 2, 4);
    imshow(imgfiltered, []);
    title(sprintf('(d) LP Filtered Image (σ = %d)', sigma));
end
