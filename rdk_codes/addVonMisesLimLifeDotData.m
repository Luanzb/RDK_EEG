function dots = addVonMisesLimLifeDotData(const,dots,dots0)
% Version 1.0, Feb 2012 by Martin Rolfs
% Modified by Martin Szinte, 21 Jan 2016
%           - add scr as input and use my own conversion in pix
% NH :      - took out scr; (9.4.2019)
%           - changed deg to pix

dots.cent = dots.xyd(1:2);
dots.diam = dots.xyd(3);

% change directions for each new phase
dots.dirs = circ_vmrnd(dots.the*pi/180,dots.kap,dots.num)/pi*180;

for f = 1 : round(dots.dur / const.frame_dur)
    % displacement per frame for each dot
    dxdy(:,1:2) = const.frame_dur * dots.spd_pix * [cos(pi*dots.dirs/180) -sin(pi*dots.dirs/180)];

    % update position of all dots
    if f == 1
        dots.posi{f} = dots0.posi{end} + dxdy;
    else
        dots.posi{f} = dots.posi{f-1} + dxdy;
    end
        
    % wrap around if out of circular aperture
    wrap = sqrt(dots.posi{f}(:,1).^2 + dots.posi{f}(:,2).^2) > dots.diam/2;
    
    if sum(wrap) > 0
        % wraps it to a position on the opposite half of the circle
        wrapphi = pi*dots.dirs(wrap)/180 + pi/2 + rand(sum(wrap),1)*pi;
        wrapamp = dots.diam/2;
        
        [wrapx,wrapy] = pol2cart(wrapphi,wrapamp);
        dots.posi{f}(wrap==1,:) = [wrapx -wrapy];
    end
    
    % decide which dots end their life time and, thus, change position
    ranLife = dots.lif(1)+exprnd(dots.lif(2)-dots.lif(1),1,dots.num);   % life times drawn from exponential distribution
    if f == 1
        newLife(dots0.life{end}< ranLife) = false;
        newLife(dots0.life{end}>=ranLife) = true;
        
        % update lifetime
        dots.life{f}( newLife)   = 1;
        dots.life{f}(~newLife)   = dots0.life{end}(~newLife)+1;
    else
        newLife(dots.life{f-1}< ranLife) = false;
        newLife(dots.life{f-1}>=ranLife) = true;
        
        % update lifetime
        dots.life{f}( newLife)   = 1;
        dots.life{f}(~newLife)   = dots.life{f-1}(~newLife)+1;
    end
    
    % replace dots that ended their lifetime
    dots.posi{f}(newLife,:) = (rand(sum(newLife), 2)-0.5) * dots.diam; 
     
    % make sure they are all inside the aperture
    out = sqrt(dots.posi{f}(:,1).^2 + dots.posi{f}(:,2).^2) > dots.diam/2;
    while sum(out)
        dots.posi{f}(out==1,:) = (rand(sum(out), 2)-0.5) * dots.diam;
        out = sqrt(dots.posi{f}(:,1).^2 + dots.posi{f}(:,2).^2) > dots.diam/2;
    end
    
    % draw new direction for dots that begin a new life
    dots.dirs(newLife) = circ_vmrnd(dots.the*pi/180,dots.kap,sum(newLife))/pi*180;
end

dots.posi = [dots0.posi dots.posi];
dots.life = [dots0.life dots.life];
end