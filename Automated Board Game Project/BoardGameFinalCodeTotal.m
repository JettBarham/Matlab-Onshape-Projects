% NOTE ALL PROGRAMS START WITH A HEADER COMMENT.  
% This program is a MATLAB script version of playing a board game.
% This code was written starting April 27, 2025 by Jett Barham and Harry Carleton Paget
% using a base of code written by Dr. Julie Whitney and edited by Dr. Danny Francis 
% during the University of Kentucky Fall 2024 Semester.
clc;
clear;
clear s
clear a
%***********************************************************************
% SECTION 1 - Variable and function declarations
%***********************************************************************

%BOARD MOVEMENT DECLARATIONS / FUNCTIONS


s = serialport('COM3',9600);     %Modify COM ports. This is for steppers
a = arduino('COM4');     %This is for servos
pause(2);   %Pause for 2 seconds to allow the connection to the serial port to be established

s1 = servo(a,'D9','MinPulseDuration',700*10^-6,'MaxPulseDuration',2300*10^-6);
s2 = servo(a,'D10','MinPulseDuration',700*10^-6,'MaxPulseDuration',2300*10^-6);
s3 = servo(a,'D11','MinPulseDuration',700*10^-6,'MaxPulseDuration',2300*10^-6);
s4 = servo(a,'D12','MinPulseDuration',700*10^-6,'MaxPulseDuration',2300*10^-6);

%Basic definitions
full_rotation_stepper = 2052;
current_position = 0;
currentDir = -1;

%These are all not likely accurate
full_rotation_crane = 3981;
one_spot_crane = full_rotation_crane/15;
new_full_rot_crane = 4380; 
new_one_spot = new_full_rot_crane/15;

%Definitions to change while testing
steps_recalibration = 0; %Add or subtract this from all steps if weird stuff

pause(2);


%DEFINED FUNCTIONS

%THIS FUNCTION RUNS THE SWAP
function [doneSwap] = runSwap(steps1, steps2, s_or_a) %Only call this with s
steps_for_1 = steps1;
steps_for_2 = steps2;
% Append combines the various strings into one individual string to be sent over to the Arduino
Multiple_Stepper_String = append("1,",int2str(steps_for_1),",","2,",int2str(steps_for_2));
% Send the string to the Arduino using the connected serial port
write(s_or_a,Multiple_Stepper_String,'string');
% Pause to allow the previous movements to complete before sending new movements
pause(5)
doneSwap = "Finished swapping";
end
%CALLS THE SWAP FUNCTION ABOVE
%runSwap(0, full_rotation_stepper/2, s)


%THIS FUNCTION ROTATES THE CRANE TOWARDS A TARGET
function [doneCraneForward, currentPosForward] = craneForward(spacesNumber, steps2, s_or_a, recalibration, direction) %Only call this with s
steps_for_1 = 0;
switch spacesNumber
    case 0
        steps_for_1 = 0;
    case 1
        steps_for_1 = 290 + recalibration;
    case 2
        steps_for_1 = 540 + recalibration;
    case 3
        steps_for_1 = 810 + recalibration;
    case 4
        steps_for_1 = 1050 + recalibration;
    case 5
        steps_for_1 = 1310 + recalibration;
    case 6
        steps_for_1 = 1585 + recalibration;
    case 7
        steps_for_1 = 1875 + recalibration;
    case 8
        steps_for_1 = 2180 + recalibration;
end
if (direction < 1)
    steps_for_1 = -steps_for_1;
end
if (steps_for_1 < 0)
    steps_for_1 = steps_for_1 - (40 + ((-steps_for_1/325)*10));
end
steps_for_2 = steps2;
% Append combines the various strings into one individual string to be sent over to the Arduino
Multiple_Stepper_String = append("1,",int2str(steps_for_1),",","2,",int2str(steps_for_2));
% Send the string to the Arduino using the connected serial port
write(s_or_a,Multiple_Stepper_String,'string');
% Pause to allow the previous movements to complete before sending new movements
pause(9)
doneCraneForward = "Finished moving forward";
currentPosForward = steps_for_1;
end
%CALLS THE FUNCTION ABOVE
%[consoleOut, current_position] = craneForward(2, 0, s, steps_recalibration, 1);
%disp(consoleOut)


