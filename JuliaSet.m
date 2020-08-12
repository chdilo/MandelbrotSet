function RGBimage = JuliaSet(c)
% 朱利亚集合
% c = -0.77+0.14i;
if nargin == 0
    c = -0.77+0.14i;
end
maxIterations = 1000;
width = 800;
height = 800;
xlim = [-2, 2];
ylim = [-2, 2];

x = gpuArray.linspace(xlim(1), xlim(2), width);
y = gpuArray.linspace(ylim(1), ylim(2), height);

[xGrid, yGrid] = meshgrid(x, y);
z0 = complex(xGrid, -yGrid);
clear xGrid yGrid

escapeRadius = 20;
pow = 2;
logCount = arrayfun(@processJuliaSetElement, z0, pow, c, escapeRadius, maxIterations);

logCount = gather(logCount);

n = 10000;
I = round(n*logCount);
offSet = -n*floor(min(I,[],'all')/n);
I = I + offSet;

inside = round(n*log(maxIterations+1-log(log(escapeRadius))/log(pow)+22))+offSet;
I(I == inside) = NaN;

m = max(I,[],'all');
map = repmat(sky(n),ceil(m/n),1);
cmap = [map;0 0 0];

RGB = ind2rgb(I,cmap);

if nargout > 0
    RGBimage = RGB;
else
    imshow(RGB)
end

end
