img = imread('hurricane-katrina.tif');
wname = 'db4';

t_ratio = zeros(1,10);        % t2/t1 ratios
max_diff = zeros(1,10);       % max absolute difference

for n = 1:10
    % --- Time wavedec2 ---
    w1 = @() wavedec2(img, n, wname);
    t1 = timeit(w1);

    % --- Time wavefast ---
    w2 = @() wavefast(img, n, wname);
    t2 = timeit(w2);

    % Store ratio
    t_ratio(n) = t2 / t1;

    % --- Compute maximum abs difference of coefficients ---
    c1 = wavedec2(img, n, wname);
    c2 = wavefast(img, n, wname);

    max_diff(n) = max(abs(c1(:) - c2(:)));
end

%% ---------- (a) Plot t2/t1 ratios ----------
figure;
plot(1:10, t_ratio, '-o', 'LineWidth', 1.5);
xlabel('n (Decomposition level)');
ylabel('t_2 / t_1');
title('Ratio of Execution Times: wavefast / wavedec2');
grid on;

%% ---------- (b) Plot max absolute differences ----------
figure;
plot(1:10, max_diff, '-s', 'LineWidth', 1.5);
xlabel('n (Decomposition level)');
ylabel('Max |w1 - w2|');
title('Maximum Absolute Differences Between wavefast and wavedec2');
grid on;
