import ctypes, ctypes.wintypes, time, sys

GENERIC_READ = 0x80000000
GENERIC_WRITE = 0x40000000
OPEN_EXISTING = 3
INVALID_HANDLE = ctypes.wintypes.HANDLE(-1).value
kernel32 = ctypes.WinDLL('kernel32', use_last_error=True)

handle = kernel32.CreateFileW('COM3', GENERIC_READ | GENERIC_WRITE, 0, None, OPEN_EXISTING, 0, None)
if handle == INVALID_HANDLE:
    print('Cannot open COM3'); sys.exit(1)

class DCB(ctypes.Structure):
    _fields_ = [('DCBlength',ctypes.wintypes.DWORD),('BaudRate',ctypes.wintypes.DWORD),
    ('fBinary',ctypes.wintypes.DWORD,1),('fParity',ctypes.wintypes.DWORD,1),
    ('fOutxCtsFlow',ctypes.wintypes.DWORD,1),('fOutxDsrFlow',ctypes.wintypes.DWORD,1),
    ('fDtrControl',ctypes.wintypes.DWORD,2),('fDsrSensitivity',ctypes.wintypes.DWORD,1),
    ('fTXContinueOnXoff',ctypes.wintypes.DWORD,1),('fOutX',ctypes.wintypes.DWORD,1),
    ('fInX',ctypes.wintypes.DWORD,1),('fErrorChar',ctypes.wintypes.DWORD,1),
    ('fNull',ctypes.wintypes.DWORD,1),('fRtsControl',ctypes.wintypes.DWORD,2),
    ('fAbortOnError',ctypes.wintypes.DWORD,1),('fDummy2',ctypes.wintypes.DWORD,17),
    ('wReserved',ctypes.wintypes.WORD),('XonLim',ctypes.wintypes.WORD),
    ('XoffLim',ctypes.wintypes.WORD),('ByteSize',ctypes.wintypes.BYTE),
    ('Parity',ctypes.wintypes.BYTE),('StopBits',ctypes.wintypes.BYTE),
    ('XonChar',ctypes.c_char),('XoffChar',ctypes.c_char),
    ('ErrorChar',ctypes.c_char),('EofChar',ctypes.c_char),('EvtChar',ctypes.c_char),
    ('wReserved1',ctypes.wintypes.WORD)]

dcb = DCB()
dcb.DCBlength = ctypes.sizeof(DCB)
kernel32.GetCommState(handle, ctypes.byref(dcb))
dcb.BaudRate = 115200; dcb.ByteSize = 8; dcb.Parity = 0; dcb.StopBits = 0
dcb.fDtrControl = 1; dcb.fRtsControl = 1
kernel32.SetCommState(handle, ctypes.byref(dcb))

class COMMTIMEOUTS(ctypes.Structure):
    _fields_ = [('ReadIntervalTimeout',ctypes.wintypes.DWORD),
    ('ReadTotalTimeoutMultiplier',ctypes.wintypes.DWORD),
    ('ReadTotalTimeoutConstant',ctypes.wintypes.DWORD),
    ('WriteTotalTimeoutMultiplier',ctypes.wintypes.DWORD),
    ('WriteTotalTimeoutConstant',ctypes.wintypes.DWORD)]

timeouts = COMMTIMEOUTS()
timeouts.ReadIntervalTimeout = 0xFFFFFFFF
timeouts.ReadTotalTimeoutMultiplier = 0
timeouts.ReadTotalTimeoutConstant = 0
kernel32.SetCommTimeouts(handle, ctypes.byref(timeouts))
kernel32.PurgeComm(handle, 0x000F)

print('Listening... try AUTH now')
buf = ctypes.create_string_buffer(4096)
br = ctypes.wintypes.DWORD(0)
total = b''
for i in range(150):
    ret = kernel32.ReadFile(handle, buf, 4095, ctypes.byref(br), None)
    if br.value > 0:
        chunk = buf.raw[:br.value]
        total += chunk
    time.sleep(0.2)

if total:
    print(total.decode('utf-8', errors='replace'))
else:
    print('No data')
kernel32.CloseHandle(handle)
