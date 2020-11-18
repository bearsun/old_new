function test_phase(debug)
%TEST_PHASE Test phase for old/new paradigm
% See Hoppstaedter et al., 2015, NeuroImage
% debug: 1, keyboard input for debugging
%        0, fMRI run with button box input
% 11/10/20 by Liwei Sun

ntriggers = 31; % how many TRs per volume
imouse = 12; % double check with GetMouseIndices
possiblekn1 = [1,3];
possiblekn2 = 1:3;

clc;
AssertOpenGL;
Priority(1);

global ptb_RootPath %#ok<NUSED>
global ptb_ConfigPath %#ok<NUSED>

subj = input('subject?', 's');
group = input('group? (A/B)', 's');
run = input('run?');

if run == 1
    [old_words, new_words] = get_wordlist(group);
%     old_words = arrayfun(@(d) num2str(d), (1:100)', 'uni', 0);
%     new_words = arrayfun(@(d) num2str(d), (101:200)', 'uni', 0);
    nold = numel(old_words);
    nnew = numel(new_words);
    wordlist = [old_words; new_words];
    nwords = nold + nnew;
    % build a hashtable here
    seqlist = [1:nwords;
        ones(1, numel(old_words)), zeros(1, numel(new_words));]';
    seq = Shuffle(seqlist, 2);

%     bpass = 0;
%     while ~bpass
%         seq = Shuffle(seqlist, 2);
%         bpass = check_rep(seq);
%     end
    
    % first col of seq contains the index of the word in wordlist
    % second col of seq contains bool whethter it is an old word
    trial_start = 1;
    trial_end = floor(nwords/2);
    save([pwd, '/subjs/', subj, '.mat'], 'seq', 'wordlist', ...
        'nwords', 'trial_end');
elseif run == 2
    info = load([pwd, '/subjs/', subj, '.mat']);
    wordlist = info.wordlist;
    seq = info.seq;
    trial_start = info.trial_end + 1;
    trial_end = info.nwords;
else
    error('Wrong run number.');
end

path_data = [pwd, '/data/data-', subj, '-', group, '-test-', ...
    num2str(run)];
outfile = fopen(path_data, 'w');
fprintf(outfile, ...
    '%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\n', ...
    'subject', 'group', 'run', 'trial', 'word', 'trial_onset', ...
    'jitter', 'text_onset', 'old', 'tar_resp', 'tar_rt',...
    'conf_resp', 'conf_rt');

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

rng('shuffle');
sid = 0;
srect = [0 0 801 601];
fixpi = 6;

white = [255 255 255];
black = [0 0 0];
fixcolor = white;
textcolor = white;
bgcolor = black;

ntrials = trial_end - trial_start + 1;
tprefix = 1;
vtjitters = .5:.25:1.5;
tjitters = Shuffle(repmat(vtjitters, 1, ntrials/numel(vtjitters))');
ttar = 2;
tpost = .5;
tconf = 3;

[mainwin, rect] = Screen('OpenWindow', sid, bgcolor, srect);
Screen('TextFont', mainwin, 'Simsun'); % font to show Chinese
fixRect = CenterRect([0 0 fixpi fixpi], rect);
% Screen('FillRect', mainwin, fixcolor, fixRect);


pretext = double('请准备');
DrawFormattedText(mainwin, double(pretext), 'center', 'center', textcolor);
Screen('Flip', mainwin);

if debug
    start(tr_tmr);
    tbeginning = GetSecs;
end

ncor = 0;

TRWait(pretr);
start_time = GetSecs;
for itrial = trial_start:trial_end
    Screen('FillRect', mainwin, fixcolor, fixRect);
    [~, trial_onset] = Screen('Flip', mainwin);
    WaitSecs(tprefix);
    
    Screen('Flip', mainwin);
    jitter = tjitters(itrial-trial_start+1);
    WaitSecs(jitter);
    
    iword = seq(itrial, 1);
    bold = seq(itrial, 2);
    DrawFormattedText(mainwin, double(wordlist{iword}), 'center', 'center', ...
        textcolor);
    [~, text_onset] = Screen('Flip', mainwin);
    
    keypressed1 = NaN;
    rt1 = NaN;
    timelapse = 0;
    while isnan(rt1) && timelapse < ttar
        [keyIsDown, timeSecs, keyCode] = KbCheck(imouse);
        if keyIsDown
            if sum(keyCode) == 1
                if any(keyCode(possiblekn1))
                    keypressed1 = find(keyCode);
                    rt1 = timeSecs - text_onset;
                end
            end
        end
        timelapse = timeSecs - text_onset;
    end
    WaitSecs(ttar-timelapse);
    
    Screen('Flip', mainwin);
    WaitSecs(tpost);
    
    DrawFormattedText(mainwin, double('你有多确定?'), 'center', 'center', ...
        textcolor);
    [~, conf_onset] = Screen('Flip', mainwin);
    
    keypressed2 = NaN;
    rt2 = NaN;
    timelapse = 0;
    while isnan(rt2) && timelapse < tconf
        [keyIsDown, timeSecs, keyCode] = KbCheck(imouse);
        if keyIsDown
            if sum(keyCode) == 1
                if any(keyCode(possiblekn2))
                    keypressed2 = find(keyCode);
                    rt2 = timeSecs - conf_onset;
                end
            end
        end
        timelapse = timeSecs - conf_onset;
    end
    WaitSecs(tconf-timelapse);
    
    Screen('Flip', mainwin);
    WaitSecs(tpost);
    
    fprintf(outfile, ...
        '%s\t %s\t %d\t %d\t %s\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\n', ...
        subj, group, run, itrial, wordlist{iword}, ...
        trial_onset - start_time, jitter, text_onset - start_time, ...
        bold, keypressed1, rt1, keypressed2, rt2);
    
    if (bold == 1 && keypressed1 == 1) || (bold == 0 && keypressed1 == 3)
        ncor = ncor + 1;
    end
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
disp(ncor/ntrials);

    function b = check_rep(seq)
        b = 1;
        s = seq(:, 2);
        cnt = 0;
        for i = 2:numel(s)
            if s(i) == s(i-1)
                cnt = cnt + 1;
                if cnt == 2
                    b = 0;
                    return
                end
            else
                cnt = 0;
            end
        end
    end
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