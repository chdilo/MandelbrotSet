clear, clc, close all
% 朱利亚集图集
d = 0.2;
xlim = [-2, 0.8];
ylim = [-1.4, 1.4];

x = xlim(1):d:xlim(2);
y = ylim(1):d:ylim(2);

width = length(x);
height = length(y);

[xGrid,yGrid] = meshgrid(x,y);
z0 = complex(xGrid,-yGrid);

I = cell(height,width);

for y = 1:height
    for x = 1:width
        I{y,x} = imresize(JuliaSet(z0(y,x)),0.25);
    end
end

I = cell2mat(I);
imshow(I)
