clear
clc


Values = [0.679135540865748,0.395515215668593,0.367436648544477,0.987982003161633,0.0377388662395521,0.885168008202475,0.913286827639239,0.796183873585212,0.0987122786555743,0.261871183870716,0.335356839962797,0.679727951377338,0.136553137355370,0.721227498581740,0.106761861607241,0.653757348668560,0.494173936639270,0.779051723231275,0.715037078400694,0.903720560556316,0.890922504330789,0.334163052737496,0.698745832334795,0.197809826685929,0.0305409463046367,0.744074260367462,0.500022435590201,0.479922141146060,0.904722238067363,0.609866648422558,0.617666389588455,0.859442305646212,0.805489424529686,0.576721515614685,0.182922469414914,0.239932010568717,0.886511933076101,0.0286741524641061,0.489901388512224,0.167927145682257,0.978680649641159,0.712694471678914,0.500471624154843,0.471088374541939,0.0596188675796392,0.681971904149063,0.0424311375007417,0.0714454646006424,0.521649842464284,0.0967300257808670,0.818148553859625,0.817547092079286,0.722439592366842,0.149865442477967,0.659605252908307,0.518594942510538,0.972974554763863,0.648991492712356,0.800330575352402,0.453797708726920,0.432391503783462,0.825313795402046,0.0834698148589140,0.133171007607162];

loc_file = load ('E:\feature scotoma\new_analysis\biosemi_chanlocs.mat');
loc_file = loc_file.chanlocs;

limit = [min(Values) max(Values)];

BACKCOLOR = [1 1 1];  % EEGLAB standard

GRID_SCALE = 200;        % plot map on a 67X67 grid
CIRCGRID   = 201;       % number of angles to use in drawing circles
CONTOURNUM = 0;         % number of contour levels to plot
HEADCOLOR = [0 0 0];    % default head color (black)
CCOLOR = [0 0 0]; % default contour color
EMARKER = '.';          % mark electrode locations with small disks
ECOLOR = [0 0 0];       % default electrode color = black
EMARKERLINEWIDTH = 1;   % default edge linewidth for emarkers
HLINEWIDTH = 2;         % default linewidth for head, nose, ears
BLANKINGRINGWIDTH = .035; % width of the blanking ring
HEADRINGWIDTH    = .007; % width of the cartoon head ring
MAPLIMITS = [0 1];
SHADING = 'interp';


Values = Values(:); % make Values a column vector

[tmpeloc, labels, Th, Rd, indices] = readlocs( loc_file );

Th = pi/180*Th;                              % convert degrees to radians
allchansind = 1:length(Th);

[x,y]     = pol2cart(Th,Rd);  % transform electrode locations from polar to cartesian coordinates

plotrad = max(Rd)*2;                 % default: plot out to the 0.5 head boundary

rmax = 2;             % actual head radius - Don't change this!




xmin = min(-rmax,min(x)); xmax = max(rmax,max(x));
ymin = min(-rmax,min(y)); ymax = max(rmax,max(y));

%
%%%%%%%%%%%%%%%%%%%%%%% Interpolate scalp map data %%%%%%%%%%%%%%%%%%%%%%%%
%
xi = linspace(xmin,xmax,GRID_SCALE);   % x-axis description (row vector)
yi = linspace(ymin,ymax,GRID_SCALE);   % y-axis description (row vector)

