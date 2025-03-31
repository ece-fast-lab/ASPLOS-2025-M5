import os

os.system('python tb_rfm.py > answer.txt')
os.system('./sim.sh')

diff_result = os.popen('diff answer.txt result.txt').read()

if diff_result == '':
  print()
  print('///////////////////////')
  print('///  Test Passed!!  ///')
  print('///////////////////////')
  print()
else:
  print()
  print('///////////////////////')
  print('///  Test Failed!!  ///')
  print('///////////////////////')
  print()
