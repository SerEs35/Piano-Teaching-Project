
%The idea is to convert the signed range [-32768,32767] to an
%usigned range [0 , 65535] by "adding" 32768 to the signed range.

%To perform the operation, first convert the int16 to uint16, 
%and then apply a XOR operation with 32768 as argument into the
%unsigned range [32768, 32767]. 
%This will yield the [0 , 65535] range...

%Load each *.wav file in the following order.
%var2: stores the sampled data as signed 16 bit [-32768,32767]
%Gs:   is the sampling rate at 16KHz
%m:    converts the "var2" as an unsigned 16 bit variable 
%      with range [32768,...65535,0,1,...32767]
%n:    xor 32768 on 'm'
%'A3': converts the uint16 'n' array into two uint8 bytes per sample

[var2,Gs] = audioread('audio_samples\A3.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

A3 = typecast(n,'uint8');

% A3:  (low, high); (low,high);...
% A3: 98.112 KB
%.....................................

[var2,Gs] = audioread('audio_samples\A4.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

A4 = typecast(n,'uint8');

%A4: 83.198 KB
%.....................................

[var2,Gs] = audioread('audio_samples\B3.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

B3 = typecast(n,'uint8');

%B3: 95.998 KB
%.....................................

[var2,Gs] = audioread('audio_samples\B4.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

B4 = typecast(n,'uint8');

%B4: 83.198 KB
%.....................................

[var2,Gs] = audioread('audio_samples\C3.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

C3 = typecast(n,'uint8');

%C3: 116.488 KB
%.....................................

[var2,Gs] = audioread('audio_samples\C4.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

C4 = typecast(n,'uint8');

%C4: 108.798 KB
%.....................................

[var2,Gs] = audioread('audio_samples\C5.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

C5 = typecast(n,'uint8');

%C5: 76.798 KB
%.....................................

[var2,Gs] = audioread('audio_samples\D3.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

D3 = typecast(n,'uint8');

%D3: 127.100 KB
%.....................................

[var2,Gs] = audioread('audio_samples\D4.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

D4 = typecast(n,'uint8');

%D4: 95.998 KB
%.....................................

[var2,Gs] = audioread('audio_samples\E3.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

E3 = typecast(n,'uint8');

%E3: 108.798 KB
%.....................................

[var2,Gs] = audioread('audio_samples\E4.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

E4 = typecast(n,'uint8');

%E4: 83.198 KB
%.....................................

[var2,Gs] = audioread('audio_samples\F3.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

F3 = typecast(n,'uint8');

%F3: 115.198 KB
%.....................................

[var2,Gs] = audioread('audio_samples\F4.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

F4 = typecast(n,'uint8');

%F4: 86.208 KB
%.....................................

[var2,Gs] = audioread('audio_samples\G3.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

G3 = typecast(n,'uint8');

%G3: 115.990 KB
%.....................................

[var2,Gs] = audioread('audio_samples\G4.wav','native');   

m = typecast(var2,'uint16');    %dont touch
n = bitxor(m,32768) ;           %dont touch

G4 = typecast(n,'uint8');

%G4: 83.198 KB
%.....................................

%concatenate the audio data...
data = cat(1,A3,A4,B3,B4,C3,C4,C5,D3,D4,E3,E4,F3,F4,G3,G4);

t = length(data);  %size of concatenated audio data
i = uint32(1);     %iterator

%By this time, the microcontroller is on stand-by.
%When any key is pressed, the microcontroller will start the 
%reading sequence as soon as it reads the 'Start' bit of the 
%Serial Protocol...

 pause();      
 
 %Serial Port COM setup.
 s = serial('COM5');   
 set(s,'BaudRate',19200,'Databits',8,'ByteOrder','littleEndian');
 fopen(s);
 
 tic       % just for debugging
 
  while (i < t)
      
   fwrite(s,data(i));   %low byte
   sprintf('i:%d   D = %d ',i,data(i))   %print out into console
   i=i+1;
   mydelay();   %custom delay of around +75 us

  end
 
 toc       % just for debugging
 
 %Close port and clear link..
 fclose(s);
 delete(s);
 clear s;

%data: 1,478.278 KB
%;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%       from        to
%A3:    0           98,111
%A4:    98,112      181,309
%B3:    181,310     277,308
%B4:    277,309     360,505
%C3:    360,506     476,993
%C4:    476,994     585,791
%C5:    585,792     662,589
%D3:    662,590     789,689
%D4:    789,690     885,687
%E3:    885,688     994,485
%E4:    994,486     1,077,683
%F3:    1,077,684   1,192,881
%F4:    1,192,882   1,279,089
%G3:    1,279,090   1,395,079
%G4:    1,395,080   1,478,277
%
%
%;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
