# Mandelbrot Set

GPU计算曼德博集和朱利亚集

无法加载图片的话，在 hosts 文件中添加`199.232.68.133 raw.githubusercontent.com`，或[点这里](https://gitee.com/chdilo/MandelbrotSet "Gitee")

## 曼德博集

取复平面上的点$c$，生成一个数列$\lbrace z_n \rbrace$，其中$z_0=0$，$z_n=z_{n-1}^2+c$，若$\lbrace z_n \rbrace$不发散，则点$c$属于曼德博集。

![MandelbrotSet_1024x576.png](https://raw.githubusercontent.com/chdilo/pictures/master/img/MandelbrotSet_1024x576.png)

[3840x2160](https://raw.githubusercontent.com/chdilo/pictures/master/img/MandelbrotSet_3840x2160.png)

将曼德博集内的点涂成黑色，外部的点根据$\lbrace z_n \rbrace$的发散速度涂成不同颜色，上色方案如下图

![20200815192850.svg](https://raw.githubusercontent.com/chdilo/pictures/master/img/20200815192850.svg)

## 朱利亚集

取复平面上的点$z_0$，生成一个数列$\lbrace z_n \rbrace$，其中$z_n=z_{n-1}^2+c,(c \in {\mathbb C})$，若$\lbrace z_n \rbrace$不发散，则点$z_0$属于朱利亚集。下图为$c = -0.77+0.14i$时的朱利亚集。

![JuliaSet_1024x576.png](https://raw.githubusercontent.com/chdilo/pictures/master/img/JuliaSet_1024x576.png)

[3840x2160](https://raw.githubusercontent.com/chdilo/pictures/master/img/JuliaSet_3840x2160.png)

下图为$c$取不同值时得到的朱利亚集

![20200815220134.png](https://raw.githubusercontent.com/chdilo/pictures/master/img/20200815220134.png)

下图为改变$c$点时，朱利亚集的变化

![20200816194113.gif](https://raw.githubusercontent.com/chdilo/pictures/master/img/20200816194113.gif)
