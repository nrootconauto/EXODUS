#ifndef _EX_DDK_
#define _EX_DDK_

/*
 * copied from git
 *
 * Copy necessary structures and definitions out of the Windows DDK
 * to enable calling NtQueryDirectoryFile()
 */

typedef VOID(NTAPI *PIO_APC_ROUTINE)(IN PVOID ApcContext,
                                     IN PIO_STATUS_BLOCK IoStatusBlock,
                                     IN ULONG Reserved);

NTSYSCALLAPI
NTSTATUS
NTAPI
NtQueryDirectoryFile(_In_ HANDLE FileHandle, _In_opt_ HANDLE Event,
                     _In_opt_ PIO_APC_ROUTINE ApcRoutine,
                     _In_opt_ PVOID ApcContext,
                     _Out_ PIO_STATUS_BLOCK IoStatusBlock,
                     _Out_writes_bytes_(Length) PVOID FileInformation,
                     _In_ ULONG Length,
                     _In_ FILE_INFORMATION_CLASS FileInformationClass,
                     _In_ BOOLEAN ReturnSingleEntry,
                     _In_opt_ PUNICODE_STRING FileName,
                     _In_ BOOLEAN RestartScan);

#define STATUS_NO_MORE_FILES ((NTSTATUS)0x80000006L)

#endif
