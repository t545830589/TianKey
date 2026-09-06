import ctypes
import ctypes.wintypes
import time
import sys

GENERIC_READ = 0x80000000
GENERIC_WRITE = 0x40000000
OPEN_EXISTING = 3
INVALID_HANDLE = ctypes.wintypes.HANDLE(-1).value

kernel32 = ctypes.WinDLL('kernel32', use_last_error=True)

handle = kernel32.CreateFileW(
    'COM3',
    GENERIC_READ | GENERIC_WRITE,
    0,
    None,
    OPEN_EXISTING,
    0,
    None
)

if handle == INVALID_HANDLE:
    print("Failed to open COM3")
    sys.exit(1)

print(f"COM3 opened, handle={handle}")

# Set baud rate
DCB = ctypes.Structure
class DCB(ctypes.Structure):
    _fields_ = [
        ('DCBlength', ctypes.wintypes.DWORD),
        ('BaudRate', ctypes.wintypes.DWORD),
        ('fBinary', ctypes.wintypes.DWORD, 1),
        ('fParity', ctypes.wintypes.DWORD, 1),
        ('fOutxCtsFlow', ctypes.wintypes.DWORD, 1),
        ('fOutxDsrFlow', ctypes.wintypes.DWORD, 1),
        ('fDtrControl', ctypes.wintypes.DWORD, 2),
        ('fDsrSensitivity', ctypes.wintypes.DWORD, 1),
        ('fTXContinueOnXoff', ctypes.wintypes.DWORD, 1),
        ('fOutX', ctypes.wintypes.DWORD, 1),
        ('fInX', ctypes.wintypes.DWORD, 1),
        ('fErrorChar', ctypes.wintypes.DWORD, 1),
        ('fNull', ctypes.wintypes.DWORD, 1),
        ('fRtsControl', ctypes.wintypes.DWORD, 2),
        ('fAbortOnError', ctypes.wintypes.DWORD, 1),
        ('fDummy2', ctypes.wintypes.DWORD, 17),
        ('wReserved', ctypes.wintypes.WORD),
        ('XonLim', ctypes.wintypes.WORD),
        ('XoffLim', ctypes.wintypes.WORD),
        ('ByteSize', ctypes.wintypes.BYTE),
        ('Parity', ctypes.wintypes.BYTE),
        ('StopBits', ctypes.wintypes.BYTE),
        ('XonChar', ctypes.c_char),
        ('XoffChar', ctypes.c_char),
        ('ErrorChar', ctypes.c_char),
        ('EofChar', ctypes.c_char),
        ('EvtChar', ctypes.c_char),
        ('wReserved1', ctypes.wintypes.WORD),
    ]

dcb = DCB()
dcb.DCBlength = ctypes.sizeof(DCB)

# GetCommState
ret = kernel32.GetCommState(handle, ctypes.byref(dcb))
print(f"GetCommState: {ret}, BaudRate={dcb.BaudRate}")

# Set 115200
dcb.BaudRate = 115200
dcb.ByteSize = 8
dcb.Parity = 0
dcb.StopBits = 0
dcb.fDtrControl = 1  # DTR_ENABLE
dcb.fRtsControl = 1  # RTS_ENABLE
ret = kernel32.SetCommState(handle, ctypes.byref(dcb))
print(f"SetCommState: {ret}")

# Set timeouts - return immediately
class COMMTIMEOUTS(ctypes.Structure):
    _fields_ = [
        ('ReadIntervalTimeout', ctypes.wintypes.DWORD),
        ('ReadTotalTimeoutMultiplier', ctypes.wintypes.DWORD),
        ('ReadTotalTimeoutConstant', ctypes.wintypes.DWORD),
        ('WriteTotalTimeoutMultiplier', ctypes.wintypes.DWORD),
        ('WriteTotalTimeoutConstant', ctypes.wintypes.DWORD),
    ]

timeouts = COMMTIMEOUTS()
timeouts.ReadIntervalTimeout = 0xFFFFFFFF
timeouts.ReadTotalTimeoutMultiplier = 0
timeouts.ReadTotalTimeoutConstant = 0
ret = kernel32.SetCommTimeouts(handle, ctypes.byref(timeouts))
print(f"SetCommTimeouts: {ret}")

# Purge any existing data
kernel32.PurgeComm(handle, 0x000F)  # PURGE_TXABORT|RXABORT|TXCLEAR|RXCLEAR

# Toggle DTR to reset ESP32
print("Toggling DTR for reset...")
kernel32.EscapeCommFunction(handle, 5)  # SETDTR
time.sleep(0.1)
kernel32.EscapeCommFunction(handle, 6)  # CLRDTR
time.sleep(0.1)
kernel32.EscapeCommFunction(handle, 5)  # SETDTR
print("Waiting 8 seconds for ESP32 to boot...")
time.sleep(8)

# Read
buf = ctypes.create_string_buffer(4096)
bytes_read = ctypes.wintypes.DWORD(0)

total_data = b''
for i in range(20):
    ret = kernel32.ReadFile(handle, buf, 4095, ctypes.byref(bytes_read), None)
    if bytes_read.value > 0:
        total_data += buf.raw[:bytes_read.value]
    time.sleep(0.2)

if total_data:
    print(f"\n=== Got {len(total_data)} bytes ===")
    try:
        print(total_data.decode('utf-8', errors='replace'))
    except:
        print(repr(total_data))
else:
    print("\n=== No data received ===")

kernel32.CloseHandle(handle)
