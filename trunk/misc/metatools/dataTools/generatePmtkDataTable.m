function generatePmtkDataTable(dataSource)
%% Generate the PMTK data table from the meta files
% The html table is stored in the dataSource directory.
% dataSource is the location of the pmtkData local copy of the svn
% repository.
% PMTKneedsMatlab 
%%
if nargin == 0
    dataSource = 'C:\pmtkData\';
end
googleRoot = ' http://pmtkdata.googlecode.com/svn/trunk';
dataSets   = dirs(dataSource);
perm       = sortidx(lower(dataSets)); % sort by name
dataSets   = dataSets(perm);
n          = numel(dataSets);
%%
colNames   = {'NAME' , 'FILESIZE (KB)', 'DESCRIPTION', 'X TYPE', 'Y TYPE',...
              'NCASES', 'NDIMS', 'SOURCE', 'CONTRIBUTED BY'};
NAME   = 1;
FSIZE  = 2; 
DESC   = 3; 
XTYPE  = 4; 
YTYPE  = 5; 
NCASES = 6; 
NDIMS  = 7;
SRC    = 8; 
CONTBY = 9;
%%
htmlData = cell(n, numel(colNames));
for ds=1:n
    dname = dataSets{ds}; 
    S = getTagStruct(dataSource, dname); 
    
    htmlData{ds, NAME}   = sprintf('<a href="%s/%s/%s.zip">%s</a>', googleRoot, dname, dname, dname); 
    htmlData{ds, FSIZE}  = fileSize(dataSource, dname); 
    htmlData{ds, DESC}   = getData(S, 'PMTKdescription'); 
    htmlData{ds, XTYPE}  = getData(S, 'PMTKtypeX');
    htmlData{ds, YTYPE}  = getData(S, 'PMTKtypeY');
    htmlData{ds, NCASES} = getData(S, 'PMTKncases');
    htmlData{ds, NDIMS}  = getData(S, 'PMTKndims');
    htmlData{ds, SRC}    = getSourceString(S, sprintf('%s/%s', googleRoot, dname));
    htmlData{ds, CONTBY} = getData(S, 'PMTKcontributedBy');
    
    if isempty(htmlData{ds, XTYPE}) && isempty(htmlData{ds, YTYPE})
        htmlData{ds, XTYPE} = getData(S, 'PMTKtype'); % backwards compatibility
    end
end
%% Generate html table
pmtkRed  = '#990000';
header = [...
    sprintf('<font align="left" style="color:%s"><h2>PMTK Data</h2></font>\n', pmtkRed),...
    sprintf('<br>Revision Date: %s<br>\n', date()),...
    sprintf('<br>Auto-generated by generatePmtkDataTable.m<br>\n'),...
    sprintf('<br>Click on the file name to download the data set.'), ...
    sprintf('<br><br><br>\n')...
    ];

colNameColors = repmat({pmtkRed}, 1, numel(colNames));
dest = fullfile(dataSource, 'dataTable.html'); 
htmlTable('data'          , htmlData       , ...
          'doshow'        , true           , ...
          'dosave'        , true           , ...
          'filename'      , dest           , ...
          'dataalign'     , 'left'         , ...
          'colnames'      , colNames       , ...
          'colNameColors' , colNameColors  , ...
          'header'        , header         );
end

function str = getSourceString(S, googlePath)
%% Deal with the source column as a special case 
% We look for both PMTKsource and PMTKcreated tags
str = {};
if isfield(S, 'PMTKsource')
    source = convertLinksToHtml(S.PMTKsource);
    if ~isempty(source)
        str = sprintf('Source: %s', source);
    end
end

if isfield(S, 'PMTKcreated')
   if ~isempty(str), str = [str, '<br>'];  end
   cstr = strtrim(S.PMTKcreated);
   if endswith(cstr, '.m')
        w = which(cstr); 
        if startswith(w, pmtk3Root()) && ~startswith(w, fullfile(pmtk3Root, 'data'))
            cstr = googleCodeLink(cstr, cstr);
        else
            cstr = convertLinksToHtml(sprintf('%s/%s', googlePath, cstr), cstr);
        end
   end
   str = [str, sprintf('Created by: %s', cstr)];
end
end

function S = getTagStruct(source, dataSet)
%% Return a struct from tags to data for the given data set
metaFile = fullfile(source, dataSet, [dataSet, '-meta.txt']);
[tags, lines] = tagfinder(metaFile);
S = createStruct(tags, lines);
end

function data = getData(S, tag)
%% Check if the tag is present, and if so, return the data
if isfield(S, tag)
    data = S.(tag);
else
    data = {};
end
end

function sz = fileSize(source, dataSet)
%% Return the size of the local data set zip file in KB as a formatted string
zip  = fullfile(source, dataSet, [dataSet, '.zip']);
info = dir(zip); 
sz = sprintf('%d', ceil(info.bytes/(1024))); 
end