/* **********************************************************
 * Copyright 2007 VMware, Inc.  All rights reserved. -- VMware Confidential
 * **********************************************************/

/*
 * vmci_sockets.h --
 *
 *    VMCI sockets public constants and types.
 */

***REMOVED***ifndef _VMCI_SOCKETS_H_
***REMOVED***define _VMCI_SOCKETS_H_


***REMOVED***if defined(_WIN32)
***REMOVED***  if !defined(NT_INCLUDED)
***REMOVED***     include <winsock2.h>
***REMOVED***  endif // !NT_INCLUDED
***REMOVED***else // _WIN32
***REMOVED***if defined(linux) && !defined(VMKERNEL)
***REMOVED***  if !defined(__KERNEL__)
***REMOVED***    include <sys/socket.h>
***REMOVED***  endif // __KERNEL__
***REMOVED***else // linux && !VMKERNEL
***REMOVED***  if defined(__APPLE__)
***REMOVED***    include <sys/socket.h>
***REMOVED***    include <string.h>
***REMOVED***  endif // __APPLE__
***REMOVED***endif // linux && !VMKERNEL
***REMOVED***endif

/*
 * We use the same value for the AF family and the socket option
 * level. To set options, use the value of VMCISock_GetAFValue for
 * 'level' and these constants for the optname.
 */
***REMOVED***define SO_VMCI_BUFFER_SIZE                 0
***REMOVED***define SO_VMCI_BUFFER_MIN_SIZE             1
***REMOVED***define SO_VMCI_BUFFER_MAX_SIZE             2
***REMOVED***define SO_VMCI_PEER_HOST_VM_ID             3
***REMOVED***define SO_VMCI_SERVICE_LABEL               4
***REMOVED***define SO_VMCI_TRUSTED                     5

/*
 * The VMCI sockets address equivalents of INADDR_ANY.  The first works for
 * the svm_cid (context id) field of the address structure below and indicates
 * the current guest (or the host, if running outside a guest), while the
 * second indicates any available port.
 */
***REMOVED***define VMADDR_CID_ANY  ((unsigned int) -1)
***REMOVED***define VMADDR_PORT_ANY ((unsigned int) -1)


***REMOVED***if defined(_WIN32) || defined(VMKERNEL)
   typedef unsigned short sa_family_t;
***REMOVED***endif // _WIN32

***REMOVED***if defined(VMKERNEL)
   struct sockaddr {
      sa_family_t sa_family;
      char sa_data[14];
   };
***REMOVED***endif

/*
 * Address structure for VSockets VMCI sockets. The address family should be
 * set to AF_VMCI. The structure members should all align on their natural
 * boundaries without resorting to compiler packing directives.
 */

struct sockaddr_vm {
***REMOVED***if defined(__APPLE__)
   unsigned char svm_len;                           // Mac OS has the length first.
***REMOVED***endif // __APPLE__
   sa_family_t svm_family;                          // AF_VMCI.
   unsigned short svm_reserved1;                    // Reserved.
   unsigned int svm_port;                           // Port.
   unsigned int svm_cid;                            // Context id.
   unsigned char svm_zero[sizeof(struct sockaddr) - // Same size as sockaddr.
***REMOVED***if defined(__APPLE__)
                             sizeof(unsigned char) -
***REMOVED***endif // __APPLE__
                             sizeof(sa_family_t) -
                             sizeof(unsigned short) -
                             sizeof(unsigned int) -
                             sizeof(unsigned int)];
};


***REMOVED***if defined(_WIN32)
***REMOVED***  if !defined(NT_INCLUDED)
***REMOVED***     include <winioctl.h>
***REMOVED***     define VMCI_SOCKETS_DEVICE          L"\\\\.\\VMCI"
***REMOVED***     define VMCI_SOCKETS_GET_AF_VALUE    0x81032068
***REMOVED***     define VMCI_SOCKETS_GET_LOCAL_CID   0x8103206c
      static __inline int VMCISock_GetAFValue(void)
      {
         int afvalue = -1;
         HANDLE device = CreateFileW(VMCI_SOCKETS_DEVICE, GENERIC_READ, 0, NULL,
                                     OPEN_EXISTING, FILE_FLAG_OVERLAPPED, NULL);
         if (INVALID_HANDLE_VALUE != device) {
            DWORD ioReturn;
            DeviceIoControl(device, VMCI_SOCKETS_GET_AF_VALUE, &afvalue,
                            sizeof afvalue, &afvalue, sizeof afvalue,
                            &ioReturn, NULL);
            CloseHandle(device);
            device = INVALID_HANDLE_VALUE;
         }
         return afvalue;
      }
   
      static __inline unsigned int VMCISock_GetLocalCID(void)
      {
         unsigned int cid = VMADDR_CID_ANY;
         HANDLE device = CreateFileW(VMCI_SOCKETS_DEVICE, GENERIC_READ, 0, NULL,
                                     OPEN_EXISTING, FILE_FLAG_OVERLAPPED, NULL);
         if (INVALID_HANDLE_VALUE != device) {
            DWORD ioReturn;
            DeviceIoControl(device, VMCI_SOCKETS_GET_LOCAL_CID, &cid,
                            sizeof cid, &cid, sizeof cid, &ioReturn,
                            NULL);
            CloseHandle(device);
            device = INVALID_HANDLE_VALUE;
         }
         return cid;
      }
