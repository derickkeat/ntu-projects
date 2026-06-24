imgcam = imread("cameraman.tif");
imgcamfft = fft2(imgcam);
imgcamshift = fftshift(imgcamfft);

imgcamspectrum = log(1 + abs(imgcamshift));

[x, y] = meshgrid(-128:127, -128:127); 
z = sqrt(x.^2 + y.^2); 
cir = (z > 30);

cirfft = fft2(img);
cirshift = fftshift(imgfft);
imgcamlp = imgcamshift .* cirshift;
imgcamlpspectrum = log(1 + abs(imgcamlp));

imgcamlpspatial = ifft2(imgcamlp);

figure;
subplot(2, 2, 1);
imshow(imgcam, []);
title('Original Image');

subplot(2, 2, 2);
imshow(imgcamspectrum, []);
title("Spectrum");

subplot(2, 2, 3);
imshow(imgcamlpspectrum, []);
title("Spectrum after LP");

subplot(2, 2, 4);
imshow(imgcamlpspatial, []);
title("LP Filtered Image");