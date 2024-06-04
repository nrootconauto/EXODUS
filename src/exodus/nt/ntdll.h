#pragma once

typedef VOID NTAPI IO_APC_ROUTINE(IN PVOID ApcContext,
                                  IN PIO_STATUS_BLOCK IoStatusBlock,
                                  IN ULONG Reserved);
typedef IO_APC_ROUTINE *PIO_APC_ROUTINE;

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

#ifndef STATUS_NO_MORE_FILES
  #define STATUS_NO_MORE_FILES ((NTSTATUS)0x80000006L)
#endif

NTSYSCALLAPI
NTSTATUS
NTAPI
NtCreateKeyedEvent(_Out_ PHANDLE KeyedEventHandle,
                   _In_ ACCESS_MASK DesiredAccess,
                   _In_opt_ POBJECT_ATTRIBUTES ObjectAttributes,
                   _In_ ULONG Flags);

NTSYSCALLAPI
NTSTATUS
NTAPI
NtOpenKeyedEvent(_Out_ PHANDLE KeyedEventHandle, _In_ ACCESS_MASK DesiredAccess,
                 _In_ POBJECT_ATTRIBUTES ObjectAttributes);

NTSYSCALLAPI
NTSTATUS
NTAPI
NtReleaseKeyedEvent(_In_ HANDLE KeyedEventHandle, _In_ PVOID KeyValue,
                    _In_ BOOLEAN Alertable, _In_opt_ PLARGE_INTEGER Timeout);

NTSYSCALLAPI
NTSTATUS
NTAPI
NtWaitForKeyedEvent(_In_ HANDLE KeyedEventHandle, _In_ PVOID KeyValue,
                    _In_ BOOLEAN Alertable, _In_opt_ PLARGE_INTEGER Timeout);

NTSYSCALLAPI
NTSTATUS
NTAPI
NtSetEvent(_In_ HANDLE EventHandle, _Out_opt_ PLONG PreviousState);

// use a negative integer because this thing does absolute deadlines for positive
NTSYSCALLAPI
NTSTATUS
NTAPI
NtDelayExecution(IN BOOLEAN Alertable, IN PLARGE_INTEGER DelayInterval);

// 100ns/unit, Wine: 1e4 min, NT: 5e3 min
// 'set' param: one of the hilarities of NT API, just make a GetTimerResolution
NTSYSCALLAPI
NTSTATUS
NTAPI
ZwSetTimerResolution(IN ULONG req, IN BOOLEAN set,
                     OUT PULONG real);
