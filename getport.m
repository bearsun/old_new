function P4 = getport
%GETPORT Summary of this function goes here
%   Detailed explanation goes here
P4 = IOPort('OpenSerialPort', ...
        '/dev/serial/by-path/pci-0000:00:14.0-usb-0:3:1.0', 'BaudRate=9600');
end

