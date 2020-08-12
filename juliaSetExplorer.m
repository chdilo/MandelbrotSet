function figh = juliaSetExplorer(z0)
%juliaSetExplorer  An interface for exploring the Mandelbrot Julia Set
%
%   juliaSetExplorer() launches a simple interface that allows the Julia
%   Set for any location in the Mandelbrot set to be viewed. The location
%   can be varied by clicking or dragging in a small overview window in the
%   top left. Close the window to exit.
%
%   figh = juliaSetExplorer() also returns a handle to the interface window
%   so that it can be captured or close programmatically.

%   Author: Ben Tordoff
%   Copyright 2010-2019 The MathWorks, Inc.

% First make sure we are capable of running this

% Create the shared data structure
data = struct();
data.DoAnimation = false;
data.LocationList = makeLocationList();
data.NextLocation = 2;
data.MaxIterations = 1000;
if nargin>0
    data.z0 = z0;
else
    data.z0 = data.LocationList(1);
end
x = gpuArray.linspace( -2, 2, 1000 );
y = gpuArray.linspace( -2, 2, 1000 );
[x,y] = meshgrid(x, y);
data.z = complex( x, y );
clear x y

% Build the interface
gui = createGUI();

% Set the initial view
x0 = gpuArray.linspace( -2, 0.5, 1000 );
y0 = gpuArray.linspace( -1.25, 1.25, 1000 );
[x0,y0] = meshgrid(x0, y0);
z0 = complex( x0, y0 );
drawMandelbrot( gui.MandelImage, z0, data.MaxIterations );
onLimitsChanged();

% Animate a set path
if data.DoAnimation
    doAnimation();
end

% Return a handle to the figure if requested
if nargout > 0
    figh = gui.Window;
