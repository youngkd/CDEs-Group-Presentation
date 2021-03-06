function [t,error] = main_burgers_MoL(nz,dt)

%close all;
%clear;
% Start a stopwatch timer
tic

%set default axes properties
set(0,'DefaultAxesFontSize', 14,'DefaultAxesFontWeight','bold','DefaultAxesLineWidth',1.5);
%set default legend properties
set(0,'DefaultLegendFontSize',14,'DefaultLegendLocation','SouthWest','DefaultLegendFontSizeMode','manual');
%set default line properties
set(0,'DefaultLineLineWidth',1.5);
%set default grid properties
set(0,'DefaultAxesGridLineStyle','factory');

% Set global variables
global mu eps
global z0 zL nz D1
global nsteps maxsteps tprint tflag tout
% Spatial grid
z0 = 0;
zL = 1;
%nz = 201; %number of mesh points
nzout = nz; %vector to store all grid sizes used
dz = (zL-z0)/(nz-1); %initial spatital grid step
z = [z0:dz:zL]'; %spatial grid
basez=z;
error=[];
z = linspace(z0,zL,nz);


% Initial conditions
mu = 0.001;
for i=1:nz
    x(i) = burgers_exact_MoL(z(i),0);
end;

% parameters of the adaptive grid (for agereg function)
npdes = 1;  %number of pdes
nzmax = 1001;   %max grid size
alpha = 0;      %monitor function parameter
beta = 100;     %monitor function parameter
tolz = 0.005;   %equidistribution parameter
bound= 1.1;     %defines a locally bounded grid
imesh= 1;   %(binary) specify monitor funciton
ilim = 1;   %(binary) whether to limit u_xx

% call to ODE solver
t0 = 0;     %initial time
tf = 1;     %end time
%dt = 0.1;     %adaption frequency
yout = x;
zout = z;
nzout= [nzout; nz];
tout = t0;

% solver to stop after this many steps:
maxsteps = 5;
% initial situation
Fig1=figure(1);
set(Fig1, 'Position', [100 100 1000 550])
plot(z,x,'.b-','MarkerSize',15);
xlabel('x');
ylabel('u(x,t)');
axis([0, 1, 0, 1.5]);
grid on
hold on


for i=1:nz
    uexact(i) = burgers_exact_MoL(z(i),t0); %exact solution
end
plot(z,uexact,'r','LineWidth',2);
axis([0, 1, 0, 1.5]);
legend('Approximate Solution','Exact Solution');

hold off

%save plot
% plot_count=0;
% print('-painters','-dpng',sprintf('images\\MoL_burgers_%d',plot_count))

% differentiation matrix
D1 = three_point_centered_D1(z); %use 3 point central FDM

tk = t0;
tspan= [t0, tf];
tprint = dt;
eps = 0.001;

while tk <= tf - 1.e-5
% initialize step counter
	nsteps= 0;
    
	% do the integration for maxsteps steps in a loop % until t becomes larger than tf
	options = odeset('RelTol',1e-5,'AbsTol',1e-5);
	options = odeset(options,'Events',@count_steps);
	options = odeset(options,'JPattern',jpattern(nz));
	[t,y,te,ye,ie] = ode15s(@burgers_adaptive_pde,tspan, ...
	 	x,options);
	
	tk = t(end);
	tspan = [tk, tf];
	x = [];
	x = y(end,:);
    
	%zout = [zout; z];
	nzout= [nzout; nz];
	tout = [tout ; tk];

	% plot intermediate results
	if tflag >= 0
	 	plot(z,x,'.b-','MarkerSize',15);
        grid on
        hold on

        clearvars uexact
        for i=1:nz
            uexact(i) = burgers_exact_MoL(z(i),tk); %exact solution
        end;
		plot(z,uexact(1:length(z)),'r','LineWidth',2)
        xlabel('x');
        ylabel('u(x,t)');
        legend('Approximate Solution','Exact Solution');
        axis([0, 1, 0, 1.5]);
        grid on
        hold off
        
        %save plot
%         plot_count=plot_count+1;
%         print('-painters','-dpng',sprintf('images\\MoL_burgers_%d',plot_count))
        
		tprint = tprint + dt;
		
    end

    error=[error max(abs(uexact-x))];
    %error=[error max(abs(uexact-x'))];
	% compute a new differentiation matrix
	D1 = three_point_centered_D1(z);
end
figure(2)
loglog(tout(2:end),error,'.b-','markersize',15)
xlabel('t');
ylabel('max grid error');
grid on
%fprintf('max grid error across all time steps = %6.4f\n',max(error));
% read the stopwatch timer
tcpu = toc; %output computation ttime
nav = sum(nzout)/length(nzout); %output average number of mesh points
fprintf('time = %6.4f, \naverage # mesh points = %8.4f \n\n',tcpu,nav);

t = tout(2:end);
end