import os

inputDir = '../src/rfm_unit_bank'
outputDir = './output'

fileList = os.listdir(inputDir)

fileList.sort()


print('Module,Frequency,Area(um^2),Timing(ns),Dynamic Power(uW),Leakage Power(uW),Violated')

for fileName in fileList:
  for SYN_FREQ in [250.0]:
    TOP_MODULE = fileName[:-2]
    outputPath = outputDir + '/' + TOP_MODULE + '/' + str(SYN_FREQ)

    timing = 0.0
    violated = ''
    area = 0.0
    dynamicPower = 0.0
    leakagePower = 0.0

    # Timing
    with open(outputPath + '/' + 'timing.rep', 'r') as f:
      lines = f.readlines()
      for line in lines:
        if line.find('data arrival time') != -1: 
          tokens = line.split()
          if float(tokens[3]) > 0:
            timing = tokens[3]
        if line.find('slack') != -1: 
          tokens = line.split()
          if(tokens[1] == '(VIOLATED)'):
            violated = 'VIOLATED'

    # Area
    with open(outputPath + '/' + 'area.rep', 'r') as f:
      lines = f.readlines()
      for line in lines:
        if line.find('Total area') != -1: 
          tokens = line.split()
          area = tokens[2]

    # Power
    with open(outputPath + '/' + 'power.rep', 'r') as f:
      lines = f.readlines()
      for line in lines:
        if line.find('Total Dynamic Power') != -1: 
          tokens = line.split()
          if(tokens[5] == 'pW'):
            dynamicPower = float(tokens[4]) / 1000 / 1000
          elif(tokens[5] == 'nW'):
            dynamicPower = float(tokens[4]) / 1000
          elif(tokens[5] == 'uW'):
            dynamicPower = float(tokens[4])
          elif(tokens[5] == 'mW'):
            dynamicPower = float(tokens[4]) * 1000
          elif(tokens[5] == 'W'):
            dynamicPower = float(tokens[4]) * 1000 * 1000
          elif(tokens[5] == 'kW'):
            dynamicPower = float(tokens[4]) * 1000 * 1000 * 1000
          elif(tokens[5] == 'MW'):
            dynamicPower = float(tokens[4]) * 1000 * 1000 * 1000 * 1000

        if line.find('Cell Leakage Power') != -1: 
          tokens = line.split()
          if(tokens[5] == 'pW'):
            leakagePower = float(tokens[4]) / 1000 / 1000
          elif(tokens[5] == 'nW'):
            leakagePower = float(tokens[4]) / 1000
          elif(tokens[5] == 'uW'):
            leakagePower = float(tokens[4])
          elif(tokens[5] == 'mW'):
            leakagePower = float(tokens[4]) * 1000
          elif(tokens[5] == 'W'):
            leakagePower = float(tokens[4]) * 1000 * 1000
          elif(tokens[5] == 'kW'):
            leakagePower = float(tokens[4]) * 1000 * 1000 * 1000
          elif(tokens[5] == 'MW'):
            leakagePower = float(tokens[4]) * 1000 * 1000 * 1000 * 1000

    print(TOP_MODULE, SYN_FREQ, area, timing, dynamicPower, leakagePower, violated, sep=',') 
