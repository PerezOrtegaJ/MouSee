function resultFlag = IsWin(is64)

% resultFlag = IsWin([is64=0])
%
% Return true if the operating system is Windows.
% If optional 'is64' flag is set to one, returns
% true if the runtime is 64 bit and on Windows.
% 
% See also: IsOSX, IsLinux, OSName, computer

% HISTORY
% ??/??/?? awi Wrote it.
% 6/30/06  awi Fixed help section.
% 6/13/12   dn Added support for 64bit and on windows query
% 10/16/15  mk Add support for 64-Bit Octave on Windows.

persistent rc;
persistent rc64;

% check input
if nargin < 1 || isempty(is64)
     is64 = 0;
end

if isempty(rc)
     rc=streq(computer,'PCWIN') || streq(computer,'PCWIN64') || ~isempty(strfind(computer, 'mingw32'));
end

if isempty(rc64)
     rc64 = rc && (~isempty(strfind(computer, 'x86_64')) || streq(computer,'PCWIN64'));
end

if is64 == 0
     resultFlag = rc;
else
     resultFlag = rc64;
end
