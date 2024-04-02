module dut_top(intf.DUT intf_dut);

    xswitch dut_core(
        .clk(intf_dut.clk),
        .reset(intf_dut.reset),

        .data_in(intf_dut.data_in),
        .addr_in(intf_dut.addr_in),
        .rcv_rdy(intf_dut.rcv_rdy),
        .valid_in(intf_dut.valid_in),
        
        .data_out(intf_dut.data_out),
        .addr_out(intf_dut.addr_out),
        .data_read(intf_dut.data_read),    
        .data_rdy(intf_dut.data_rdy)
    );

endmodule
