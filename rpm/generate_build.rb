#!/usr/bin/ruby

# Android build system is complicated and does not allow to build
# separate parts easily.
# This script tries to mimic Android build rules.

def expand(dir, files)
  files.map{|f| File.join(dir,f)}
end

# Compiles sources to *.o files.
# Returns array of output *.o filenames
def compile(sources, cflags)
  outputs = []
  for s in sources
    ext = File.extname(s)
    
    case ext
    when '.c'
        cc = 'gcc'
    	lang_flags = '-std=gnu11 $CFLAGS $CPPFLAGS'
    when '.cpp', '.cc'
        cc = 'g++'
    	lang_flags = '-std=gnu++14 $CXXFLAGS $CPPFLAGS'
    else
        raise "Unknown extension #{ext}"
    end

    output = s + '.o'
    outputs << output
    puts "#{cc} -o #{output} #{lang_flags} #{cflags} -c #{s}\n"
  end

  return outputs
end

# Links object files
def link(output, objects, ldflags)
  puts "g++ -o #{output} #{ldflags} $LDFLAGS #{objects.join(' ')}"
end

adbdfiles = %w(
  client/usb_dispatch.cpp
  client/usb_libusb.cpp
  client/usb_linux.cpp
  adb.cpp
  adb_io.cpp
  socket_spec.cpp
  adb_listeners.cpp
  adb_utils.cpp
  sockets.cpp
  transport.cpp
  transport_local.cpp
  transport_usb.cpp
  services.cpp
  adb_trace.cpp
  diagnose_usb.cpp
  adb_auth_host.cpp
  sysdeps_unix.cpp
)
libadbd = compile(expand('adb', adbdfiles), '-DADB_REVISION=\"$PKGVER\" -DADB_HOST=1 -fpermissive -I../boringssl/include -Iadb -Iinclude -Ibase/include -Ilibcrypto_utils/include')

adbshfiles = %w(
  fdevent.cpp
  shell_service.cpp
  shell_service_protocol.cpp
)
libadbsh = compile(expand('adb', adbshfiles), '-DADB_REVISION=\"$PKGVER\" -DADB_HOST=0 -D_Nonnull= -D_Nullable= -fpermissive -Iadb -Iinclude -Ibase/include')

adbfiles = %w(
  console.cpp
  bugreport.cpp
  commandline.cpp
  adb_client.cpp
  sysdeps/errno.cpp
  file_sync_client.cpp
  line_printer.cpp
  transport_mdns.cpp
  client/main.cpp
)
libadb = compile(expand('adb', adbfiles), '-DADB_REVISION=\"$PKGVER\" -D_GNU_SOURCE -DADB_HOST=1 -D_Nonnull= -D_Nullable= -fpermissive -Iadb -I../mdnsresponder/mDNSShared -Iinclude -Ibase/include')

basefiles = %w(
  file.cpp
  logging.cpp
  parsenetaddress.cpp
  stringprintf.cpp
  strings.cpp
  errors_unix.cpp
)
libbase = compile(expand('base', basefiles), '-DADB_HOST=1 -D_GNU_SOURCE -Ibase/include -Iinclude')

logfiles = %w(
  logger_write.c
  local_logger.c
  config_read.c
  logprint.c
  stderr_write.c
  config_write.c
  logger_lock.c
  logger_name.c
  log_event_list.c
  log_event_write.c
  fake_log_device.c
  fake_writer.c
)
liblog = compile(expand('liblog', logfiles), '-DLIBLOG_LOG_TAG=1005 -DFAKE_LOG_DEVICE=1 -D_GNU_SOURCE -Ilog/include -Iinclude')

cutilsfiles = %w(
  load_file.c
  socket_inaddr_any_server_unix.c
  socket_local_client_unix.c
  socket_local_server_unix.c
  socket_loopback_server_unix.c
  socket_network_client_unix.c
  threads.c
  sockets.cpp
  android_get_control_file.cpp
  sockets_unix.cpp
)
libcutils = compile(expand('libcutils', cutilsfiles), '-D_GNU_SOURCE -Iinclude')

cryptofiles = %w(
  android_pubkey.c
)
libcryptoutils = compile(expand('libcrypto_utils', cryptofiles), '-Ilibcrypto_utils/include -I../boringssl/include -Iinclude')

boringcryptofiles = %w(
  bn/cmp.c
  bn/bn.c
  bytestring/cbb.c
  mem.c
  buf/buf.c
  bio/file.c
  bn/convert.c
  base64/base64.c
)
boringcrypto = compile(expand('../boringssl/src/crypto', boringcryptofiles), '-I../boringssl/include -Iinclude')

mdnsfiles = %w(
  mDNSShared/dnssd_ipc.c
  mDNSShared/dnssd_clientstub.c
)
mdns = compile(expand('../mdnsresponder', mdnsfiles), '-D_GNU_SOURCE -DHAVE_IPV6 -DHAVE_LINUX -DNOT_HAVE_SA_LEN -DUSES_NETLINK -UMDNS_DEBUGMSGS -DMDNS_DEBUGMSGS=0 -I../mdnsresponder/mDNSShared -I../mdnsresponder/mDNSCore -Iinclude')

link('adb/adb', libbase + liblog + libcutils + boringcrypto + libcryptoutils + libadbd + libadbsh + mdns + libadb, '-lrt -ldl -lpthread -lcrypto -lutil -lusb-1.0')

fastbootfiles = %w(
  socket.cpp
  tcp.cpp
  udp.cpp
  protocol.cpp
  engine.cpp
  bootimg_utils.cpp
  fastboot.cpp
  util.cpp
  fs.cpp
  usb_linux.cpp
)
libfastboot = compile(expand('fastboot', fastbootfiles), '-DFASTBOOT_REVISION=\"$PKGVER\" -D_GNU_SOURCE -Iadb -Iinclude -Imkbootimg -Ibase/include -Ilibsparse/include -I../extras/ext4_utils/include -I../extras/f2fs_utils')

sparsefiles = %w(
  backed_block.c
  output_file.c
  sparse.c
  sparse_crc32.c
  sparse_err.c
  sparse_read.c
)
libsparse = compile(expand('libsparse', sparsefiles), '-Ilibsparse/include')

zipfiles = %w(
  zip_archive.cc
)
libzip = compile(expand('libziparchive', zipfiles), '-Ibase/include -Iinclude')

utilfiles = %w(
  FileMap.cpp
)
libutil = compile(expand('libutils', utilfiles), '-Iinclude')

ext4files = %w(
  make_ext4fs.c
  ext4fixup.c
  ext4_utils.c
  allocate.c
  contents.c
  extent.c
  indirect.c
  sha1.c
  wipe.c
  crc16.c
  ext4_sb.c
)
libext4 = compile(expand('../extras/ext4_utils', ext4files), '-Ilibsparse/include -Iinclude -I../extras/ext4_utils/include')

link('fastboot/fastboot', libsparse + libzip + liblog + libutil + libcutils + boringcrypto + libcryptoutils + libbase + libext4 + libfastboot + libadbsh + libadbd, '-lpthread -lselinux -lz -lcrypto -lutil -lusb-1.0')

simg2imgfiles = %w(
  simg2img.c
)
libsimg2img = compile(expand('libsparse', simg2imgfiles), '-Iinclude -Ilibsparse/include')
link('libsparse/simg2img', libsparse + libsimg2img, '-lz')

img2simgfiles = %w(
  img2simg.c
)
libimg2simg = compile(expand('libsparse', img2simgfiles), '-Iinclude -Ilibsparse/include')
link('libsparse/img2simg', libsparse + libimg2simg, '-lz')
