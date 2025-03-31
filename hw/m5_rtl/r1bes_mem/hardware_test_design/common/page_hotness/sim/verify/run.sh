rm answer.txt result.txt  rtrace.txt ;
python3 tb_afu_top_random.py ;
cd ../ ; 
./sim.sh ;
cd verify ;
python3 compare.py ;
