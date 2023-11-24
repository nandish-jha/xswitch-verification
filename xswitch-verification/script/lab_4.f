// QuestaSim command line:
//   setenv UVM_HOME ...
//   qverilog -f uvm_basics_hello_world.f

+incdir+.
+incdir+$UVM_HOME/src
$UVM_HOME/src/uvm_pkg.sv
//$UVM_HOME/src/dpi/uvm_dpi.cc

./dut/xswitch.svp

./verification/interface.sv
./verification/sequencer.sv
./verification/lab4_pkg.sv
./verification/dut_top.sv
./verification/tbench_top.sv

//-R
//-suppress 2167
//-suppress 3829
//-uvmcontrol=all
//+UVM_TESTNAME="test3"
