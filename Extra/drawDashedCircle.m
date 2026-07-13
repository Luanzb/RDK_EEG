function drawDashedCircle(window, centerX, centerY, radius, color, dashLength, gapLength)
% Create points around the circle
    numPoints = 360; % One point per degree
    angles = linspace(0, 2*pi, numPoints);
    
    % Calculate which points should be visible (dashes vs gaps)
    circumference = 2 * pi * radius;
    dashUnit = dashLength + gapLength;
    
    visiblePoints = [];
    for i = 1:numPoints
        currentArcLength = (i-1) / numPoints * circumference;
        positionInUnit = mod(currentArcLength, dashUnit);
        
        if positionInUnit <= dashLength
            x = centerX + radius * cos(angles(i));
            y = centerY + radius * sin(angles(i));
            visiblePoints = [visiblePoints; x, y];
        end
    end
    
    if ~isempty(visiblePoints)
        Screen('DrawDots', window, visiblePoints', dashLength, color, [], 1);
    end
end