end


    function gui = createGUI()
        gui = struct();
        
        gui.Window = figure( ...
            'Name', 'Julia Set explorer', ...
            'NumberTitle', 'off', ...
            'HandleVisibility', 'off', ...
            'MenuBar', 'none', ...
            'ToolBar', 'figure',...
            'Visible', 'off', ...
            'SizeChangedFcn', @onFigureResize);
        
        gui.JuliaAxes = axes(gui.Window, ...
            'Position', [0.5 0 0.5 1], ...
            'XLim', [-2 2], 'YLim', [-2 2], ...
            'XTick', [], 'YTick', [], ...
            'DataAspectRatio', [1 1 1] ,...
            'Colormap',[repmat(sky(1000),100,1);0 0 0], ...
            'CLim',[1 10000]);
        addlistener( gui.JuliaAxes, 'YLim', 'PostSet', @onLimitsChanged );
        
        % Also add a small set of axes for showing the Mandelbrot set
        gui.MandelAxes = axes(gui.Window, ...
            'Position', [0 0 0.5 1], ...
            'XLim', [-2 0.5], 'YLim', [-1.25 1.25], ...
            'XTick', [], 'YTick', [], ...
            'DataAspectRatio', [1 1 1] ,...
            'Colormap',[repmat(sky(1000),100,1);0 0 0], ...
            'CLim',[1 10000], ...
            'ButtonDownFcn', @onMandelButtonDown );
        addlistener( gui.MandelAxes, 'YLim', 'PostSet', @mandelLimitsChanged );
        
        gui.JuliaImage = imagesc(gui.JuliaAxes, ...
            'CData', NaN, ...
            'XData', [-2 2], 'YData', [-2 2] );
        
        gui.MandelImage = imagesc(gui.MandelAxes, ...
            'CData', NaN, ...
            'XData', [-2 0.5], 'YData', [-1.25 1.25], ...
            'HitTest', 'off' );
        
        gui.MandelCrosshair = [
            line(gui.MandelAxes, ...
            'XData', [-2 0.5], 'YData', [0 0], ...
            'Color', 'w', ...
            'HitTest', 'off', ...
            'Tag', 'CrossHairH' );
            line(gui.MandelAxes, ...
            'XData', [0 0], 'YData', [-2 2], ...
            'Color', 'w', ...
            'HitTest', 'off', ...
            'Tag', 'CrossHairV' );
            ];
        
        gui.CrossText = text(gui.MandelAxes,...
            real(data.z0),imag(data.z0), ...
            num2str(data.z0), ...
            'VerticalAlignment','top', ...
            'FontSize',12, ...
            'FontWeight','bold', ...
            'HitTest', 'off', ...
            'Color','k', ...
            'BackgroundColor','w',...
            'Margin',eps);
        
        % Remove some things we don't want from the toolbar and add a
        % toggle to the toolbar to hide the mandelbrot view
        tb = findall( gui.Window, 'Type', 'uitoolbar' );
        delete( findall( tb, 'Tag', 'Standard.FileOpen' ) );
        delete( findall( tb, 'Tag', 'Standard.NewFigure' ) );
        delete( findall( tb, 'Tag', 'Standard.EditPlot' ) );
        delete( findall( tb, 'Tag', 'Exploration.Brushing' ) );
        delete( findall( tb, 'Tag', 'Exploration.DataCursor' ) );
        delete( findall( tb, 'Tag', 'Exploration.Rotate' ) );
        delete( findall( tb, 'Tag', 'DataManager.Linking' ) );
        delete( findall( tb, 'Tag', 'Plottools.PlottoolsOn' ) );
        delete( findall( tb, 'Tag', 'Plottools.PlottoolsOff' ) );
        delete( findall( tb, 'Tag', 'Annotation.InsertLegend' ) );
        delete( findall( tb, 'Tag', 'Annotation.InsertColorbar' ) );
        
        gui.ShowMandelToggle = uitoggletool(tb, ...
            'CData', readIcon( 'icon_mandel.png' ), ...
            'TooltipString', '显示/隐藏Mandelbrot视图', ...
            'State', 'on', ...
            'Separator', 'on', ...
            'ClickedCallback', @onMandelTogglePressed );
        
        gui.AnimToggle = uitoggletool(tb, ...
            'CData', readIcon( 'icon_play.png' ), ...
            'TooltipString', '播放动画', ...
            'State', 'off', ...
            'ClickedCallback', @onAnimTogglePressed );
        
        gui.ShowCrossText = uitoggletool(tb, ...
            'CData', readIcon( 'icon_mandel.png' ), ...
            'TooltipString', '显示/隐藏数值', ...
            'State', 'on', ...
            'Separator', 'on', ...
            'ClickedCallback', @onCrossTextPressed );
        % Set the resize function (we can't do this on construction as it
        % would fire!
%         gui.Window.ResizeFcn = @onFigureResize;
    end % createGUI


    function cdata = readIcon( filename )
        [cdata,~,alpha] = imread( filename );
        idx = find( ~alpha );
        page = size(cdata,1)*size(cdata,2);
        cdata = im2double(cdata);
        cdata(idx) = NaN;
        cdata(idx+page) = NaN;
        cdata(idx+2*page) = NaN;
    end % readIcon


    function onMandelButtonDown( ~, ~ )
        pos = gui.MandelAxes.CurrentPoint;
        gui.Window.WindowButtonMotionFcn = @onMandelButtonMotion;
        gui.Window.WindowButtonUpFcn = @onMandelButtonUp;
        updatePosition( complex( pos(1,1), pos(1,2) ) )
    end % onMandelButtonDown


    function onMandelButtonMotion( ~, ~ )
        pos = gui.MandelAxes.CurrentPoint;
        updatePosition( complex( pos(1,1), pos(1,2) ) )
    end % onMandelButtonMotion


    function onMandelButtonUp( ~, ~ )
        pos = gui.MandelAxes.CurrentPoint;
        gui.Window.WindowButtonMotionFcn = [];
        gui.Window.WindowButtonUpFcn = [];
        updatePosition( complex( pos(1,1), pos(1,2) ) )
    end % onMandelButtonUp


    function updatePosition( z0 )
        data.z0 = z0;
        drawMandelbrotCrosshair( gui.MandelCrosshair, gui.CrossText, data.z0 );
        drawJulia( gui.JuliaImage, data.z, data.z0, data.DoAnimation, data.MaxIterations );
        % Capture!
        drawnow
    end % updatePosition


    function onLimitsChanged( ~, ~ )
        % To work out what to draw and at what resolution we need the axis
        % limits and pixel counts.
        xlim = gui.JuliaAxes.XLim;
        ylim = gui.JuliaAxes.YLim;
        pixpos = getpixelposition( gui.JuliaAxes );
        x = gpuArray.linspace( xlim(1), xlim(2), max(0,round(pixpos(3))) );
        y = gpuArray.linspace( ylim(1), ylim(2), max(0,round(pixpos(4))) );
        [x,y] = meshgrid(x, y);
        data.z = complex( x, y );
        gui.JuliaImage.XData = xlim;
        gui.JuliaImage.YData = ylim;
        % Use "update position to force a redraw"
        updatePosition( data.z0 );
    end % onLimitsChanged


    function mandelLimitsChanged( ~, ~ )
        % To work out what to draw and at what resolution we need the axis
        % limits and pixel counts.
        xlim = gui.MandelAxes.XLim;
        ylim = gui.MandelAxes.YLim;
        pixpos = getpixelposition( gui.MandelAxes );
        x0 = gpuArray.linspace( xlim(1), xlim(2), max(0,round(pixpos(3))) );
        y0 = gpuArray.linspace( ylim(1), ylim(2), max(0,round(pixpos(4))) );
        [x0,y0] = meshgrid(x0, y0);
        z0 = complex( x0, y0 );
        gui.MandelImage.XData = xlim;
        gui.MandelImage.YData = ylim;
        % Use "update position to force a redraw"
        drawMandelbrotCrosshair( gui.MandelCrosshair, gui.CrossText, data.z0 );
        drawMandelbrot(gui.MandelImage, z0, data.MaxIterations);
        drawnow
    end % onLimitsChanged


    function onFigureResize( ~, ~ )
        pos = gui.Window.Position;
        xlim = gui.MandelAxes.XLim;
        ylim = gui.MandelAxes.YLim;
        delta_ylim = ( 2*diff( xlim )*pos(4)/pos(3) - diff( ylim ) ) / 2;
        gui.MandelAxes.YLim = ylim + delta_ylim*[-1 1];
        
        xlim = gui.JuliaAxes.XLim;
        ylim = gui.JuliaAxes.YLim;
        if strcmpi( gui.ShowMandelToggle.State, 'on' )
            delta_ylim = ( 2*diff( xlim )*pos(4)/pos(3) - diff( ylim ) ) / 2;
        else
            delta_ylim = ( diff( xlim )*pos(4)/pos(3) - diff( ylim ) ) / 2;
        end
        gui.JuliaAxes.YLim = ylim + delta_ylim*[-1 1];

    end % onFigureResize


    function onMandelTogglePressed( ~, ~ )
        % Toggle the Mandelbrot view on and off
        state = gui.ShowMandelToggle.State;
        gui.MandelAxes.Visible = state;
        gui.MandelAxes.HitTest = state;
        gui.MandelImage.Visible = state;
        gui.MandelCrosshair(1).Visible = state;
        gui.MandelCrosshair(2).Visible = state;
        if strcmpi( gui.ShowCrossText.State, 'on' )
            gui.CrossText.Visible = state;
        end
        pos = gui.Window.Position;
        if strcmpi( gui.ShowMandelToggle.State, 'on' )
            gui.JuliaAxes.Position = [0.5 0 0.5 1];
            xlim = gui.JuliaAxes.XLim;
            ylim = gui.JuliaAxes.YLim;
            delta_ylim = ( 2*diff( xlim )*pos(4)/pos(3) - diff( ylim ) ) / 2;
            gui.JuliaAxes.YLim = ylim + delta_ylim*[-1 1];
        else
            gui.JuliaAxes.Position = [0 0 1 1];
            xlim = gui.JuliaAxes.XLim;
            ylim = gui.JuliaAxes.YLim;
            delta_ylim = ( diff( xlim )*pos(4)/pos(3) - diff( ylim ) ) / 2;
            gui.JuliaAxes.YLim = ylim + delta_ylim*[-1 1];
        end
    end


    function onCrossTextPressed( ~, ~ )
        % Toggle the Mandelbrot view on and off
        state = gui.ShowCrossText.State;
        if strcmpi( gui.ShowMandelToggle.State, 'on' )
            gui.CrossText.Visible = state;
        end
    end


    function onAnimTogglePressed( ~, ~ )
        % Toggle the Mandelbrot view on and off
        data.DoAnimation = strcmpi( gui.AnimToggle.State, 'on' );
        if data.DoAnimation
            doAnimation();
        end
    end


    function doAnimation()
        while data.DoAnimation
            if ~ishandle( gui.Window )
                return;
            end
            updatePosition( data.LocationList(data.NextLocation) );
            data.NextLocation = mod( data.NextLocation, numel( data.LocationList ) ) + 1;
        end
        % Do a final redraw with animation off
        updatePosition( data.LocationList(data.NextLocation) );
    end  % doAnimation


    gui.Window.Visible = 'on';
end


function drawMandelbrot( imh, z, maxIters )
escapeRadius = 20; % Square of escape radius
z0 = z;
pow = 2;
logCount = arrayfun( @processMandelbrotSetElement, z0, pow, escapeRadius, maxIters );
logCount = gather(logCount);

n = 1000;
I = round(n*logCount);
offSet = -n*floor(min(I,[],'all')/n);
I = I + offSet;

inside = round(n*log(maxIters+1-log(log(escapeRadius))/log(pow)+22))+offSet;
I(I == inside) = 100000;

imh.CData = I;
imh.Parent.CLim = [1 100000];
end % drawMandelbrot


function drawMandelbrotCrosshair( l, t, z0 )
hline = l(1);
vline = l(2);

vline.XData = real(z0)*[1 1];
hline.YData = imag(z0)*[1 1];
t.Position = [real(z0), imag(z0)];
t.String = num2str(z0);
end % drawMandelbrotCrosshair


function drawJulia( imh, z, c, animating, maxIterations )
escapeRadius = 20; % Square of escape radius

if animating && numel(z)>1e6
    z = z(1:2:end,1:2:end);
end
pow = 2;
logCount = arrayfun( @processJuliaSetElement, z, pow, c, escapeRadius, maxIterations );

logCount = gather(logCount);

n = 1000;
I = round(n*logCount);
offSet = -n*floor(min(I,[],'all')/n);
I = I + offSet;

inside = round(n*log(maxIterations+1-log(log(escapeRadius))/log(pow)+22))+offSet;
I(I == inside) = 100000;

imh.CData = I;
imh.Parent.CLim = [1 100000];

end % drawJulia


function locations = makeLocationList()
breakpoints = [
    0.29
    0.47 + 0.157143i
    0.4442 + 0.3286i
    0.354911 + 0.585714i
    0.2103 + 0.5551i
    -0.0827 + 0.8355i
    -0.158482 + 1.042857i
    -0.5826 + 0.6143i
    -0.7533 + 0.1178i
    -1.008216 + 0.35i
    -1.25 + 0.2i
    -1.25
    0.29
    ];
numSteps = 10000;
N = numel(breakpoints);
re = interp1( 1:N, real( breakpoints ), linspace( 1, N, numSteps ) );
im = interp1( 1:N, imag( breakpoints ), linspace( 1, N, numSteps ) );
locations = complex( re, im );
end

