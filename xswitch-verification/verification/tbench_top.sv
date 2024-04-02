`include "uvm_macros.svh"

module tbench_top;

  bit clk = 0;
  bit reset = 1;
  
  import uvm_pkg::*;
  import lab4_pkg::*;
  
  intf i_intf (.clk(clk), .reset(reset));
  dut_top dut(i_intf.DUT);

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    reset = 1;
    repeat(3) @(negedge clk);
    reset = 0;
  end

  initial begin: blk
    uvm_config_db #(virtual intf)::set(null, "uvm_test_top", "driver_if",  i_intf.DRIV);
    uvm_config_db #(virtual intf)::set(null, "uvm_test_top", "monitor_if", i_intf.MON );

    uvm_top.finish_on_completion  = 1;
  
    run_test();
  end

  final begin
      // i_intf.cg_inst.sample();
      $display("\033[34mCoverage = %0.2f %%\033[0m", i_intf.cg_inst.get_inst_coverage());
  end

endmodule
