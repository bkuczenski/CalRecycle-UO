%function repair_Facilities(varargin)
% function repair_Facilities(varargin)
% 
% pull out records that have single-word facility names to undo a 'truncate first
% and last' error due to poor planning with csv conventions.  Only needed to be
% done for years 2010-2009-2008 because the problem was caught by 2007.
%
% cycle through directories (sloppily)
% find records which (1) are in FACILITIES and (2) don't have spaces
%
% accumulate a list of these in 'fspace'
%
% overwrite the bad entries in Facilities with those in fspace.

global Facilities
global FACILITIES
load Facilities
pwd
fspace=filter(Facilities,{'FAC_NAME'},{@regexp},{' '},1)
fspace=mvfield(fspace,'FAC_NAME','AC_NAM')
fspace=rmfield(fspace,'FAC_STR1')
fspace=rmfield(fspace,'FAC_CITY')
fspace=rmfield(fspace,'FAC_CNTY')
fspace=rmfield(fspace,'FAC_ST')
fspace=rmfield(fspace,'FAC_ZIP')

cd Tanner2010_9_22_2011/
fn='Facilities_.csv';
fac2010read={'s','s','s','','s','s','s','s',''};
F=read_dat(fn,',',fac2010read,struct('Field',{'GEN_EPA_ID','FAC_NAME'},'Test', ...
                                     {@FACILITY_lookup,@regexp},'Pattern',{'',' '},'Inv',{0,1}))

show(F(1:10))

fspace=vlookup(fspace,'GEN_EPA_ID',F,'GEN_EPA_ID','FAC_NAME')
show(fspace(1:24))

fspace=mvfield(fspace,'FAC_NAME','FAC_NAME_10')

fn='FACILITY_LIST_.csv';

fac2009read={'','s','s','s','s','s','s','s',''};

cd ../Tanner2009
F=read_dat(fn,',',fac2009read,struct('Field',{'GEN_EPA_ID','FAC_NAME'},'Test', ...
                                     {@FACILITY_lookup,@regexp},'Pattern',{'',' '},'Inv',{0,1}))

fspace=vlookup(fspace,'FAC_NAME_10',F,'GEN_EPA_ID','FAC_NAME')
show(fspace(1:34))
fspace=mvfield(fspace,'FAC_NAME','FAC_NAME_09')
cd ..
cd Tanner2008/

fn='Facility_.csv';
fac2008read={'s','s','s','s','s','s','s',''};
F8=read_dat(fn,',',fac2008read,struct('Field',{'GEN_EPA_ID','FAC_NAME'},'Test',{@FACILITY_lookup,@regexp},'Pattern',{'',' '},'Inv',{0,1}))
fspace
fspace=vlookup(fspace,'FAC_NAME_09',F8,'GEN_EPA_ID','FAC_NAME')
show(fspace(1:34))
fspace=filter(fspace,'FAC_NAME',{@regexp},'^[A-Z]{2}[A-Z0-9][0-9]{9}$',1)
fspace=mvfield(fspace,'FAC_NAME','FFAC_NAMEE')
fspace=flookup(fspace,'GEN_EPA_ID')
show(fspace(1:40))

M=[fspace(:).FAC_INDEX];
[Facilities(M).FAC_NAME]=fspace(:).FFAC_NAMEE
show(Facilities(M(1:10)))
M(1:10)
show(Facilities(40:45))
pwd
cd ..
save Facilities FACILITIES Facilities

