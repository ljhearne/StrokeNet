function [data, key, P_ID] = load_stroke_behav

% read in spreadsheet of stroke behavioural data.
HARDPATH = '/scratch/sw49/';
[NUM,TXT,RAW]=xlsread([HARDPATH,'Stroke_Lucy_030817_edit.xlsx']);

key=TXT(1,:); % list of what each behavioural variable is
P_ID=TXT(2:end,1); % participant IDs

data=NUM(1:length(P_ID),:);
end
