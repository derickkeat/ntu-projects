%% 1. Read image
I = imread('peppers_gray.tif');
I = im2double(I);     % convert to double in [0,1]
Imax = 255;             % for double images PSNR uses max=255

%% 2. Add Gaussian noise (two variances)
variances = [0.05, 0.2];

for v = variances
    noisy = imnoise(I, 'gaussian', 0, v);

    %% Start evaluating methods
    results = {};   % store name, image, PSNR, parameters

    %% (a) Arithmetic Mean Filter — try multiple kernel sizes
    best_psnr = -inf;
    best_img = [];
    best_param = [];
    for k = [3 5 7 9 11 13 15 17 19 21]
        h = fspecial('average', k);
        out = filter2(h, noisy);
        curr_psnr = psnr(uint8(out), uint8(I), Imax);
        if curr_psnr > best_psnr
            best_psnr = curr_psnr;
            best_img = out;
            best_param = k;
        end
    end
    results{end+1} = {"Arithmetic Mean", best_img, best_psnr, best_param};


    %% (b) Gaussian Lowpass Filter — try sigma and size
    best_psnr = -inf;
    best_img = [];
    best_param = [];
    for k = [3 5 7 9 11 13 15 17 19 21]
        for sigma = [0.5 1 1.5 2]
            h = fspecial('gaussian', [k k], sigma);
            out = filter2(h, noisy);
            curr_psnr = psnr(uint8(out), uint8(I), Imax);
            if curr_psnr > best_psnr
                best_psnr = curr_psnr;
                best_img = out;
                best_param = [k sigma];
            end
        end
    end
    results{end+1} = {"Gaussian LPF", best_img, best_psnr, best_param};


    %% (c) Median Filter
    best_psnr = -inf;
    best_img = [];
    best_param = [];
    for k = [3 5 7 9 11 13 15 17 19 21]
        out = medfilt2(noisy, [k k]);
        curr_psnr = psnr(uint8(out), uint8(I), Imax);
        if curr_psnr > best_psnr
            best_psnr = curr_psnr;
            best_img = out;
            best_param = k;
        end
    end
    results{end+1} = {"Median", best_img, best_psnr, best_param};


    %% (d) Wiener Filter
    best_psnr = -inf;
    best_img = [];
    best_param = [];
    for k = [3 5 7 9 11 13 15 17 19 21]
        out = wiener2(noisy, [k k]);
        curr_psnr = psnr(uint8(out), uint8(I), Imax);
        if curr_psnr > best_psnr
            best_psnr = curr_psnr;
            best_img = out;
            best_param = k;
        end
    end
    results{end+1} = {"Wiener", best_img, best_psnr, best_param};


    %% (e) Alpha-Trimmed Mean Filter
    best_psnr = -inf;
    best_img = [];
    best_param = [];
    for k = [3 5 7 9 11 13 15 17 19 21]
        k2 = k * k;
        % pick d = average(1, k^2), forced to be valid even integer
        d = floor((1 + k2) / 2);
        d = d - mod(d, 2);   % force to even
        if d > k2 - 1
            d = d - 2;       % ensure d <= k^2 - 1
        end
        try
            out = alphatrim(noisy, k, d);
            curr_psnr = psnr(uint8(out), uint8(I), Imax);
            if curr_psnr > best_psnr
                best_psnr = curr_psnr;
                best_img = out;
                best_param = [k d];
            end
        catch ME
            disp(ME)
        end 
    end
    results{end+1} = {"Alpha-Trimmed Mean", best_img, best_psnr, best_param};


    %% Display results
    figure('Name', sprintf('Variance = %.2f', v), 'NumberTitle', 'off');
    subplot(2,3,1); imshow(noisy); title(sprintf('Noisy (var=%.2f)', v));

    for i = 1:5
        subplot(2,3,i+1);
        imshow(results{i}{2});
        title(sprintf('%s\nParam=%s\nPSNR=%.2f dB', ...
            results{i}{1}, mat2str(results{i}{4}), results{i}{3}));
    end

end