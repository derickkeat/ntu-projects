function out = outlier(img, D)
% OUTLIER  Outlier noise filtering based on neighborhood mean
%   img : input noisy grayscale image
%   D   : threshold value
%   out : filtered output image

    [M, N] = size(img);
    out = img;

    % Pad image to handle borders
    padded = padarray(img, [1 1], 'symmetric');

    for i = 1:M
        for j = 1:N
            % Extract 3x3 window
            window = padded(i:i+2, j:j+2);

            % Center pixel
            p = window(2,2);

            % Mean of 8 neighbors (exclude center efficiently)
            m = (sum(window(:)) - p) / 8;

            % Outlier detection
            if abs(p - m) > D
                out(i,j) = m;   % replace noisy pixel
            else
                out(i,j) = p;   % keep original pixel
            end
        end
    end
end
