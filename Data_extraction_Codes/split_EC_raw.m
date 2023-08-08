function split_ec_raw(site,freq,indir,outdir,filename)
% author: Christiaan van der Tol (c.vandertol@utwente.nl)
% date: 4 April 2019
% this code splits large EC raw data files (TOA5 of a CS datalogger) into
% chuncks that can be handled by EddyPro, and stores these on the server.
% These files (data\1_raw\ec\split) may be removed after a while: They are
% bulky and can be regenerated from the 7z files in data\1_raw\ec.
%
% update 6 August 2019 (CT): deletes the input file after it did the job.
%                            deletes older split files.


if nargin<4
    site = 'speuld';        % name of the measurement site
    freq = 20;              % Hz, frequency of the measurements
    indir = 'C:\Users\Ashutosh Umale\Documents\Syllabus Q4\In-Situ Measurements\Assignment\Evaporation\EDDYCOVARIANCE\';
    outdir = 'C:\Users\Ashutosh Umale\Documents\Syllabus Q4\In-Situ Measurements\Assignment\Evaporation\';
    filename = 'SP_ECData*.dat';
    %outdir = '\\file-itc-wrs.utsp.utwente.nl\group\Siteswrs\speuld\data\1_raw\ec\split\';
    % location of the input and output files
end

%outdirfiles = dir([outdir '*.raw' ]);
% for k = 1:length(outdirfiles)-1
%    delete([outdir outdirfiles(k).name])
% end      

filelength = 1800*freq; % length of the 30-min files
outfilename = 'dummy'; 
files = dir([indir '\' filename]);

for fileno = 1:length(files)
    
    infile = files(fileno).name
    lineno = 0;
    fid = fopen([indir infile],'r');
    for k = 1:4
        fgetl(fid);
    end
    while ~feof(fid)
        Oneline = fgetl(fid);
        Oneline = strrep(Oneline,'"','');
        d = textscan(Oneline,'%s%d%c%d%c%f%c%c%d%c%f%c%f%c%f%c%f%c%f%c%f%c%f%c%f\n');
        
        if ~isempty(d{11}) && ~isempty(d{23})
            Datestr = char(d{1});
            outfilename_new = [outdir Datestr '_' sprintf('%02d',d{2}) sprintf('%02d',30*floor(single(d{4})/30)) '_' site '.raw' ];
            if ~strcmp(outfilename_new,outfilename)
                if ~strcmp(outfilename,'dummy')
                    dlmwrite(outfilename,dout,'delimiter','\t','precision',6)
                end
                outfilename = outfilename_new;
                if exist(outfilename_new,'file')
                    outfilename_new
                    dout = load(outfilename_new);
                   
                else
                    dout = -6999*ones(filelength,6);
                end
            end
            I = freq*mod(d{4},30)*60+freq*d{6}+1;
            
            switch site
                case 'speuld'
                    dout(I,:) = [d{11} d{13} d{15} d{17} d{21} d{23}];
                    lineno = lineno+1;
                case 'enschede'
                    dout(I,:) = [d{13} d{15} d{17} d{19} d{23} d{25}];
            end
        end
        
    end
    fclose(fid);
    dlmwrite(outfilename,dout,'delimiter','\t','precision',6)
    delete ([indir '\' infile]);
end


%exit