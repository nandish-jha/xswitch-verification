interface intf(input bit clk, reset);

    logic [15:0] data_in;
    logic [15:0] addr_in;
    logic [3:0]  valid_in;
    logic [3:0]  data_read;

    logic [15:0] data_out; 
    logic [15:0] addr_out;
    logic [3:0]  data_rdy;
    logic [3:0]  rcv_rdy;
    
    covergroup cg @ (posedge clk);
        option.at_least = 3;
        
        coverpoint data_in iff (reset == 0){
            // bins di_min = {16'H0};
            bins di_b1  = {[16'H0:16'HF]};
            bins di_b2  = {[16'H10:16'HFF]};
            bins di_b3  = {[16'H100:16'HFFF]};
            bins di_b4  = {[16'H1000:16'HFFFF]};
            // bins di_max = {16'HFFFF};
        }

        coverpoint addr_in[3:0] iff (reset == 0){
            // bins ai_b1_min = {4'h0};  
            bins ai_b1 = { 4'h0,4'h3};  
            // bins ai_b1_max = {4'h3};  
            // illegal_bins ai_i_b1 = {[4'h4:4'hF]};
        }

        coverpoint addr_in[7:4] iff (reset == 0){
            // bins ai_b2_min = {4'h0};  
            bins ai_b2 = { 4'h0,4'h3};  
            // bins ai_b2_max = {4'h3};         
            // illegal_bins ai_i_b2 = {[4'h4:4'hF]};
        }

        coverpoint addr_in[11:8] iff (reset == 0){
            // bins ai_b3_min = {4'h0};  
            bins ai_b3 = { 4'h0,4'h3};  
            // bins ai_b3_max = {4'h3};         
            // illegal_bins ai_i_b3 = {[4'h4:4'hF]};
        }

        coverpoint addr_in[15:12] iff (reset == 0){    
            // bins ai_b4_min = {4'h0};  
            bins ai_b4 = { 4'h0,4'h3};  
            // bins ai_b4_max = {4'h3};         
            // illegal_bins ai_i_b14 = {[4'h4:4'hF]};
        }
    
        coverpoint valid_in iff (reset == 0){
            // bins valid_in_min = {4'h0};
            bins valid_in_bin = {[4'h0:4'hF]};
            bins valid_in_falling = ([4'h1:4'hF] => 4'h0);
            bins valid_in_rising = (4'h0 => [4'h1:4'hF]);
            // bins valid_in_max = {4'hF};
        }

        coverpoint data_read iff (reset == 0){
            // bins data_read_min = {4'h0};
            bins data_read_bin = {[4'h0:4'hF]};
            bins data_read_falling = ([4'h1:4'hF] => 4'h0);
            bins data_read_rising = (4'h0 => [4'h1:4'hF]);
            // bins data_read_max = {4'hF};
        }
    endgroup

    cg cg_inst = new;

    clocking cb_mon @(posedge clk);
        input data_in;
        input addr_in;
        input valid_in;
        input data_read;

        input rcv_rdy;
        input data_rdy;
        input data_out;
        input addr_out;
    endclocking

    clocking cb_driv @(posedge clk);
        output data_in;
        output addr_in;
        output valid_in;
        output data_read;

        input rcv_rdy;
        input data_rdy;
        input data_out;
        input addr_out;
    endclocking

    modport MON(
        clocking cb_mon,
        input reset
    );

    modport DRIV(
        clocking cb_driv,
        input reset
    );

    modport DUT(
        input clk,
        input reset,

        input data_in,
        input addr_in,
        input valid_in,
        input data_read,

        output rcv_rdy,
        output data_rdy,
        output data_out,
        output addr_out
    );

endinterface