%THIS FUNCTION ROTATES THE CRANE BACK FROM A TARGET
function [doneCraneReturn, currentPosBack, dirBack] = craneReturn(steps1, steps2, s_or_a) %Only call this with s
steps_for_1 = steps1;
steps_for_2 = steps2;
% Append combines the various strings into one individual string to be sent over to the Arduino
Multiple_Stepper_String = append("1,",int2str(steps_for_1),",","2,",int2str(steps_for_2));
% Send the string to the Arduino using the connected serial port
write(s_or_a,Multiple_Stepper_String,'string');
% Pause to allow the previous movements to complete before sending new movements
pause(9)
doneCraneReturn = "Finished returning crane";
if (steps_for_1 > 0)
    dirBack = 1;
else
    dirBack = -1;
end
currentPosBack = 0;
end
%CALLS THE FUNCTION ABOVE
%[consoleOut, current_position, currentDir] = craneReturn(-current_position, 0, s);
%disp(consoleOut)


%THIS FUNCTION RESETS THE CRANE ARM IF YOU'RE NEXT FORWARD CRANE MOVE IS
%THE SAME DIRECTION AS IT WAS GOING WHEN IT RETURNED
function [doneJigglingCrane, resetDir] = resetJiggle(s_or_a, dir)
if (dir < 0)
    % Jiggle in the positive direction 30 steps
    steps_for_1 = 30;
    steps_for_2 = 0;
    % Append combines the various strings into one individual string to be sent over to the Arduino
    Multiple_Stepper_String = append("1,",int2str(steps_for_1),",","2,",int2str(steps_for_2));
    % Send the string to the Arduino using the connected serial port
    write(s_or_a,Multiple_Stepper_String,'string');
    % Pause to allow the previous movements to complete before sending new movements
    pause(2)
else
    % Jiggle in the negative direction 30 steps
    steps_for_1 = -30;
    steps_for_2 = 0;
    % Append combines the various strings into one individual string to be sent over to the Arduino
    Multiple_Stepper_String = append("1,",int2str(steps_for_1),",","2,",int2str(steps_for_2));
    % Send the string to the Arduino using the connected serial port
    write(s_or_a,Multiple_Stepper_String,'string');
    % Pause to allow the previous movements to complete before sending new movements
    pause(2)
end
resetDir = -dir;
doneJigglingCrane = "Finished jiggling crane";
end
%[consoleOut, currentDir] = resetJiggle(s, currentDir);
%disp(consoleOut)


%THIS FUNCTION MAKES THE CLAWS AND PINION PICK UP A PIECE
function [donePickUp] = pickUp(servo1, servo2)
writePosition(servo2, .45); %open claws
pause(2);
writePosition(servo1, 0); %down rack pinion
pause(3);
writePosition(servo2, .8); %closing claws
pause(.5);
writePosition(servo2, .9); %closing claws
pause(.5);
writePosition(servo2, 1); %closed claws
pause(1);
writePosition(servo1, 1); %default up rack pinion
pause(3);
donePickUp = "Done picking up";
end
%[consoleOut] = pickUp(s1, s2);
%disp(consoleOut)


%THIS FUNCTION MAKES THE CLAWS AND PINION PUT DOWN A PIECE
function [donePutDown] = putDown(servo1, servo2)
writePosition(servo1, 0); %down rack pinion
pause(3);
writePosition(servo2, .45); %open claws
pause(2);
writePosition(servo1, 1); %default up rack pinion
pause(3);
writePosition(servo2, 1); %closed claws
pause(2);
donePutDown = "Done putting down";
end
%[consoleOut] = putDown(s1, s2);
%disp(consoleOut)


%THIS FUNCTION RUNS DUMP CLOSE TO SWAP
function [doneDumpingClose] = dumpClose(servo3)
writePosition(servo3, 0); %default down
pause(1);
writePosition(servo3, .75); %up
pause(1);
writePosition(servo3, 0); %default down
pause(1);
doneDumpingClose = "Done dumping close";
end
%[consoleOut] = dumpClose(s3);
%disp(consoleOut)


%THIS FUNCTION RUNS DUMP FAR FROM SWAP
function [doneDumpingFar] = dumpFar(servo4)
%RUNNING DUMP FARTHER FROM SWAP
writePosition(servo4, 0); %default down
pause(1);
writePosition(servo4, .6); %up
pause(1);
writePosition(servo4, 0); %default down
pause(1);
doneDumpingFar = "Done dumping far";
end
%[consoleOut] = dumpFar(s4);
%disp(consoleOut)


