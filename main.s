require lib/sys/sys.s

requireend lib/curses/curses.s
requireend lib/std/io/fput.s
requireend lib/std/io/fputdec.s
requireend lib/std/proc/exit.s
requireend lib/std/proc/getabspath.s
requireend lib/std/str/strtoint.s

db usageStr 'Usage: editor FILE\n',0
db badFileStr 'Bad file path\n',0
db couldNotOpenFileStr 'Could not open file\n',0

ab fileFd 1
ab filePath PathMax

const lineBufferSize 81 ; width of terminal plus one - space for full length line plus null terminator
ab lineBuffer lineBufferSize

; Interrupt handlers (must be in first 256 bytes)
jmp start

label suicideHandler
jmp quit

label start

; Set fd to invalid before registering suicide handler so we do not close a random fd
mov r0 fileFd
mov r1 0
store8 r0 r1

; Register interrupt handlers
mov r0 SyscallIdRegisterSignalHandler
mov r1 SignalIdSuicide
mov r2 suicideHandler
syscall

; Check argument count
mov r0 SyscallIdArgc
syscall
mov r1 2
cmp r0 r0 r1
skipeq r0
jmp usage

; Grab file name
mov r0 SyscallIdArgvN
mov r1 1
mov r2 lineBuffer ; note: we use lineBuffer for now as a scratch buffer for getabspath call
mov r3 PathMax
syscall

cmp r0 r0 r0
skipneqz r0
jmp badFile

; Ensure path is absolute
mov r0 filePath
mov r1 lineBuffer
call getabspath

; If file does not exist then create it
; TODO: this

; Attempt to open file
mov r0 SyscallIdOpen
mov r1 filePath
syscall

cmp r1 r0 r0
skipneqz r1
jmp couldNotOpenFile

mov r1 fileFd
store8 r1 r0

; Setup display
mov r0 0
call cursesSetEcho
call cursesClearScreen

; TODO: rest of program

; Quit
label quit
; Close file
mov r0 SyscallIdClose
mov r1 fileFd
load8 r1 r1
cmp r2 r1 r1
skipeqz r2
syscall
; Reset display
mov r0 1
call cursesSetEcho
call cursesReset

; Exit
mov r0 0
call exit

; Print usage str and exit
label usage
mov r0 usageStr
call puts0
mov r0 1
call exit

; Empty file argument (might not even be possible but just to be safe)
label badFile
mov r0 badFileStr
call puts0
mov r0 1
call exit

; Could not open file error
label couldNotOpenFile
mov r0 couldNotOpenFileStr
call puts0
mov r0 1
call exit
