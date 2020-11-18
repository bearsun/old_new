function [ old, new ] = get_wordlist( group )
%GET_WORDLIST return old/new words
% 11/14/20 by Liwei Sun

w = load('words.mat');

if group == 'A'
    old = w.a;
    new = w.b;
elseif group == 'B'
    old = w.b;
    new = w.a;
else
    error('wrong group name.');
end

end

