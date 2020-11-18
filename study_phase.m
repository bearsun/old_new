function study_phase(debug)
%STUDY_PHASE Study phase for old/new paradigm
% See Hoppstaedter et al., 2015, NeuroImage
% 11/9/20 by Liwei Sun

ntriggers = 31; % how many TRs per volume
imouse = 12; % double check with GetMouseIndices
possiblekn = [1,3];

clc;
AssertOpenGL;
Priority(1);

global ptb_RootPath %#ok<NUSED>
global ptb_ConfigPath %#ok<NUSED>

rng('shuffle');
sid = 0;
srect = [0 0 801 601];
fixpi = 6;

white = [255 255 255];
black = [0 0 0];
fixcolor = white;
textcolor = white;
bgcolor = black;

subj = input('subject?', 's');
group = input('group? (A/B)', 's');

path_data = [pwd, '/data/data-', subj, '-', group, '-study'];
outfile = fopen(path_data, 'w');
fprintf(outfile, '%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\n', ...
    'subject', 'group', 'trial', 'word', 'trial_onset', 'jitter', ...
    'text_onset', 'pleasant', 'rt');

% MR parameters
tr = 0;
pretr = 5 * ntriggers; % wait 5 TRs for BOLD to be stable
if debug
    BUFFER = [];
    fRead = @() ReadFakeTrigger;
    tr_tmr = timer('TimerFcn', @SetTrigger, 'Period', 2, ...
        'ExecutionMode', 'fixedDelay', 'Name', 'tr_timer');
else
    tbeginning = NaN;
    trigger = 57; %GE scanner with MR Technology Inc. trigger box
    IOPort('Closeall');
    P4 = getport;
    fRead = @() ReadScanner;
end

[mainwin, rect] = Screen('OpenWindow', sid, bgcolor, srect);
Screen('TextFont', mainwin, 'Simsun'); % font to show Chinese
fixRect = CenterRect([0 0 fixpi fixpi], rect);
% Screen('FillRect', mainwin, fixcolor, fixRect);

[old_words, ~] = get_wordlist(group);
% old_words = arrayfun(@(d) num2str(d), (1:100)', 'uni', 0);
ntrials = numel(old_words);
seq = Shuffle(old_words);

tprefix = 1;
vtjitters = .5:.25:1.5;
tjitters = Shuffle(repmat(vtjitters, 1, ntrials/numel(vtjitters))');
ttar = 2;
tpost = .5;

pretext = '请准备';
DrawFormattedText(mainwin, double(pretext), 'center', 'center', textcolor);
Screen('Flip', mainwin);

if debug
    start(tr_tmr)
    tbeginning = GetSecs;
end

TRWait(pretr);

start_time = GetSecs;
for itrial = 1:ntrials
    Screen('FillRect', mainwin, fixcolor, fixRect);
    [~, trial_onset] = Screen('Flip', mainwin);
    WaitSecs(tprefix);
    
    Screen('Flip', mainwin);
    WaitSecs(tjitters(itrial));
    
    DrawFormattedText(mainwin, double(seq{itrial}), 'center', 'center', ...
        textcolor);
    [~, text_onset] = Screen('Flip', mainwin);
    
    keypressed = NaN;
    rt = NaN;
    timelapse = 0;
    while isnan(rt) && timelapse < ttar
        [keyIsDown, timeSecs, keyCode] = KbCheck(imouse);
        if keyIsDown
            if sum(keyCode) == 1
                if any(keyCode(possiblekn))
                    keypressed = find(keyCode);
                    rt = timeSecs - text_onset;
                end
            end
        end
        timelapse = timeSecs - text_onset;
    end
    WaitSecs(ttar-timelapse);
    
    Screen('Flip', mainwin);
    WaitSecs(tpost);
    
    fprintf(outfile, '%s\t %s\t %d\t %s\t %d\t %d\t %d\t %d\t %d\n', ...
        subj, group, itrial, seq{itrial}, trial_onset-start_time, ...
        tjitters(itrial), text_onset-start_time, keypressed, rt);
end

WaitSecs(6);
fprintf(outfile, '%s:\t %f\t %s:\t %f\t', 'TR1', tbeginning, 'Trial1', ...
    start_time);
fclose(outfile);
if debug
    StopTimer;
else
    IOPort('Closeall');
end
sca;

    function [data, when] = ReadScanner
        [data, when] = IOPort('Read', P4);
        
        if ~isempty(data)
            fprintf('data: %d\n', data);
            tr = tr + sum(data == trigger);
            if tr == 1
                tbeginning = when;
            end
            fprintf('%d\t %d\n', when-tbeginning, tr);
        end
    end

    function TRWait(t)
        while t > tr
            fRead();
            WaitSecs(.01);
        end
    end

    function [data, when] = ReadFakeTrigger
        data = BUFFER;
        BUFFER = [];
%         [~, ~, kDown] = KbCheck;
%         b = logical(kDown(BUTTONS));
%         BUFFER = [BUFFER CODES(b)];
        when = GetSecs;
    end

    function SetTrigger(varargin)
        tr = tr + 1;
        fprintf('TR TRIGGER %d\n', tr);
        BUFFER = [BUFFER 53];
    end

    function StopTimer
        if isobject(tr_tmr) && isvalid(tr_tmr)
            if strcmpi(tr_tmr.Running, 'on')
                stop(tr_tmr);
            end
            delete(tr_tmr);
        end
    end
end