%THIS FUNCTION LETS YOU MOVE A LITTLE IN EITHER DIRECTION TO CENTER THINGS.
%MAKE SURE YOU FINISH BY MOVING CLOCKWISE (-). ALWAYS CALL S
function [doneMovingLittle] = moveALittle(s_or_a, dir)
if (dir > 0)
    % Jiggle in the positive direction 30 steps
    steps_for_1 = 30;
    steps_for_2 = 0;
    % Append combines the various strings into one individual string to be sent over to the Arduino
    Multiple_Stepper_String = append("1,",int2str(steps_for_1),",","2,",int2str(steps_for_2));
    % Send the string to the Arduino using the connected serial port
    write(s_or_a,Multiple_Stepper_String,'string');
    % Pause to allow the previous movements to complete before sending new movements
    pause(2)
else
    % Jiggle in the negative direction 30 steps
    steps_for_1 = -30;
    steps_for_2 = 0;
    % Append combines the various strings into one individual string to be sent over to the Arduino
    Multiple_Stepper_String = append("1,",int2str(steps_for_1),",","2,",int2str(steps_for_2));
    % Send the string to the Arduino using the connected serial port
    write(s_or_a,Multiple_Stepper_String,'string');
    % Pause to allow the previous movements to complete before sending new movements
    pause(2)
end
doneMovingLittle = "Finished moving a little";
end
%[consoleOut] = moveALittle(s, 1);
%disp(consoleOut)




% MOVES TO DEFAULT POSITIONS
writePosition(s3, 0); %default down dump 1
pause(1.5);
writePosition(s4, 0); %default down dump 2
pause(1.5);
writePosition(s1, 1); %default up for rack pinion
pause(3);
writePosition(s2, 1); %closed claws
pause(1.5);

%PUT A DOUBLE COMMENT HERE AND RUN THE UNCOMMENTED LINES BELOW UNTIL THE
%GAME PIECE MOVER IS CENTERED OVER SPACE 1 (only brown planet near dump)
%Positive values move clockwise, negative counterclockwise.

[consoleOut] = moveALittle(s, -1);
disp(consoleOut)



%Other variable declarations:
cam = webcam('USB Camera');
posPlayer1 = 15;
posPlayer2 = 1;
ScorePlayer1=0;
LivesPlayer1=4;
ScorePlayer2=0;
LivesPlayer2=4;
turnNum=0;
strAdd = "+";
strSub = "-";
strMulti = "x";
strDiv = "/";
mathSym = "s";

%pseudo-variable declarations for global varaibles because fucking matlab
%doesn't let you specify a function's return type
function setGlobalx(val)
global moveTo;
moveTo = val;
end

function r = getGlobalx
global moveTo;
r = moveTo;
end



