clear, clc, close all
% 曼德博集合
maxIterations = 1000; % 最大迭代次数
width = 1000;
height = 1000;
xlim = [-2, 0.6];
ylim = [-1.3, 1.3];

x = gpuArray.linspace(xlim(1),xlim(2),width);
y = gpuArray.linspace(ylim(1),ylim(2),height);

[xGrid,yGrid] = meshgrid(x,y);
z0 = complex(xGrid,-yGrid);
clear xGrid yGrid

escapeRadius = 20;
pow = 2;
logCount = arrayfun(@processMandelbrotSetElement, z0, pow, escapeRadius, maxIterations);

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

imshow(RGB)
% imwrite(RGB,'MandelbrotSet.png','BitDepth',16)

