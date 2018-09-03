function [MFinal] = resize_nii(data,outputSize)

%not sure who wrote this...

%//Figure out size of original matrix
data=single(data);
d = size(data);

%//Scaling coefficients
scaleCoeff = outputSize ./ d;

%//Indices of original slices in 3D
z = 1:d(3);

%//Output slice indices in 3D
zi=1:1/scaleCoeff(3):d(3);

%//Create gridded interpolated co-ordinates for 1 slice
[X,Y] = meshgrid(1:1/scaleCoeff(2):d(2), 1:1/scaleCoeff(1):d(1));

%//We simply duplicate the last rows and last columns of the grid if
%//by doing meshgrid, we don't get exactly the output size we want
%//This is due to round off when perform 1/scaleCoeff(2) or
%//1/scaleCoeff(1).  We would be off by 1.
if size(X,1) ~= outputSize(1)
    X(end+1,:) = X(end,:);
    Y(end+1,:) = Y(end,:);
end
if size(X,2) ~= outputSize(2)
    X(:,end+1) = X(:,end);
    Y(:,end+1) = X(:,end);
end

%//For each slice...
M2D = zeros(outputSize(1), outputSize(2), d(3));
for ind = z
    %//Interpolate each slice via interp2
    M2D(:,:,ind) = interp2(data(:,:,ind), X, Y);
end

%//Now interpolate in 3D
MFinal = permute(interp1(z,permute(M2D,[3 1 2]),zi),[2 3 1]);

%//If the number of output slices don't match after we interpolate in 3D, we
%//just duplicate the last slice again
if size(MFinal,3) ~= outputSize(3)
    MFinal(:,:,end+1) = MFinal(:,:,end);
end
end