%non-trivial timer that keeps track of SIMULATED time (it may be
%inaccurate if one's computer is slow); takes an integer parameter
function mathTime(answer)
userInput = -999;
accumTime = timer( ...
    'Period', 1, ... % delay between TimerFcn executions
    'TasksToExecute', answer, ... % number of times the timer should execute before stopping
    'ExecutionMode', 'fixedRate', ... % executes callback at a fixed rate (every second)
    'TimerFcn', {@timerAccu} ...%event call to time accumulator function
    );

start(accumTime)
    while (answer ~= accumTime.TasksExecuted && answer ~= userInput)
         userInput = input('Answer: ');
        if (userInput == answer)
            setGlobalx(answer - accumTime.TasksExecuted);
            stop(accumTime)
            disp('Correct answer!');
                break
          else 
            disp('Incorrect answer! Try again!');
        end
    end %%end while

    if (getGlobalx == -1)
            disp('Too slow!');

    end

end

function timerAccu(timerObj, ~)
    if (timerObj.TasksToExecute == timerObj.TasksExecuted)
        setGlobalx(-1);
        stop(timerObj)
    end
end




function countdown3()
disp('Timer starts in . . .');
pause(1)
count3 = timer( ...
    'Period', 1, ... % Period, in seconds
    'TasksToExecute', 3, ... % Number of timer cycles
    'ExecutionMode', 'fixedRate', ... % Execute the callback exclusively by period
    'TimerFcn', {@task3} ...
    );

start(count3)
pause(3)
stop(count3)
end

function task3(timerObj, ~)
disp(4 - timerObj.TasksExecuted);
end

%***************************BEGIN GAME**************************************
%***************************BEGIN GAME**************************************
%***************************BEGIN GAME**************************************
%***************************BEGIN GAME**************************************
%***************************BEGIN GAME**************************************
%***************************BEGIN GAME**************************************
%***************************BEGIN GAME**************************************



scoreGoal = input('Enter score goal for this match: ');
difLevel = 0;
while (difLevel > 6 || difLevel < 1)
    difLevel = input('Enter the level of difficulty for this match (1-4) or type "0" for more information: ');
    if difLevel == 0
        fprintf(['Level 1: Addition \n' ...
            'Level 2: Subtraction \n' ...
            'Level 3: Multiplication \n' ...
            'Level 4: Division \n' ])
    elseif (difLevel > 6 || difLevel < 0)
        disp('Invalid input.')
    end
end

    
while (ScorePlayer1 ~= scoreGoal && ScorePlayer2 ~= scoreGoal)
    % Check whose turn it is
    whoseTurn = (mod(turnNum,2));
    if (whoseTurn)==0 %
        fprintf('Player 1, your turn, you are LIGHT blue \n');
    else
        fprintf('Player 2, your turn, you are DARK blue \n');
    end




% ******************************************************************
%  Section 2 - rolling the dice and checking for legal moves
%*******************************************************************


if(whoseTurn == 0)
sentinel = input('Roll the dice and then click enter!');

pause(2)
imgTemp = snapshot(cam);

imshow(imgTemp)

imcrop(imgTemp, [215 245.0000 148.0000 160.0000])



%imgCropped = (imgTemp, )




%Declares variables based on what the minimum and maximum radii are of the
%dice.
%Problems: if the camera isn't static, I need to figure out how to find
%regions on interest based on both color and geometry.


rMin = 3;
rMax = 8;

[centersDark, radiiDark, metricDark] = imfindcircles(imgTemp,[rMin, rMax], 'Method','PhaseCode', 'ObjectPolarity', 'dark', 'Sensitivity', .88, 'EdgeThreshold', .35);

%viscircles(centersDark, radiiDark, 'EdgeColor', 'b')


% Setting up bounding box to count number of circles for buggy, erroneous counting at 2 and 1 dots

if (length(centersDark) < 3)
 %distance between dots is marginal
countCircles = length(radiiDark); %                                       therefore, there is only 1 dot
else %                                distance between dots is non-marginal
countCircles = length(centersDark);  %therefore, we will count the number of circles
    if (countCircles > 6)
        countCircles = 6;
    end
end
dice = countCircles;
fprintf('You rolled a %d! \n', dice);

else
        dynStat=randi([1,3]);
        dice=randi(6);
        fprintf('Player2 throws their dice!\n');
        pause(2)
        fprintf(' ... \n')
        pause(2)
        switch dynStat
            case 1
                fprintf('Lucky number %d! \n', dice);
            case 2
                fprintf('Awesome! A %d! \n', dice);
            case 3
                fprintf('%d! \n', dice);
        end
        pause(1)
end
%%



answer = 0;
MoveComplete=0;




switch difLevel
   case 4
      firstVal = randi([24,60]);
      mathSym = strDiv;
      firstVal = (firstVal - mod(firstVal, dice));
      answer = firstVal / dice;
   case 3
       mathSym = strMulti;
       firstVal = randi([2,7]);
      answer = firstVal * dice;
    case 2
        firstVal = randi([10,25]);
        mathSym = strSub;
      answer = firstVal - dice;
    case 1
        firstVal = randi([10,25]);
        mathSym = strAdd;
        answer = firstVal + dice;
end

disp('Equation generated!');
pause(1)
countdown3();
fprintf('What is %d %s %d? ', firstVal, mathSym, dice);
mathTime(answer);



totalNumSpacesMove = getGlobalx;
if (getGlobalx == -1)
            fprintf('The user took too long to answer and will be moved directly to dump and lose one life!\n')
                %put in code that guarantees dump from current position
     else 
        fprintf('User correctly answered the question in %d seconds and will move %d spaces! \n', (answer-getGlobalx), (getGlobalx));
        beforeMovePos1 = posPlayer1;
        beforeMovePos2 = posPlayer2;
            if (whoseTurn == 0) %only entered if player 1's turn
                fprintf('This corresponds to space %d', mod(getGlobalx + posPlayer1,15));
                    if (getGlobalx + posPlayer1 == posPlayer2)
                        fprintf('Wait! Player 2 occupies that position! \nPlayer 1 is frozen!')
                    elseif (mod(getGlobalx + posPlayer1,15) == 2 || mod(getGlobalx + posPlayer1,15) == 4)
                        fprintf('Wait! That positon is a dump! \nPlayer 1 is moved to dump and loses 1 life!\n')
                        posPlayer1 = 2;
                        LivesPlayer1 = LivesPlayer1 - 1;

                    else 
                        ScorePlayer1 =+ ((totalNumSpacesMove + posPlayer1)/15);
                        posPlayer1  = mod(getGlobalx + posPlayer1,15);
                    end 

            else %only entered if player 2's turn
                fprintf('This corresponds to space %d', mod(getGlobalx + posPlayer2,15));
                    if (getGlobalx + posPlayer2 == posPlayer1)
                        fprintf('Wait! Player 1 occupies that position! \nPlayer 2 is frozen!')
                    elseif (mod(getGlobalx + posPlayer2,15) == 2 || mod(getGlobalx + posPlayer2,15) == 4) %only entered if player 2's turn
                        fprintf('Wait! That positon is a dump! \nPlayer 2 is moved to dump and loses 1 life!\n')
                        posPlayer2 = 2;
                        LivesPlayer2 = LivesPlayer2 - 1;
                    else
                        ScorePlayer2 =+ ((totalNumSpacesMove + posPlayer2)/15);
                        posPlayer2  = mod(getGlobalx + posPlayer2,15);
                    end
            end
end

if (whoseTurn == 0 && (beforeMovePos1 ~= posPlayer1))


    if (beforeMovePos1<= 9)
        % go to pick up piece clockwise then come back
        if (currentDir == 1)
            [consoleOut, currentDir] = resetJiggle(s, currentDir);
            disp(consoleOut)
        end
        [consoleOut, current_position] = craneForward(beforeMovepos1-1, 0, s, steps_recalibration, 1);
        disp(consoleOut)
        [consoleOut] = pickUp(s1, s2);
        disp(consoleOut)
        [consoleOut, current_position, currentDir] = craneReturn(-current_position, 0, s);
        disp(consoleOut)

    else
        % go to pick up piece counterclockwise then come back
        if (currentDir == -1)
            [consoleOut, currentDir] = resetJiggle(s, currentDir);
            disp(consoleOut)
        end
        [consoleOut, current_position] = craneForward(abs(beforeMovePos1-16), 0, s, steps_recalibration, -1);
        disp(consoleOut)
        [consoleOut] = pickUp(s1, s2);
        disp(consoleOut)
        [consoleOut, current_position, currentDir] = craneReturn(-current_position, 0, s);
        disp(consoleOut)
    end
    
    if (posPlayer1 <= 9)
        % go to put down piece clockwise then come back
        if (currentDir == 1)
            [consoleOut, currentDir] = resetJiggle(s, currentDir);
            disp(consoleOut)
        end
        [consoleOut, current_position] = craneForward(posPlayer1-1, 0, s, steps_recalibration, 1);
        disp(consoleOut)
        [consoleOut] = putDown(s1, s2);
        disp(consoleOut)
        [consoleOut, current_position, currentDir] = craneReturn(-current_position, 0, s);
        disp(consoleOut)
    else
        % go to put down piece counterclockwise then come back
        if (currentDir == -1)
            [consoleOut, currentDir] = resetJiggle(s, currentDir);
            disp(consoleOut)
        end
        [consoleOut, current_position] = craneForward(abs(posPlayer1-16), 0, s, steps_recalibration, -1);
        disp(consoleOut)
        [consoleOut] = putDown(s1, s2);
        disp(consoleOut)
        [consoleOut, current_position, currentDir] = craneReturn(-current_position, 0, s);
        disp(consoleOut)
    end

elseif (beforeMovePos2 ~= posPlayer2)
    
    if (beforeMovePos2<= 9)
        % go to pick up piece clockwise then come back
        if (currentDir == 1)
            [consoleOut, currentDir] = resetJiggle(s, currentDir);
            disp(consoleOut)
        end
        [consoleOut, current_position] = craneForward(beforeMovePos2-1, 0, s, steps_recalibration, 1);
        disp(consoleOut)
        [consoleOut] = pickUp(s1, s2);
        disp(consoleOut)
        [consoleOut, current_position, currentDir] = craneReturn(-current_position, 0, s);
        disp(consoleOut)
    
    else
        % go to pick up piece counterclockwise then come back
        if (currentDir == -1)
            [consoleOut, currentDir] = resetJiggle(s, currentDir);
            disp(consoleOut)
        end
        [consoleOut, current_position] = craneForward(abs(beforeMovePos2-16), 0, s, steps_recalibration, -1);
        disp(consoleOut)
        [consoleOut] = pickUp(s1, s2);
        disp(consoleOut)
        [consoleOut, current_position, currentDir] = craneReturn(-current_position, 0, s);
        disp(consoleOut)
    end
    

    if (posPlayer2 <= 9)
        % go to put down piece clockwise then come back 
        if (currentDir == 1)
            [consoleOut, currentDir] = resetJiggle(s, currentDir);
            disp(consoleOut)
        end
        [consoleOut, current_position] = craneForward(posPlayer2-1, 0, s, steps_recalibration, 1);
        disp(consoleOut)
        [consoleOut] = putDown(s1, s2);
        disp(consoleOut)
        [consoleOut, current_position, currentDir] = craneReturn(-current_position, 0, s);
        disp(consoleOut)
    else
        % go to put down piece counterclockwise then come back
        if (currentDir == -1)
            [consoleOut, currentDir] = resetJiggle(s, currentDir);
            disp(consoleOut)
        end
        [consoleOut, current_position] = craneForward(abs(posPlayer2-16), 0, s, steps_recalibration, -1);
        disp(consoleOut)
        [consoleOut] = putDown(s1, s2);
        disp(consoleOut)
        [consoleOut, current_position, currentDir] = craneReturn(-current_position, 0, s);
        disp(consoleOut)
    end
end

if (posPlayer1 == 2 || posPlayer2 == 2)
    [consoleOut] = dumpFar(s4);
    disp(consoleOut)
    if (posPlayer1 ~= 1 && posPlayer2 ~= 1)
        fprintf('Place your piece on space 1\n')
        if (posPlayer1 == 2)
            posPlayer1 = 1;
        else
            posPlayer2 = 1;
        end
    else
        fprintf('Place your piece on space 15\n')
        if (posPlayer1 == 2)
            posPlayer1 = 15;
        else
            posPlayer2 = 15;
        end
    end
end
if (posPlayer1 == 4 || posPlayer2 == 4)
    [consoleOut] = dumpClose(s3);
    disp(consoleOut)
    if (posPlayer1 ~= 1 && posPlayer2 ~= 1)
        fprintf('Place your piece on space 1\n')
        if (posPlayer1 == 2)
            posPlayer1 = 1;
        else
            posPlayer2 = 1;
        end
    else
        fprintf('Place your piece on space 15\n')
        if (posPlayer1 == 2)
            posPlayer1 = 15;
        else
            posPlayer2 = 15;
        end
    end
end
if (posPlayer1 == 7 || posPlayer1 == 8 || posPlayer2 == 7 || posPlayer2 == 8)
    runSwap(0, full_rotation_stepper/2, s)
    if (posPlayer1 == 7)
        posPlayer1 = 7;
    elseif (posPlayer1 == 8)
        posPlayer1 = 8;
    elseif (posPlayer2 == 7)
        posPlayer2 = 7;
    else
        posPlayer2 = 8;
    end
end


%runSwap(0, full_rotation_stepper/2, s)
%[consoleOut, current_position] = craneForward(2, 0, s, steps_recalibration, 1);
%disp(consoleOut)
%[consoleOut, current_position, currentDir] = craneReturn(-current_position, 0, s);
%disp(consoleOut)
%[consoleOut, currentDir] = resetJiggle(s, currentDir);
%disp(consoleOut)
%[consoleOut] = pickUp(s1, s2);
%disp(consoleOut)
%[consoleOut] = putDown(s1, s2);
%disp(consoleOut)
%[consoleOut] = dumpClose(s3);
%disp(consoleOut)
%[consoleOut] = dumpFar(s4);
%disp(consoleOut)
%[consoleOut] = moveALittle(s, 1);
%disp(consoleOut)


turnNum=turnNum+1;
%********************************************************************
% Check to see if one player has gotten all 4 game pieces to home
%********************************************************************
if ((ScorePlayer1==scoreGoal || ScorePlayer2==scoreGoal) || (LivesPlayer2 < 1 || LivesPlayer1 < 1))
    break
end
%*******************************************************************
end

% *********************************************************************
% Declare a winner!
% ******************************************************************
fprintf('Game Over!  Player 1 has %d goals and %d many lives left\nPlayer 2 has %d goals and %d many lives left! \n',ScorePlayer1, LivesPlayer1, ScorePlayer2, LivesPlayer2);

