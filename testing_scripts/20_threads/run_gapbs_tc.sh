bench="gapbs-tc"
node="0"
second=10
test_m5=$1

./run_gapbs_generic.sh $bench $node $second $test_m5
sudo pkill -f pcm-memory-daem
sudo pkill -f m5_manager
