function create_tanner
% creates Tanner.mat, a metadata file reference
% Tanner.mat contains:
%
%  Counties -   list of county codes and names
%  Methods -    list of disposal method codes and descriptions
%  WasteCodes - list of waste codes and descriptions

disp('Creating Tanner.mat from basic files')
error('This function clobbers Methods_old ! ')

cf=check_file('County.txt');
Counties=read_dat(cf,',',{'n','qs','qs'});
Counties=moddata(Counties,'CNTY_NAME',@deblank);

mf=check_file('Method_.txt');
Methods=read_dat(mf,',',{'qs','qs','qs'});
Methods=moddata(Methods,'METH_DESC',@deblank);

wf=check_file('WasteC_.txt');
WasteCodes=read_dat(wf,',',{'qs','qs'});
WasteCodes=moddata(WasteCodes,'CAT_DESC',@deblank);

manifest_read={'qs','qn','qs','qn','','','qs','qs','qn'};
manifest_write={'%s','%8d','%s','%8d','%d','%s','%f'};

save Tanner.mat Counties Methods WasteCodes manifest_read manifest_write
