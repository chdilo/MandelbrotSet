clear, clc, close all

d = 0.1;
xlim = [-2, 0.6];
ylim = [-1.3, 1.3];

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
