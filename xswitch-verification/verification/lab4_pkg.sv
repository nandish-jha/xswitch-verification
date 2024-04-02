`include "uvm_macros.svh"

package lab4_pkg;

  import uvm_pkg::*;
  import sequencer::*;

  typedef sequencer::transaction transaction;
  typedef uvm_sequencer #(transaction) my_sequencer;

  class dut_config extends uvm_object;
     `uvm_object_utils(dut_config)

    function new(string name = "");
      super.new(name);
    endfunction

    //  virtual intf dut_vi;
    virtual intf.DRIV driver_if;
    virtual intf.MON  monitor_if;
    // optionally add other config fields as needed
     
  endclass // dut_config
   
   
  class driver extends uvm_driver #(transaction);
  
    `uvm_component_utils(driver)

    dut_config dut_config_0;
    // virtual intf dut_vi;
    virtual intf.DRIV driver_if;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
       assert( uvm_config_db #(dut_config)::get(this, "", "dut_config", dut_config_0) );
       driver_if = dut_config_0.driver_if;
       // other config settings from dut_config_0 object as needed
    endfunction : build_phase
   
    task run_phase(uvm_phase phase);
      forever begin
        transaction tx;
        
        // @(posedge driver_if.cb_driv);
        // seq_item_port.get(tx);
        seq_item_port.get(tx);
        @(posedge driver_if.cb_driv);
        
        // Wiggle pins of DUT
        driver_if.cb_driv.data_in   <= tx.data_in  ;
        driver_if.cb_driv.addr_in   <= tx.addr_in  ;
        driver_if.cb_driv.valid_in  <= tx.valid_in ;
        driver_if.cb_driv.data_read <= tx.data_read;
      end
    endtask: run_phase

  endclass: driver


  class monitor extends uvm_monitor;
  
    `uvm_component_utils(monitor)

     uvm_analysis_port #(transaction) aport;
    
     dut_config dut_config_0;
    //  virtual intf dut_vi;
    virtual intf.MON monitor_if;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
       dut_config_0 = dut_config::type_id::create("config");
       aport = new("aport", this);
       assert( uvm_config_db #(dut_config)::get(this, "", "dut_config", dut_config_0) );
       monitor_if = dut_config_0.monitor_if;
       // other config settings as needed
    endfunction : build_phase
   
    task run_phase(uvm_phase phase);
      forever
      begin
        transaction tx;
        tx = transaction::type_id::create("tx");

        tx.reset     = monitor_if.reset;

        tx.data_in   = monitor_if.cb_mon.data_in;
        tx.addr_in   = monitor_if.cb_mon.addr_in;
        tx.valid_in  = monitor_if.cb_mon.valid_in;
        tx.data_read = monitor_if.cb_mon.data_read;

        @(monitor_if.cb_mon);
        tx.addr_out = monitor_if.cb_mon.addr_out;
        tx.data_out = monitor_if.cb_mon.data_out;
        tx.rcv_rdy  = monitor_if.cb_mon.rcv_rdy;
        tx.data_rdy = monitor_if.cb_mon.data_rdy;

        aport.write(tx);

      end
    endtask: run_phase

  endclass: monitor


  class agent extends uvm_agent;

    `uvm_component_utils(agent)
    
    uvm_analysis_port #(transaction) aport;
    
    my_sequencer sequencer_h;
    driver       driver_h;
    monitor      monitor_h;
    
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
       aport = new("aport", this);
       sequencer_h = my_sequencer::type_id::create("sequencer_h", this);
       driver_h    = driver      ::type_id::create("driver_h"   , this);
       monitor_h   = monitor     ::type_id::create("monitor_h"  , this);
    endfunction: build_phase
    
    function void connect_phase(uvm_phase phase);
      driver_h.seq_item_port.connect( sequencer_h.seq_item_export );
      monitor_h.       aport.connect( aport );
    endfunction: connect_phase
    
  endclass: agent
  
  
  class scoreboard extends uvm_subscriber #(transaction);
  
    `uvm_component_utils(scoreboard)

    int i, j, h, k, flag = 0;

    logic [15:0] data_in  ;
    logic [15:0] addr_in  ;
    bit   [3:0]  valid_in ;
    bit   [3:0]  data_read;

    logic [15:0] data_out ;
    logic [15:0] addr_out ;
    bit   [3:0]  data_rdy ;
    bit   [3:0]  rcv_rdy  ;

    bit reset;

    int   fail_count_DR, fail_count_DO, fail_count_AO, fail_count_RR;
    int   pass_count_DR, pass_count_DO, pass_count_AO, pass_count_RR;
    logic [15:0] my_addr_out = 16'hxxxx, my_data_out = 16'hxxxx;
    bit [3:0] my_old_data_rdy, my_data_rdy, my_rcv_rdy = 4'b1111;

    covergroup cg;
        option.at_least = 3;
        
        coverpoint data_in iff (reset == 0){
            bins di_min = {16'H0};
            bins di_b1  = {[16'H1:16'HF]};
            bins di_b2  = {[16'H10:16'HFF]};
            bins di_b3  = {[16'H100:16'HFFF]};
            bins di_b4  = {[16'H1000:16'HFFFE]};
            bins di_max = {16'HFFFF};
        }

        coverpoint addr_in[3:0] iff (reset == 0){
            bins ai_b1_min = {4'h0};  
            bins ai_b1 = { 4'h1,4'h2};  
            bins ai_b1_max = {4'h3};  
            // illegal_bins ai_i_b1 = {[4'h4:4'hF]};
        }

        coverpoint addr_in[7:4] iff (reset == 0){
            bins ai_b2_min = {4'h0};  
            bins ai_b2 = { 4'h1,4'h2};  
            bins ai_b2_max = {4'h3};         
            // illegal_bins ai_i_b2 = {[4'h4:4'hF]};
        }

        coverpoint addr_in[11:8] iff (reset == 0){
            bins ai_b3_min = {4'h0};  
            bins ai_b3 = { 4'h1,4'h2};  
            bins ai_b3_max = {4'h3};         
            // illegal_bins ai_i_b3 = {[4'h4:4'hF]};
        }

        coverpoint addr_in[15:12] iff (reset == 0){    
            bins ai_b4_min = {4'h0};  
            bins ai_b4 = { 4'h1,4'h2};  
            bins ai_b4_max = {4'h3};         
            // illegal_bins ai_i_b14 = {[4'h4:4'hF]};
        }
    
        coverpoint valid_in iff (reset == 0){
            bins valid_in_min = {4'h0};
            bins valid_in_bin = {[4'h1:4'hE]};
            // bins valid_in_falling = ([4'h1:4'hF] => 4'h0);
            // bins valid_in_rising = (4'h0 => [4'h1:4'hF]);
            bins valid_in_max = {4'hF};
        }

        coverpoint data_read iff (reset == 0){
            bins data_read_min = {4'h0};
            bins data_read_bin = {[4'h1:4'hE]};
            // bins data_read_falling = ([4'h1:4'hF] => 4'h0);
            // bins data_read_rising = (4'h0 => [4'h1:4'hF]);
            bins data_read_max = {4'hF};
        }
    endgroup

    function new(string name, uvm_component parent);
      super.new(name, parent);
      cg = new;
    endfunction: new

    // WORKING FOR EVERYTHING
    function void write(transaction t);
    `uvm_info("mg", $psprintf("Scoreboard received transaction %s", t.convert2string()), UVM_NONE);

      cg.sample();
      
      begin
        if (t.reset == 0) begin
          // DOUBLE FOR LOOP 1 - checks for addr_out, data_out, and data_rdy
          begin
            for (j = 0; j < 4; j = j + 1) begin
              // The above for loop switches from port 0 to 3 in order
              // Loop for each port
              // The below for loop is for bits in one port in order
              for (i = 0; i < 4; i = i + 1) begin
                if ((t.valid_in[i] == 1) && (t.addr_in[4*i +:4] == j)) begin
                  my_data_rdy[j] = 1;
                  if (((my_old_data_rdy[j] == 1) && (t.data_read[j] == 1)) || (my_old_data_rdy[j] == 0)) begin
                    my_addr_out[4*j +:4] = i;
                    my_data_out[4*j +:4] = t.data_in[4*i +:4];
                  end
                  break; // exit loop if condition is met
                end
              end
              if (i == 4) begin // Handling the else part outside the loop
                if (t.data_read[j] == 1) begin
                  my_data_rdy[j] = 0;
                end
                else begin
                  my_data_rdy[j] = my_data_rdy[j];
                end
              end
            end
          end

          // DOUBLE FOR LOOP 2 - checks for rcv_rdy 
          begin
            for(h = 0; h < 4; h++)begin
              // The above for loop switches from port 0 to 3 in order
              // Loop for each port
              // The below for loop is for bits in one port in order
              flag = 0;
              for(k = 0; k < 4; k ++) begin
                if ((t.valid_in[k] == 1) && (t.addr_in[k*4 +: 4] == h)) begin
                  if (((my_old_data_rdy[h] == 1 && t.data_read[h] == 1) || ((my_old_data_rdy[h] == 0))) && (flag == 0))begin
                    my_rcv_rdy[k] = 1;
                    flag = 1;
                  end
                  else begin
                    my_rcv_rdy[k] = 0;
                  end
                end 
              end
              if (k == 4) begin // Handling the else part outside the loop
                my_rcv_rdy[k] = my_rcv_rdy[k];
              end
            end
          end
        end
        else begin
          my_rcv_rdy  =  4'b1111;
          my_data_rdy =  4'b0000;
          my_addr_out = 16'hzzzz;
          my_data_out = 16'hzzzz;
        end
      end
      my_old_data_rdy  = my_data_rdy;

      if (!t.reset) begin

        // DATA_RDY COUNTER
        if (my_data_rdy === t.data_rdy) begin
            // $display("\t\033[32mPass (data_rdy)\033[0m");
            pass_count_DR++;
        end
        else if (my_data_rdy !== t.data_rdy) begin
            `uvm_error("data_rdy error", $sformatf("Error in data_rdy \n%s", expected_string("data_rdy")));
            fail_count_DR++;
        end
        
        // DATA_OUT COUNTER
        if (my_data_out === t.data_out) begin
            // $display("\t\033[32mPass (data_out)\033[0m");
            pass_count_DO++;
        end
        else if (my_data_out !== t.data_out) begin
            `uvm_error("data_out error", $sformatf("Error in data_out \n%s", expected_string("data_out")));
            fail_count_DO++;
        end
        
        // ADDR_OUT COUNTER
        if (my_addr_out === t.addr_out) begin
            // $display("\t\033[32mPass (addr_out)\033[0m");
            pass_count_AO++;
        end
        else if (my_addr_out !== t.addr_out) begin
            `uvm_error("addr_out error", $sformatf("Error in addr_out \n%s", expected_string("addr_out")));
            fail_count_AO++;
        end
        
        // RCV_RDY COUNTER
        if (my_rcv_rdy === t.rcv_rdy) begin
            // $display("\t\033[32mPass (rcv_rdy)\033[0m");
            pass_count_RR++;
        end
        else if (my_rcv_rdy !== t.rcv_rdy) begin
            `uvm_error("rcv_rdy error", $sformatf("Error in rcv_rdy \n%s", expected_string("rcv_rdy")));            
            fail_count_RR++;
        end
      end

    endfunction: write


    function string expected_string(string name);
      string string1, string5, result;
      string1 = $sformatf("\033[32m[Expected]\033[0m");
      result = {string1};
      
      if (name == "data_rdy") begin
        string5 = $sformatf("\tmy_data_rdy = %4b\n", my_data_rdy );
        result = {result, string5};
      end
      if (name == "data_out") begin
        string5 = $sformatf("\tmy_data_out = %4h\n", my_data_out );
        result = {result, string5};
      end
      if (name == "addr_out") begin
        string5 = $sformatf("\tmy_addr_out = %4h\n", my_addr_out );
        result = {result, string5};
      end
      if (name == "rcv_rdy") begin
        string5 = $sformatf("\tmy_rcv_rdy = %4b\n", my_rcv_rdy );
        result = {result, string5};
      end
      
      return $psprintf(result);

    endfunction: expected_string


    function string pass_fail_string;
      string string1, string2, string3, string4, result;
      string1 = $sformatf("\n\n\033[34mdata_rdy: %0d Pass and %0d Fail\033[0m",   pass_count_DR, fail_count_DR);
      string2 = $sformatf("\n\033[34mdata_out: %0d Pass and %0d Fail\033[0m",     pass_count_DO, fail_count_DO);
      string3 = $sformatf("\n\033[34maddr_out: %0d Pass and %0d Fail\033[0m",     pass_count_AO, fail_count_AO);
      string4 = $sformatf("\n\033[34mrcv_rdy:  %0d Pass and %0d Fail\033[0m\n",   pass_count_RR, fail_count_RR);
      
      result = {string1, string2, string3, string4};
      return $psprintf(result);
    endfunction: pass_fail_string

  endclass: scoreboard
  
  
  class env extends uvm_env;

    `uvm_component_utils(env)
    
    UVM_FILE   file_h;
    agent      agent_h;
    scoreboard scoreboard_h;
    
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
      agent_h      = agent     ::type_id::create("agent_h", this);
      scoreboard_h = scoreboard::type_id::create("scoreboard_h", this);
    endfunction: build_phase
    
    function void connect_phase(uvm_phase phase);
      agent_h.aport.connect( scoreboard_h.analysis_export );
    endfunction: connect_phase
    
    function void start_of_simulation_phase(uvm_phase phase);
    
      //uvm_top.set_report_verbosity_level_hier(UVM_NONE);
      uvm_top.set_report_verbosity_level_hier(UVM_HIGH);
      //uvm_top.set_report_severity_action_hier(UVM_INFO, UVM_NO_ACTION);
      //uvm_top.set_report_id_action_hier("ja", UVM_NO_ACTION);
      
      file_h = $fopen("uvm_lab_4.log", "w");
      uvm_top.set_report_default_file_hier(file_h);
      uvm_top.set_report_severity_action_hier(UVM_INFO, UVM_DISPLAY + UVM_LOG);

    endfunction: start_of_simulation_phase

    function void final_phase(uvm_phase phase);
      `uvm_info("mg", $psprintf("End of Result %s", scoreboard_h.pass_fail_string()), UVM_NONE);
    endfunction

  endclass: env
  

  // class seq_of_commands extends uvm_sequence #(transaction);
  
  //   `uvm_object_utils(seq_of_commands)
  //   `uvm_declare_p_sequencer(uvm_sequencer#(transaction))
    
  //   // int n = 1000; // = (5 + 3);
  //   int n = 5; // = (5 + 3);
    
  //   function new (string name = "");
  //     super.new(name);
  //   endfunction: new

  //   task body;
  //     repeat(n+5)
  //     begin
  //       read_modify_write seq;
  //       seq = read_modify_write::type_id::create("seq");
  //       assert( seq.randomize() );
  //       seq.start(p_sequencer);
  //     end
  //   endtask: body
   
  // endclass: seq_of_commands
  
  
  class test extends uvm_test;
  
    `uvm_component_utils(test)
    
    dut_config dut_config_0;
    env env_h;
   
    function new(string name, uvm_component parent);
	    super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
      dut_config_0 = new();

      if(!uvm_config_db #(virtual intf)::get( this, "", "driver_if", dut_config_0.driver_if))
        `uvm_fatal("NOVIF", "No virtual interface set")

      if(!uvm_config_db #(virtual intf)::get( this, "", "monitor_if", dut_config_0.monitor_if))
        `uvm_fatal("NOVIF", "No virtual interface set")

      // other DUT configuration settings
      uvm_config_db #(dut_config)::set(this, "*", "dut_config", dut_config_0);
      env_h = env::type_id::create("env_h", this);

    endfunction: build_phase
         
  endclass // test


  // This will only constrain the address to be 0123
  class test_sanity extends test;

   `uvm_component_utils(test_sanity)
	
    function new(string name, uvm_component parent);
	    super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      transaction::type_id::set_type_override(constraint_sanity_addr::get_type());
    endfunction: build_phase
    
    task run_phase(uvm_phase phase);

      seq_of_commands seq;
      seq = seq_of_commands::type_id::create("seq");

      // seq.n = 1000;

      assert(seq.randomize());
      phase.raise_objection(this);
      seq.start( env_h.agent_h.sequencer_h );
      phase.drop_objection(this);

    endtask: run_phase

  endclass: test_sanity
   

  // Totally random inputs
  class test_random extends test;
   `uvm_component_utils(test_random)
	
    function new(string name, uvm_component parent);
	    super.new(name, parent);
    endfunction: new
    
    task run_phase(uvm_phase phase);

      seq_of_commands seq;
      seq = seq_of_commands::type_id::create("seq");

      // seq.n = 1000;

      assert(seq.randomize());
      phase.raise_objection(this);
      seq.start( env_h.agent_h.sequencer_h );
      phase.drop_objection(this);

    endtask: run_phase

  endclass: test_random
   

  // All the ports in the address input will be same
  class test_duplicate_addr extends test;
  
    `uvm_component_utils(test_duplicate_addr)
	
    function new(string name, uvm_component parent);
	    super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      transaction::type_id::set_type_override(constraint_duplicate_addr::get_type());
    endfunction: build_phase
    
    task run_phase(uvm_phase phase);

      seq_of_commands seq;
      seq = seq_of_commands::type_id::create("seq");

      // seq.n = 1000;

      assert(seq.randomize());
      phase.raise_objection(this);
      seq.start( env_h.agent_h.sequencer_h );
      phase.drop_objection(this);

    endtask: run_phase

  endclass: test_duplicate_addr
   

  // All the ports in the addess will be unique values
  class test_unique_addr extends test;
    `uvm_component_utils(test_unique_addr)
	
    function new(string name, uvm_component parent);
	    super.new(name, parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      transaction::type_id::set_type_override(constraint_unique_addr::get_type());
    endfunction: build_phase
    
    task run_phase(uvm_phase phase);

      seq_of_commands seq;
      seq = seq_of_commands::type_id::create("seq");

      // seq.n = 1000;

      assert(seq.randomize());
      phase.raise_objection(this);
      seq.start( env_h.agent_h.sequencer_h );
      phase.drop_objection(this);

    endtask: run_phase

  endclass: test_unique_addr

endpackage: lab4_pkg
