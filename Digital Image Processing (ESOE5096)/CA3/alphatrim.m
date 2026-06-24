function out = alphatrim(img, k, d)
% img: input image (double)
% k: window size (k x k)
% d: total number of pixels to trim (must be even)

assert(mod(d,2)==0, 'd must be even');

pad = floor(k/2);

% Symmetric padding (same as your original)
img_pad = padarray(img, [pad pad], 'symmetric');

% Convert sliding windows into columns
patches = im2col(img_pad, [k k], 'sliding');   % (k^2) x (M*N)

% Sort each column (each window)
patches = sort(patches, 1);

% Trim smallest and largest values
trim = d/2;
patches = patches(trim+1:end-trim, :);

% Compute mean of trimmed values
out = mean(patches, 1);

% Reshape back to image
out = reshape(out, size(img));
end