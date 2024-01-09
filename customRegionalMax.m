function regionalMax = customRegionalMax(I)    
    % Pad the image with Inf on all sides to handle boundaries
    paddedI = padarray(I, [1, 1], Inf, 'both');
    
    % Initialize the matrix for regional maxima
    regionalMax = false(size(I));
    
    % Iterate over each pixel in the original image size
    for i = 1:size(I,1)
        for j = 1:size(I,2)
            % Extract the neighborhood of the current pixel
            neighborhood = paddedI(i:i+2, j:j+2);
            
            % The current pixel is the center of the neighborhood
            currentPixel = neighborhood(2,2);
            
            % Remove the center pixel from the neighborhood
            neighborhood(2,2) = -Inf;
            
            % Check if the current pixel is greater than all of its neighbors
            if currentPixel > max(neighborhood(:))
                % If true, it is a regional maximum
                regionalMax(i,j) = true;
            end
        end
    end
end
