function RGBimage = JuliaSet(c)
% 朱利亚集合
% c = -0.77+0.14i;
if nargin == 0
    c = -0.77+0.14i;
end

maxIterations = 1024;
width = 800;
height = 800;
xlim = [-2, 2];
ylim = [-2, 2];

x = gpuArray.linspace(xlim(1), xlim(2), width);
y = gpuArray.linspace(ylim(1), ylim(2), height);

[xGrid, yGrid] = meshgrid(x, y);
z0 = complex(xGrid, -yGrid);
clear xGrid yGrid

escapeRadius = 16;
pow = 2;
logCount = arrayfun(@processJuliaSetElement, z0, pow, c, escapeRadius, maxIterations);

logCount = gather(logCount);

n = 10000;
I = round(n*logCount);

offSet = -n*floor(min(I(~isinf(I)),[],'all')/n);
if isempty(offSet)
    I = ones(height,width);
else
    I = I + offSet;
    inside = round(n*tflog(maxIterations+1,escapeRadius,pow)) + offSet;
    I(I == inside) = NaN;
end

m = max(I,[],'all');
if isnan(m)
    RGB = zeros(height,width,3);
else
    map = repmat(sky(n),ceil(m/n),1);
    cmap = [map;0 0 0];
    
    RGB = ind2rgb(I,cmap);
end

if nargout > 0
    RGBimage = RGB;
else
    imshow(RGB)
end

end
