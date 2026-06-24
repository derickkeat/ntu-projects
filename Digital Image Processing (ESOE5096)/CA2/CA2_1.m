[x, y] = meshgrid(-128:127, -128:127); 
z = sqrt(x.^2 + y.^2); 
img = (z < 20);

imgfft = fft2(img);

imgshift = fftshift(imgfft);

realpart = real(imgshift);

impart = imag(imgshift);

magnitudespectrum = log(1 + abs(imgshift));

figure;
subplot(2, 2, 1);
imshow(img, []);
title('Original Image');

subplot(2, 2, 2);
imshow(realpart, []);
title("Real Part");

subplot(2, 2, 3);
imshow(impart, []);
title("Imaginary Part");

subplot(2, 2, 4);
imshow(magnitudespectrum, []);
title("Spectrum")