[Xi,Yi,Zi] = griddata(y,x,double(Values),yi',xi,'v4'); % interpolate data



tmph = surface(Xi, Yi, zeros(size(Zi))-0.1, Zi,'EdgeColor','none','FaceColor', SHADING);

axis equal
colormap('hot')
colorbar
caxis( [ min(Values) max(Values) ] )

return


%
%%%%%%%%%%%%%%%%%%%%%%% Mask out data outside the head %%%%%%%%%%%%%%%%%%%%%
%
mask = (sqrt(Xi.^2 + Yi.^2) <= rmax); % mask outside the plotting circle
ii = find(mask == 0);
Zi(ii)  = NaN;                         % mask non-plotting voxels with NaNs
ZiC(ii) = NaN;                         % mask non-plotting voxels with NaNs
grid = plotrad;                       % unless 'noplot', then 3rd output arg is plotrad
%
%%%%%%%%%% Return interpolated value at designated scalp location %%%%%%%%%%
%

amin = MAPLIMITS(1);
amax = MAPLIMITS(2);

delta = xi(2)-xi(1); % length of grid entry


hold on
h = gca; % uses current axes
AXHEADFAC = 1.05;     % do not leave room for external ears if head cartoon

set(gca,'Xlim',[-rmax rmax]*AXHEADFAC,'Ylim',[-rmax rmax]*AXHEADFAC);
% specify size of head axes in gca

unsh = (GRID_SCALE+1)/GRID_SCALE; % un-shrink the effects of 'interp' SHADING

tmph = surface(Xi*unsh,Yi*unsh,zeros(size(Zi))-0.1,Zi,...
    'EdgeColor','none','FaceColor',SHADING);

[cls, chs] = contour(Xi,Yi,ZiC,CONTOURNUM,'k');




colormap('hot')
colorbar
return

cax_sgn = sign([amin amax]);                                                  % getting sign
caxis([amin+cax_sgn(1)*(0.05*abs(amin)) amax+cax_sgn(2)*(0.05*abs(amax))]);   % Adding 5% to the color limits

handle = gca;

hin  = squeezefac*headrad*(1- HEADRINGWIDTH/2);  % inner head ring radius
rwidth = BLANKINGRINGWIDTH*1.3;             % width of blanking outer ring
rin    =  rmax*(1-rwidth/2);              % inner ring radius

cnv = convhull(allx,ally);
cnvfac = round(CIRCGRID/length(cnv)); % spline interpolate the convex hull

CIRCGRID = cnvfac*length(cnv);

startangle = atan2(allx(cnv(1)),ally(cnv(1)));
circ = linspace(0+startangle,2*pi+startangle,CIRCGRID);
rx = sin(circ);
ry = cos(circ);

allx = allx(:)';  % make x (elec locations; + to nose) a row vector
ally = ally(:)';  % make y (elec locations, + to r? ear) a row vector
erad = sqrt(allx(cnv).^2+ally(cnv).^2);  % convert to polar coordinates
eang = atan2(allx(cnv),ally(cnv));
eang = unwrap(eang);
eradi =spline(linspace(0,1,3*length(cnv)), [erad erad erad], ...
    linspace(0,1,3*length(cnv)*cnvfac));
eangi =spline(linspace(0,1,3*length(cnv)), [eang+2*pi eang eang-2*pi], ...
    linspace(0,1,3*length(cnv)*cnvfac));
xx = eradi.*sin(eangi);           % convert back to rect coordinates
yy = eradi.*cos(eangi);
yy = yy(CIRCGRID+1:2*CIRCGRID);
xx = xx(CIRCGRID+1:2*CIRCGRID);
eangi = eangi(CIRCGRID+1:2*CIRCGRID);
eradi = eradi(CIRCGRID+1:2*CIRCGRID);
xx = xx*1.02; yy = yy*1.02;           % extend spline outside electrode marks

splrad = sqrt(xx.^2+yy.^2);           % arc radius of spline points (yy,xx)
oob = find(splrad >= rin);            %  enforce an upper bound on xx,yy
xx(oob) = rin*xx(oob)./splrad(oob);   % max radius = rin
yy(oob) = rin*yy(oob)./splrad(oob);   % max radius = rin

splrad = sqrt(xx.^2+yy.^2);           % arc radius of spline points (yy,xx)
oob = find(splrad < hin);             % don't let splrad be inside the head cartoon
xx(oob) = hin*xx(oob)./splrad(oob);   % min radius = hin
yy(oob) = hin*yy(oob)./splrad(oob);   % min radius = hin

ringy = [[ry(:)' ry(1) ]*(rin+rwidth) yy yy(1)];
ringx = [[rx(:)' rx(1) ]*(rin+rwidth) xx xx(1)];

ringh2= patch(ringy,ringx,ones(size(ringy)),BACKCOLOR,'edgecolor','none'); hold on

headx = [rx(:)' rx(1)]*hin;
heady = [ry(:)' ry(1)]*hin;
ringh= plot(headx,heady);
set(ringh, 'color',HEADCOLOR,'linewidth', HLINEWIDTH); hold on

axis equal



EMARKERSIZE = 5;
ELECTRODE_HEIGHT = 2.1;  % z value for plotting electrode information (above the surf)

hp2 = plot3(y,x,ones(size(x))*ELECTRODE_HEIGHT,EMARKER,'Color',ECOLOR,'markersize',EMARKERSIZE,'linewidth',EMARKERLINEWIDTH);

set(gcf, 'color', BACKCOLOR);

hold off
axis off
