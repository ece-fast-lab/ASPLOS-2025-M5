rm answer.txt result.txt addr_trace.txt cnt_trace.txt ;
python3 heap_tb_random.py ;
cd ../ ; 
./sim.sh ;
cd verify ;
python3 compare.py;
python3 test.py;
