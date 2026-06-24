function out = midpoint(img, k)
% img: input image (double)
% k: window size (k x k)
    pad = floor(k/2);
    padded = padarray(img, [pad pad], 'symmetric');

    [M, N] = size(img);
    out = zeros(M, N);

    for i = 1:M
        for j = 1:N
            window = padded(i:i+k-1, j:j+k-1);
            min_val = min(window(:));
            max_val = max(window(:));
            out(i,j) = (min_val + max_val) / 2;
        end
    end
end