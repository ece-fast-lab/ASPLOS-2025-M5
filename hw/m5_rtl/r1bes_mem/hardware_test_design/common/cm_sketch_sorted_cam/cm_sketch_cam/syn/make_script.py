
import math

params = [] # N_entry, RFM_th, Counter-bits
#params.append([19, 8, 5])
#params.append([22, 32, 7])
#params.append([24, 128, 9])
#params.append([38, 8, 6])
#params.append([46, 32, 8])
#params.append([50, 128, 10])
#params.append([78, 8, 6])
#params.append([93, 32, 8])
#params.append([107, 128, 10])
#params.append([157, 8, 6])
#params.append([194, 32, 8])
#params.append([254, 128, 10])
#params.append([320, 8, 6])
#params.append([422, 32, 8])
#params.append([981, 128, 10])
#params.append([698, 8, 6])
#params.append([1122, 32, 8])

#params.append([369, 16, 7])
#params.append([522, 64, 9])
#params.append([984, 128, 10])
#params.append([177, 16, 7])
#params.append([214, 64, 9])
#params.append([254, 128, 10])
#params.append([420, 256, 11])
#params.append([87, 16, 7])
#params.append([99, 64, 9])
#params.append([107, 128, 10])
#params.append([123, 256, 11])
#params.append([53, 256, 11])
#params.append([25, 256, 10])
#params.append([415, 16, 7])
#params.append([583, 64, 9])
#params.append([1186, 128, 10])
#params.append([187, 16, 7])
#params.append([223, 64, 9])
#params.append([264, 128, 10])
#params.append([439, 256, 11])
#params.append([89, 16, 7])
#params.append([101, 64, 9])
#params.append([108, 128, 10])
#params.append([124, 256, 11])
#params.append([53, 256, 11])
#params.append([25, 256, 10])

params.append([25, 256, 10])
params.append([53, 256, 10])
params.append([124, 256, 11])
params.append([101, 64, 8])
params.append([95, 32, 7])
params.append([264, 128, 10])
params.append([223, 64, 9])
params.append([203, 32, 7])
params.append([1186, 128, 10])
params.append([583, 64, 9])
params.append([471, 32, 8])
params.append([1590, 32, 9])



BASE_DIR = ".."
TSMC_STD_CELL = "/scale/cal/home/jhpark/logic_design/db/tsmc40/g"
SYN_FREQ = "250.0"
TSMC_TARGET_LIB = "sc9_cln40g_base_rvt_tt_typical_max_0p90v_25c"



for param in params:
  print( "mkdir -p ./log/rfm_{}; ".format(SYN_FREQ), end='')
  print( "export BASE_DIR={}; ".format(BASE_DIR), end='')
  print( "export TSMC_STD_CELL={}; ".format(TSMC_STD_CELL), end='')
  print( "export SYN_FREQ={}; ".format(SYN_FREQ), end='')
  print( "export TSMC_TARGET_LIB={}; ".format(TSMC_TARGET_LIB), end='')
  print( "export NUM_ENTRY={}; ".format(int(param[0])), end='')
  print( "export RFM_TH={}; ".format(int(param[1])), end='')
  print( "export NUM_BIT={}; ".format(int(param[2])), end='')
  print( "dc_shell-xg-t -f {}/syn/rfm.tcl -no_gui > ./log/rfm_{}/{}_{}_{}.log".format(BASE_DIR, SYN_FREQ, int(param[0]), int(param[1]), int(param[2])))

