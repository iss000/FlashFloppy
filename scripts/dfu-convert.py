# Written by Antonio Galea - 2010/11/18
# Distributed under Gnu LGPL 3.0
# see http://www.gnu.org/licenses/lgpl-3.0.txt

import sys,struct,zlib
from optparse import OptionParser
from intelhex import IntelHex

DEFAULT_DEVICE="0x0483:0xdf11"

def compute_crc(data):
  return 0xFFFFFFFF & -zlib.crc32(data) -1

def build(file,targets,device=DEFAULT_DEVICE):
  data = ''
  for t,target in enumerate(targets):
    tdata = ''
    for image in target:
      tdata += struct.pack('<2I',image['address'],len(image['data']))+image['data']
    tdata = struct.pack('<6sBI255s2I','Target',0,1,'ST...',len(tdata),len(target)) + tdata
    data += tdata
  data  = struct.pack('<5sBIB','DfuSe',1,len(data)+11,len(targets)) + data
  v,d=map(lambda x: int(x,0) & 0xFFFF, device.split(':',1))
  data += struct.pack('<4H3sB',0,d,v,0x011a,'UFD',16)
  crc   = compute_crc(data)
  data += struct.pack('<I',crc)
  open(file,'wb').write(data)

if __name__=="__main__":
  usage = """
%prog {-i|--ihex} file.hex [-i file.hex ...] [{-D|--device}=vendor:device] outfile.dfu"""

  parser = OptionParser(usage=usage)
  parser.add_option("-i", "--ihex", action="append", dest="hexfiles",
    help="build a DFU file from given HEXFILES", metavar="HEXFILES")
  parser.add_option("-D", "--device", action="store", dest="device",
    help="build for DEVICE, defaults to %s" % DEFAULT_DEVICE, metavar="DEVICE")
  (options, args) = parser.parse_args()

  if options.hexfiles and len(args)==1:
    target = []
    
    for hex in options.hexfiles:
      ih = IntelHex(hex)
      address = ih.minaddr()
      data = ih.tobinstr()
      try:
        address = address & 0xFFFFFFFF
      except ValueError:
        print "Address %s invalid." % address
        sys.exit(1)
      target.append({ 'address': address, 'data': data })
    
    outfile = args[0]
    device = DEFAULT_DEVICE
    if options.device:
      device=options.device
    try:
      v,d=map(lambda x: int(x,0) & 0xFFFF, device.split(':',1))
    except:
      print "Invalid device '%s'." % device
      sys.exit(1)
    build(outfile,[target],device)
  else:
    parser.print_help()
    sys.exit(1)
