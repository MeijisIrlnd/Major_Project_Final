;String conversion
opcode inttostring, S, k
kValue xin
SnewString sprintfk "%d", kValue
xout SnewString
endop

opcode floattostring, S, k
kValue xin
SnewString sprintfk "%f", kValue
xout SnewString
endop

; <T>to String: 
; Convert an int or a float to a string, opcode automatically determines whether it's an int or a float. 
; If you want to use an i value, typecast to k before using the opcode. 
; NB: Need Python 2.7 and to run pyinit from the csd calling this opcode. 
; USAGE Sstring ttostr kValue


