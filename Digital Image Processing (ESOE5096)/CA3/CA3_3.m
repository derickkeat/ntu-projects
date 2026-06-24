%% 1. Read image
I = imread('woman_blonde.tif');
I = im2double(I);     % convert to double in [0,1]
Imax = 255;             % for double images PSNR uses max=255

%% 2. Add Gaussian noise (two variances)
densities = [0.1, 0.4];

for density = densities
    noisy = imnoise(I, 'salt & pepper', density);

    %% Start evaluating methods
    results = {};   % store name, image, PSNR, parameters

    %% (a) Median Filter
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


    %% (b) Alpha-Trimmed Mean Filter
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


    %% (c) Midpoint Filter
    best_psnr = -inf;
    best_img = [];
    best_param = [];
    for k = [3 5 7 9 11 13 15 17 19 21]
        out = midpoint(noisy, k);
        curr_psnr = psnr(uint8(out), uint8(I), Imax);
        if curr_psnr > best_psnr
            best_psnr = curr_psnr;
            best_img = out;
            best_param = k;
        end
    end
    results{end+1} = {"Midpoint", best_img, best_psnr, best_param};


    %% (d) Outlier Filter
    best_psnr = -inf;
    best_img = [];
    best_param = [];
    for k = [3 5 7 9 11 13 15 17 19 21]
        out = outlier(noisy, k);
        curr_psnr = psnr(uint8(out), uint8(I), Imax);
        if curr_psnr > best_psnr
            best_psnr = curr_psnr;
            best_img = out;
            best_param = k;
        end
    end
    results{end+1} = {"Outlier", best_img, best_psnr, best_param};


    %% Display results
    figure('Name', sprintf('Density = %.2f', density), 'NumberTitle', 'off');
    subplot(2,3,1); imshow(noisy); title(sprintf('Noisy (density=%.2f)', density));

    for i = 1:4
        subplot(2,3,i+1);
        imshow(results{i}{2});
        title(sprintf('%s\nParam=%s\nPSNR=%.2f dB', ...
            results{i}{1}, mat2str(results{i}{4}), results{i}{3}));
    end

end