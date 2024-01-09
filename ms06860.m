I = imread('mri.png');

notch_filter_image(I);

function filtered = notch_filter_image(image)

    subplot(3,2,1);
    imshow(image);title('Original Image');

    %converting 3 channel rgb image to grayscale
    if size(image,3) == 3
        I = rgb2gray(image);
    else
        I = image;
    end
    
    I = im2double(I);

    %going to frequency domain
    FFT = fftshift(fft2(I));
    %contrast enhancing
    freq_I = log(1+abs(FFT));
    subplot(3,2,2);
    imshow(freq_I,[]);title('Frequency Domain')

    %padding for wrap around edge cases
    padded_freq_I = padarray(freq_I, [1, 1], Inf, 'both');

    %initializing notch detection
    notches = zeros(size(freq_I));
   
    %here we do a comparison for every pixel where we check if its the
    %maximum pixel in its 3x3 neighbourhood. This helps us identify bright
    %regions in the frequency spectrum. Mostly we can identify the center
    %of bright regions and then filter them out using radius threshold
    for i = 1:size(freq_I,1)
        for j = 1:size(freq_I,2)
            %getting a 3x3
            adjacency_matrix = padded_freq_I(i:i+2, j:j+2);
            %focusing on center pixel
            pixel = adjacency_matrix(2,2);
            adjacency_matrix(2,2) = -Inf;

            if pixel > max(adjacency_matrix(:))
                notches(i,j) = 1;
            end
        end
    end

    [H, W] = size(I);

    midH = ceil(H/2);
    midW = ceil(W/2);

    %value decided through trial and error
    threshold=10;

    %creating an exclusion zone in the center to avoid losing image
    %content
    [x, y] = meshgrid(1:size(I,2), 1:size(I,1));
    exclusion_zone = ~((x - midW).^2 + (y - midH).^2 <= threshold^2);
    notches = notches.*exclusion_zone;

    subplot(3,2,3);
    imshow(notches);title('Notch Detection');

    %finding index of notches in freq_spectrum
    [r, c] = find(notches==1);

    %storing the intensity values
    intensities = zeros(size(r));
    for k = 1:length(r)
        intensities(k) = freq_I(r(k), c(k));
    end
    
    %filtering out noise
    threshold_2 = 0.000425;
    [~, index] = sort(intensities, 'descend');

    %fetching the top filtered out intensity values
    [N,~] = size(r);
    %taking top 4-6 values of the notches
    notches_number = floor(N*threshold_2);
    %index of top selected notches
    peaks = index(1:notches_number);
    
    %top selected notches index in r,c
    r_new = zeros(size(peaks));
    c_new = zeros(size(peaks));
    for x=1:size(peaks,1)
        r_new(x,1) = r(peaks(x,1),1);
        c_new(x,1) = c(peaks(x,1),1);
    end
    r=r_new;c=c_new;

    %creating the notch filter
    notch_filter = ones(size(I));
    %radius of notches
    threshold_3 = 7;

    %creating notches
    for a = 1:length(r)
        X = 1:W;Y = 1:H;
        [X, Y] = meshgrid(X, Y);
        %creating the circular notch based on distance and threhsold
        distance = (X - c(a)).^2 + (Y - r(a)).^2;
        distance_2 = (X - (W - c(a) + 1)).^2 + (Y - (H - r(a) + 1)).^2;
        notch_filter(distance <= threshold_3^2) = 0;
        notch_filter(distance_2 <= threshold_3^2) = 0;
    end

    subplot(3,2,4);
    imshow(notch_filter);title('Notch Filter');

    F_filtered = FFT .* notch_filter;
    f = log(abs(F_filtered)+1);
    subplot(3,2,5);
    imshow(f,[]);title('Frequency Domain After Filter');

    I_filtered = real(ifft2(ifftshift(F_filtered)));
    bruh = log(1+I_filtered);
    I_filtered = (I_filtered - min(I_filtered(:))) / (max(I_filtered(:)) - min(I_filtered(:)));
    filtered = I_filtered;
    subplot(3,2,6);
    imshow(bruh);title('Processed Image');
end