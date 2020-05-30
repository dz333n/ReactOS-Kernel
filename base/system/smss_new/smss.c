#include <stdio.h>

#define WIN32_NO_STATUS
#include <windef.h>
#include <winbase.h>
#include <ntddkbd.h>

#define NTOS_MODE_USER
#include <ndk/exfuncs.h>
#include <ndk/kefuncs.h>
#include <ndk/iofuncs.h>
#include <ndk/obfuncs.h>
#include <ndk/psfuncs.h>
#include <ndk/rtlfuncs.h>

static INT
PrintString(char* fmt,...)
{
    INT Len;
    char buffer[512];
    va_list ap;
    UNICODE_STRING UnicodeString;
    ANSI_STRING AnsiString;

    va_start(ap, fmt);
    Len = vsprintf(buffer, fmt, ap);
    va_end(ap);

    RtlInitAnsiString(&AnsiString, buffer);
    RtlAnsiStringToUnicodeString(&UnicodeString,
                                 &AnsiString,
                                 TRUE);
    NtDisplayString(&UnicodeString);
    RtlFreeUnicodeString(&UnicodeString);

    return Len;
}

static VOID
EraseLine(
    IN INT LineLength)
{
    INT Len;
    UNICODE_STRING UnicodeString;
    WCHAR buffer[512];

    if (LineLength <= 0)
        return;

    /* Go to the beginning of the line */
    RtlInitUnicodeString(&UnicodeString, L"\r");
    NtDisplayString(&UnicodeString);

    /* Fill the buffer chunk with spaces */
    Len = min(LineLength, ARRAYSIZE(buffer));
    while (Len > 0) buffer[--Len] = L' ';

    RtlInitEmptyUnicodeString(&UnicodeString, buffer, sizeof(buffer));
    while (LineLength > 0)
    {
        /* Display the buffer */
        Len = min(LineLength, ARRAYSIZE(buffer));
        LineLength -= Len;
        UnicodeString.Length = Len * sizeof(WCHAR);
        NtDisplayString(&UnicodeString);
    }

    /* Go to the beginning of the line */
    RtlInitUnicodeString(&UnicodeString, L"\r");
    NtDisplayString(&UnicodeString);
}

static NTSTATUS
OpenKeyboard(
    OUT PHANDLE KeyboardHandle)
{
    OBJECT_ATTRIBUTES ObjectAttributes;
    IO_STATUS_BLOCK IoStatusBlock;
    UNICODE_STRING KeyboardName = RTL_CONSTANT_STRING(L"\\Device\\KeyboardClass0");

    /* Just open the class driver */
    InitializeObjectAttributes(&ObjectAttributes,
                               &KeyboardName,
                               0,
                               NULL,
                               NULL);
    return NtOpenFile(KeyboardHandle,
                      FILE_ALL_ACCESS,
                      &ObjectAttributes,
                      &IoStatusBlock,
                      FILE_OPEN,
                      0);
}

static NTSTATUS
WaitForKeyboard(
    IN HANDLE KeyboardHandle,
    IN LONG TimeOut)
{
    NTSTATUS Status;
    IO_STATUS_BLOCK IoStatusBlock;
    LARGE_INTEGER Offset, Timeout;
    KEYBOARD_INPUT_DATA InputData;
    INT Len = 0;

    /* Skip the wait if there is no timeout */
    if (TimeOut <= 0)
        return STATUS_TIMEOUT;

    /* Attempt to read a down key-press from the keyboard */
    do
    {
        Offset.QuadPart = 0;
        Status = NtReadFile(KeyboardHandle,
                            NULL,
                            NULL,
                            NULL,
                            &IoStatusBlock,
                            &InputData,
                            sizeof(KEYBOARD_INPUT_DATA),
                            &Offset,
                            NULL);
        if (!NT_SUCCESS(Status))
        {
            /* Something failed, bail out */
            return Status;
        }
        if ((Status != STATUS_PENDING) && !(InputData.Flags & KEY_BREAK))
        {
            /* We have a down key-press, return */
            return Status;
        }
    } while (Status != STATUS_PENDING);

    /* Perform the countdown of TimeOut seconds */
    Status = STATUS_TIMEOUT;
    while (TimeOut > 0)
    {
        /*
         * Display the countdown string.
         * Note that we only do a carriage return to go back to the
         * beginning of the line to possibly erase it. Note also that
         * we display a trailing space to erase any last character
         * when the string length decreases.
         */
        Len = PrintString("Wait %d second(s) or press any key to exit. \r", TimeOut);

        /* Decrease the countdown */
        --TimeOut;

        /* Wait one second for a key press */
        Timeout.QuadPart = -10000000;
        Status = NtWaitForSingleObject(KeyboardHandle, FALSE, &Timeout);
        if (Status != STATUS_TIMEOUT)
            break;
    }

    /* Erase the countdown string */
    EraseLine(Len);

    if (Status == STATUS_TIMEOUT)
    {
        /* The user did not press any key, cancel the read */
        NtCancelIoFile(KeyboardHandle, &IoStatusBlock);
    }
    else
    {
        /* Otherwise, return some status */
        Status = IoStatusBlock.Status;
    }

    return Status;
}

INT
__cdecl
_main(
    IN INT argc,
    IN PCHAR argv[],
    IN PCHAR envp[],
    IN ULONG DebugFlag)
{
    HANDLE KeyboardHandle;

    PrintString("Welcome to NT Shell Stub!\r\n\r\n");
    PrintString("If this program is used as a session manager, bugcheck screen with\r\n");
    PrintString("SESSION5_INITIALIZATION_FAILED code will appear after exit!\r\n\r\n");

    /* Open the keyboard */
    OpenKeyboard(&KeyboardHandle);

    if (KeyboardHandle)
    {
        WaitForKeyboard(KeyboardHandle, 10);
        NtClose(KeyboardHandle);
    }

    PrintString("*mainmoduledotexe left, lol*\r\n");

    return 0;
}
