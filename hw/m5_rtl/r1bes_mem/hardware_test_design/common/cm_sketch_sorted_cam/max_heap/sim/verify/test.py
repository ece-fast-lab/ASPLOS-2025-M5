import os

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