***REMOVED***  endif // !NT_INCLUDED
***REMOVED***else // _WIN32
***REMOVED***if (defined(linux) && !defined(VMKERNEL)) || (defined(__APPLE__))
***REMOVED***  if defined(linux) && defined(__KERNEL__)
   void VMCISock_KernelRegister(void);
   void VMCISock_KernelDeregister(void);
   int VMCISock_GetAFValue(void);
   int VMCISock_GetLocalCID(void);
***REMOVED***  elif defined(__APPLE__) && (KERNEL)
   /* Nothing to define here. */
***REMOVED***  else // __KERNEL__
***REMOVED***  include <sys/types.h>
***REMOVED***  include <sys/stat.h>
***REMOVED***  include <fcntl.h>
***REMOVED***  include <sys/ioctl.h>
***REMOVED***  include <unistd.h>

***REMOVED***  include <stdio.h>

***REMOVED***  define VMCI_SOCKETS_DEFAULT_DEVICE      "/dev/vsock"
***REMOVED***  define VMCI_SOCKETS_CLASSIC_ESX_DEVICE  "/vmfs/devices/char/vsock/vsock"

***REMOVED*** if defined(linux)
***REMOVED***  define VMCI_SOCKETS_GET_AF_VALUE  1976
***REMOVED***  define VMCI_SOCKETS_GET_LOCAL_CID 1977
***REMOVED*** elif defined(__APPLE__)
***REMOVED***  include <sys/ioccom.h>
***REMOVED***  define VMCI_SOCKETS_GET_AF_VALUE  _IOR('V', 25 , int)
***REMOVED***  define VMCI_SOCKETS_GET_LOCAL_CID _IOR('V', 26 , unsigned)
***REMOVED***endif

   /*
    *----------------------------------------------------------------------------
    *
    * VMCISock_GetAFValue and VMCISock_GetAFValueFd --
    *
    *      Returns the value to be used for the VMCI Sockets address family.
    *      This value should be used as the domain argument to socket(2) (when
    *      you might otherwise use AF_INET).  For VMCI Socket-specific options,
    *      this value should also be used for the level argument to
    *      setsockopt(2) (when you might otherwise use SOL_TCP).
    *
    *      This function leaves its descriptor to the vsock device open so that
    *      the socket implementation knows that the socket family is still in
    *      use.  We do this because we register our address family with the
    *      kernel on-demand and need a notification to unregister the address
    *      family.
    *
    *      For many programs this behavior is sufficient as is, but some may
    *      wish to close this descriptor once they are done with VMCI Sockets.
    *      For these programs, we provide a VMCISock_GetAFValueFd() that takes
    *      an optional outFd argument.  This value can be provided to
    *      VMCISock_ReleaseAFValueFd() only after the program no longer will
    *      use VMCI Sockets.  Note that outFd is only valid in cases where
    *      VMCISock_GetAFValueFd() returns a non-negative value.
    *
    * Results:
    *      The address family value to use on success, negative error code on
    *      failure.
    *
    *----------------------------------------------------------------------------
    */

   static inline int VMCISock_GetAFValueFd(int *outFd)
   {
      int fd;
      int family;

      fd = open(VMCI_SOCKETS_DEFAULT_DEVICE, O_RDWR);
      if (fd < 0) {
         fd = open(VMCI_SOCKETS_CLASSIC_ESX_DEVICE, O_RDWR);
         if (fd < 0) {
            return -1;
         }
      }

      if (ioctl(fd, VMCI_SOCKETS_GET_AF_VALUE, &family) < 0) {
         family = -1;
      }

      if (family < 0) {
         close(fd);
      } else if (outFd) {
         *outFd = fd;
      }

      return family;
   }

   static inline int VMCISock_GetAFValue(void)
   {
      return VMCISock_GetAFValueFd(NULL);
   }


   static inline void VMCISock_ReleaseAFValueFd(int fd)
   {
      if (fd >= 0) {
         close(fd);
      }
   }

   static inline unsigned int VMCISock_GetLocalCID(void)
   {
      int fd;
      unsigned int contextId;

      fd = open(VMCI_SOCKETS_DEFAULT_DEVICE, O_RDWR);
      if (fd < 0) {
         fd = open(VMCI_SOCKETS_CLASSIC_ESX_DEVICE, O_RDWR);
         if (fd < 0) {
            return VMADDR_CID_ANY;
         }
      }

      if (ioctl(fd, VMCI_SOCKETS_GET_LOCAL_CID, &contextId) < 0) {
         contextId = VMADDR_CID_ANY;
      }

      close(fd);
      return contextId;
   }
***REMOVED***  endif // __KERNEL__
***REMOVED***endif // linux && !VMKERNEL
***REMOVED***endif // _WIN32


***REMOVED***endif // _VMCI_SOCKETS_H_

