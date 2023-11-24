`include "uvm_macros.svh"

package sequencer;

  import uvm_pkg::*;

  class transaction extends uvm_sequence_item;
  
    `uvm_object_utils(transaction)

    rand logic [15:0] data_in  ;
    rand logic [15:0] addr_in  ;
    rand bit   [3:0]  valid_in ;
    rand bit   [3:0]  data_read;

    logic [15:0] data_out;
    logic [15:0] addr_out;
    bit   [3:0]  data_rdy;
    bit   [3:0]  rcv_rdy ;

    bit reset;
    
    function new (string name = "");
      super.new(name);
    endfunction: new
  
    constraint addr_less_than_4 {
        addr_in[3:0]   < 4;
        addr_in[7:4]   < 4;
        addr_in[11:8]  < 4;
        addr_in[15:12] < 4;
    }
    
    function string convert2string;
      string string1, string2, string3, string4, string5, string6,string7, result;
      string1 = ("\n-----------------------------------------------------------------------------------------------------------------\n");
      string7 = $sformatf("\n\033[31m[Scoreboard] - reset = %0b\033[0m\n", reset);
      string2 = $sformatf("\n\tdata_in  = %4h, data_out  = %4h", data_in,  data_out );
      string3 = $sformatf("\n\taddr_in  = %4h, addr_out  = %4h", addr_in,  addr_out );
      string4 = $sformatf("\n\tvalid_in = %4b, data_rdy  = %4b", valid_in, data_rdy );
      string5 = $sformatf("\n\trcv_rdy  = %4b, data_read = %4b", rcv_rdy,  data_read);
      string6 = ("\n");
      // string6 = ("\n------------------------------------------------------------------------\n");
      
      result = {string1, string7, string2, string3, string4, string5, string6};
      return $psprintf(result);
    endfunction: convert2string

  endclass: transaction


  class constraint_sanity_addr extends transaction;

    `uvm_object_utils(constraint_sanity_addr)

    function new (string name = "");
      super.new(name);
    endfunction: new
    
    constraint addr_duplicate {
      addr_in[3:0]   == 4'd0;
      addr_in[7:4]   == 4'd1;
      addr_in[11:8]  == 4'd2;
      addr_in[15:12] == 4'd3;
    }

  endclass: constraint_sanity_addr


  class constraint_duplicate_addr extends transaction;

    `uvm_object_utils(constraint_duplicate_addr)

    function new (string name = "");
      super.new(name);
    endfunction: new
    
    constraint addr_duplicate {
      addr_in[3:0] == addr_in[7:4] && addr_in[7:4] == addr_in[11:8] && addr_in[11:8] == addr_in[15:12];
    }

  endclass: constraint_duplicate_addr


  class constraint_unique_addr extends transaction;

    `uvm_object_utils(constraint_unique_addr)

    function new (string name = "");
      super.new(name);
    endfunction: new
    
    constraint addr_unique {
        unique {addr_in[3:0], addr_in[7:4], addr_in[11:8], addr_in[15:12]};
    }

  endclass: constraint_unique_addr


  class read_modify_write extends uvm_sequence #(transaction);
  
    `uvm_object_utils(read_modify_write)
    
    function new (string name = "");
      super.new(name);
    endfunction: new

    task body;
      transaction tx;
      tx = transaction::type_id::create("tx");

      start_item(tx);
      assert( tx.randomize() );
      finish_item(tx);

    endtask: body
   
  endclass: read_modify_write
  

  class seq_of_commands extends uvm_sequence #(transaction);
  
    `uvm_object_utils(seq_of_commands)
    `uvm_declare_p_sequencer(uvm_sequencer#(transaction))
    
    int n = 1000; // = (5 + 3);
    // int n = 5; // = (5 + 3);
    
    function new (string name = "");
      super.new(name);
    endfunction: new

    task body;
      repeat(n+5)
      begin
        read_modify_write seq;
        seq = read_modify_write::type_id::create("seq");
        assert( seq.randomize() );
        seq.start(p_sequencer);
      end
    endtask: body
   
  endclass: seq_of_commands
  
endpackage: sequencer
