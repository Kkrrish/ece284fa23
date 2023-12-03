// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps

module core_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_kij_dim_1 = 3;
parameter len_onij = 16;
parameter len_onij_dim_1 = 4;
parameter col = 8;
parameter row = 8;
parameter len_nij = 36;
parameter len_nij_dim_1 = 6;

reg clk = 0;
reg reset = 1;

wire [33:0] inst_q; 

reg [1:0]  inst_w_q = 0; 
reg [bw*row-1:0] D_xmem_q = 0;
reg CEN_xmem = 1;
reg WEN_xmem = 1;
reg [10:0] A_xmem = 0;
reg CEN_xmem_q = 1;
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;
reg CEN_pmem = 1;
reg WEN_pmem = 1;
reg [10:0] A_pmem = 0;
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg [10:0] A_pmem_q = 0;
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg acc = 0;

reg [1:0]  inst_w; 
reg [bw*row-1:0] D_xmem;
reg [psum_bw*col-1:0] answer;


reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;
reg [8*30:1] stringvar;
reg [8*30:1] w_file_name;
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij;
integer error;

// Verification variables
reg verbose = 1;
integer clk_cnt = 0;
reg [31:0] weight_in [col-1:0];
reg [31:0] data_in [len_nij-1:0];
reg [31:0] l0_data_out;
integer onij_scale, kij_scale;
integer onij_delta, kij_delta;
integer acc_addr;
integer l0_consec_wr_count = 0;
integer mac_consec_count = 0;

// Parallelising some stages
integer t_sram_to_l0 = 0;
integer t_l0_to_mac = 0;
wire l0_mac_series = 0;
integer t_ofifo_to_pmem = 0;
wire ofifo_pmem_series = 0;
integer kernel_using_xmem = 1;
integer activation_using_xmem = 0;
integer kernel_sram_l0 = 0;
integer activation_sram_l0 = 0;
integer xmem_busy = 0;
integer kij_xmem = 0;
integer kij_load = 0;
integer kij_execute = 0;

assign inst_q[33] = acc_q;
assign inst_q[32] = CEN_pmem_q;
assign inst_q[31] = WEN_pmem_q;
assign inst_q[30:20] = A_pmem_q;
assign inst_q[19]   = CEN_xmem_q;
assign inst_q[18]   = WEN_xmem_q;
assign inst_q[17:7] = A_xmem_q;
assign inst_q[6]   = ofifo_rd_q;
assign inst_q[5]   = ififo_wr_q;
assign inst_q[4]   = ififo_rd_q;
assign inst_q[3]   = l0_rd_q;
assign inst_q[2]   = l0_wr_q;
assign inst_q[1]   = execute_q; 
assign inst_q[0]   = load_q; 

core  #(.bw(bw), .col(col), .row(row)) core_instance (
  .clk(clk), 
  .inst(inst_q),
  .ofifo_valid(ofifo_valid),
  .D_xmem(D_xmem_q), 
  .sfp_out(sfp_out), 
  .reset(reset)
);

task tick_tock;
  input integer delay;
  begin
    for (i=0; i<delay ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end
  end
endtask

task kernel_loading_sram_to_l0;
  input [10:0] start_addr;
  input integer count;
  input data_is_weights;
  begin  
    for (t_sram_to_l0=0; t_sram_to_l0<count+1; t_sram_to_l0=t_sram_to_l0+1) begin  
      #0.5 clk = 1'b0;
      if(t_sram_to_l0 == 0) begin
        A_xmem = start_addr;
        WEN_xmem = 1;
        CEN_xmem = 0;
      end else begin
        A_xmem = A_xmem + 1;
        l0_wr = 1;
        //l0_rd = 0;
      end
      /*if(data_is_weights == 1) begin
        if(weight_in[t][31:0] == core_instance.xmem_inst.Q) begin
          $display("[%4d] %2d-th data from XMEM to L0 is %h --- Data matched", clk_cnt, t, core_instance.xmem_inst.Q);
        end else begin
        $display("[%4d] %2d-th data from XMEM to L0 is %h --- Data ERROR !!!", clk_cnt, t, core_instance.xmem_inst.Q);
        end
      end else begin
        if(data_in[t][31:0] == core_instance.xmem_inst.Q) begin
          $display("[%4d] %2d-th data from XMEM to L0 is %h --- Data matched", clk_cnt, t, core_instance.xmem_inst.Q);
        end else begin
        $display("[%4d] %2d-th data from XMEM to L0 is %h --- Data ERROR !!!", clk_cnt, t, core_instance.xmem_inst.Q);
        end
      end*/
      #0.5 clk = 1'b1;  
    end
    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; l0_wr = 0;
    #0.5 clk = 1'b1;
  end
endtask

task loading_l0_to_mac;
  input integer number_of_cycles;
  input ld_;
  input execute_;
  begin  
    for (t_l0_to_mac=0; t_l0_to_mac<number_of_cycles+1; t_l0_to_mac=t_l0_to_mac+1) begin
      #0.5 clk = 1'b0;
      if(t_l0_to_mac == 0) begin
        l0_rd = 1;
        load = ld_;
        execute = execute_;
      end
      if(t_l0_to_mac>(number_of_cycles-col)) begin
        l0_rd = 0;
        load = 0; execute = 0;
      end
      #0.5 clk = 1'b1;
    end
    #0.5 clk = 1'b0;  l0_rd = 0; load = 0; execute = 0;
    #0.5 clk = 1'b1;
  end
endtask

task read_ofifo_to_pmem;
  input [10:0] start_addr;
  input integer number_of_cycles;
  begin
    $display("[%4d] ==== Writing OFIFO data for kij %2d to PMEM ====", clk_cnt, kij_load);
    for (t_ofifo_to_pmem=0; t_ofifo_to_pmem<number_of_cycles+1; t_ofifo_to_pmem=t_ofifo_to_pmem+1) begin  
      #0.5 clk = 1'b0;
      if(t_ofifo_to_pmem == 0) begin
        ofifo_rd = 1;
        A_pmem = start_addr;
      end else begin
        WEN_pmem = 0;
        CEN_pmem = 0;
      end
      if(t_ofifo_to_pmem > 1) A_pmem = A_pmem + 1;
      //$display("[%4d] [%2dth] [SFP to PMEM] %h, Valid: %b", clk_cnt, t, core_instance.pmem_data_in, core_instance.pmem_wr_en);
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  WEN_pmem = 1;  CEN_pmem = 1; ofifo_rd = 0; A_pmem = A_pmem + 1;
    #0.5 clk = 1'b1;
  end
endtask

task write_activation_xmem;
  input integer count;
  begin
  x_file = $fopen("./stimulus_files/activation.txt", "r");
  // Following three lines are to remove the first three comment lines of the file
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);

  /////// Activation data writing to memory ///////
  $display("==== Writing activation data to XMEM ====");
  for (t=0; t<count; t=t+1) begin  
    #0.5 clk = 1'b0;
    x_scan_file = $fscanf(x_file,"%32b", D_xmem);
    WEN_xmem = 0;
    CEN_xmem = 0;
    if (t>0) A_xmem = A_xmem + 1;
    
    data_in[t][31:0] = D_xmem;
    if(verbose) $display("[%4d] %2d-th data from TB to XMEM is %h", clk_cnt, t, D_xmem);

    #0.5 clk = 1'b1;   
  end

  #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
  #0.5 clk = 1'b1; 

  $fclose(x_file);
  /////////////////////////////////////////////////
  end
endtask

task write_kernel_xmem;
  input [31:0] start_addr;
  input integer count;
  begin
    A_xmem = start_addr;
    for (t=0; t<count; t=t+1) begin  
      #0.5 clk = 1'b0;
      w_scan_file = $fscanf(w_file,"%32b", D_xmem);
      WEN_xmem = 0;
      CEN_xmem = 0;
      if (t>0) A_xmem = A_xmem + 1;

      weight_in[t][31:0] = D_xmem;
      if(verbose) $display("[%4d] %2d-th data from TB to XMEM is %h", clk_cnt, t, D_xmem);
      
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1;
  end
endtask

// Separate thread to maintain clock count
initial begin
  forever begin
    #0.5; clk_cnt=clk_cnt+1;
    #0.5;
  end
end

initial begin
  forever begin
    #0.5;
    if(core_instance.corelet_inst.l0_wr) begin
      l0_consec_wr_count=l0_consec_wr_count+1;
      $display("[%4d] [%3d] L0 Write: %h", clk_cnt, l0_consec_wr_count, core_instance.corelet_inst.l0_data_in);
    end else begin
      if(l0_consec_wr_count != 0) l0_consec_wr_count=0;
    end
    #0.5;
  end
end

initial begin
  forever begin
    #0.5;
    if((|core_instance.corelet_inst.mac_array_inst.inst_w_temp) == 1) begin
      mac_consec_count=mac_consec_count+1;
      $display("[%4d] [%3d] MAC inst: %2b, data: %h", clk_cnt, mac_consec_count, core_instance.corelet_inst.mac_array_inst.inst_w_temp, core_instance.corelet_inst.mac_array_inst.in_w);
    end else begin
      if(mac_consec_count != 0) mac_consec_count=0;
    end
    #0.5;
  end
end

// Temporary Thread to monitor outputs from MAC Array
initial begin
  forever begin
    #0.5;
    if(|core_instance.corelet_inst.mac_valid) $display("[%4d]                               PSUM: %h, Valid: %b", clk_cnt, core_instance.corelet_inst.mac_out_s, core_instance.corelet_inst.mac_valid);
    #0.5;
  end
end

// Temporary Thread to monitor writes to PMEM
initial begin
  forever begin
    #0.5;
    if(!core_instance.pmem_chip_en & !core_instance.pmem_wr_en) $display("[%4d]                                                               PMEM Addr: %h, Data: %h", clk_cnt, core_instance.pmem_addr_in, core_instance.pmem_data_in);
    #0.5;
  end
end

initial begin 

  inst_w   = 0; 
  D_xmem   = 0;
  CEN_xmem = 1;
  WEN_xmem = 1;
  A_xmem   = 0;
  ofifo_rd = 0;
  ififo_wr = 0;
  ififo_rd = 0;
  l0_rd    = 0;
  l0_wr    = 0;
  execute  = 0;
  load     = 0;

  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);

  activation_using_xmem = 1;
  //////// Reset /////////
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 

  tick_tock(5);

  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 

  #0.5 clk = 1'b0;   
  #0.5 clk = 1'b1;   
  /////////////////////////

  
  write_activation_xmem(len_nij);
  activation_using_xmem = 0;
  
  w_file_name = "./stimulus_files/weight.txt";  

  w_file = $fopen(w_file_name, "r");
  // Following three lines are to remove the first three comment lines of the file
  w_scan_file = $fscanf(w_file,"%s", captured_data);
  w_scan_file = $fscanf(w_file,"%s", captured_data);
  w_scan_file = $fscanf(w_file,"%s", captured_data);

  fork
    begin
      for (kij_xmem=0; kij_xmem<9; kij_xmem=kij_xmem+1) begin  // kij loop
      
        wait(!xmem_busy);
        kernel_using_xmem = 1;
        tick_tock(1);   

        /////// Kernel data writing to memory ///////
        $display("==== Writing kernel data for kij %2d to XMEM ====", kij_xmem);
        A_xmem = 11'b10000000000;

        write_kernel_xmem(A_xmem, col);
        tick_tock(1);
        kernel_using_xmem = 0;
        /////////////////////////////////////
        tick_tock(5);
        wait(xmem_busy);
      end
    end

    begin
      tick_tock(5);
      for (kij_load=0; kij_load<9; kij_load=kij_load+1) begin  // kij loop
        wait(!kernel_using_xmem);
        xmem_busy = 1;
        #0.5 clk = 1'b0;   reset = 1;
        #0.5 clk = 1'b1; 

        tick_tock(5);

        #0.5 clk = 1'b0;   reset = 0;
        #0.5 clk = 1'b1; 

        if(l0_mac_series) begin
          /////// Kernel data writing to L0 ///////
          kernel_loading_sram_to_l0(11'b10000000000, col, 1);
          /////////////////////////////////////

          /////// Kernel loading to PEs ///////
          loading_l0_to_mac(2*col-1, 1, 0);
          /////////////////////////////////////
        end else begin
          fork
            begin
              kernel_loading_sram_to_l0(11'b10000000000, col, 1);
            end

            begin
              tick_tock(1);
              loading_l0_to_mac(2*col-1, 1, 0);
            end
          join
        end

        if(l0_mac_series) begin
          ////// provide some intermission to clear up the kernel loading ///
          tick_tock(col);
          /////////////////////////////////////
          
          /////// Activation data writing to L0 ///////
          kernel_loading_sram_to_l0(11'b00000000000, len_nij, 0);
          /////////////////////////////////////

          /////// Execution ///////
          loading_l0_to_mac(len_nij+col-1, 0, 1);
          /////////////////////////////////////
          xmem_busy = 0;
        end else begin
          fork
            begin
              kernel_loading_sram_to_l0(11'b00000000000, len_nij, 0);
              xmem_busy = 0;
            end

            begin
              tick_tock(1);
              loading_l0_to_mac(len_nij+col-1, 0, 1);
              
            end

            if(!ofifo_pmem_series) begin
              wait((&core_instance.corelet_inst.mac_valid));
              read_ofifo_to_pmem(A_pmem, len_nij);
            end
          join
        end
        

        //////// OFIFO READ ////////
        // Ideally, OFIFO should be read while execution, but we have enough ofifo
        // depth so we can fetch out after execution.
        if(ofifo_pmem_series) begin
          tick_tock(col);
          read_ofifo_to_pmem(A_pmem, len_nij);
        end
        /////////////////////////////////////
      end  // end of kij loop
    end
  join

  tick_tock(2);

  ////////// Accumulation /////////
  out_file = $fopen("./stimulus_files/psum.txt", "r");  

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;

  $display("############ Verification Start during accumulation #############"); 
  
  for (i=0; i<len_onij+1; i=i+1) begin 

    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1; 

    if (i>0) begin
      $display("[%4d] [%2dth] sfp_out: %h", clk_cnt, i, core_instance.sfp_out);
      out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
      if (sfp_out == answer)
        $display("%2d-th output featuremap Data matched! :D", i); 
      else begin
        $display("%2d-th output featuremap Data ERROR!!", i); 
        $display("sfpout: %h", sfp_out);
        $display("answer: %h", answer);
        error = 1;
      end
    end

    if(i < len_onij) begin 
      #0.5 clk = 1'b0; reset = 1;
      #0.5 clk = 1'b1;  
      #0.5 clk = 1'b0; reset = 0; 
      #0.5 clk = 1'b1;  

      onij_scale = i/len_onij_dim_1;
      onij_delta = i - (onij_scale*len_onij_dim_1);
      //$display("onij: %d, onij_scale: %d, onij_delta: %d", i, onij_scale, onij_delta);
      
      for (j=0; j<len_kij+1; j=j+1) begin
        #0.5 clk = 1'b0;
        
        kij_scale = j/len_kij_dim_1;
        kij_delta = j - (kij_scale*len_kij_dim_1);
        //$display("kij: %d, kij_scale: %d, kij_delta: %d", j, kij_scale, kij_delta);
        
        if (j<len_kij) begin
          CEN_pmem = 0;
          WEN_pmem = 1;
          A_pmem = j*len_nij + (onij_scale*len_nij_dim_1+onij_delta) + (kij_scale*len_nij_dim_1+kij_delta);
        end else begin
          CEN_pmem = 1;
          WEN_pmem = 1;
        end
        if (j>0)  acc = 1;
        #0.5 clk = 1'b1;   
      end

      #0.5 clk = 1'b0;
      acc = 0;
      #0.5 clk = 1'b1;
    end
  end

  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 

  end

  //////////////////////////////////

  //tick_tock(5);
  $display("[%4d] Last cycle", clk_cnt);
  $finish;

end

always @ (posedge clk) begin
   inst_w_q   <= inst_w; 
   D_xmem_q   <= D_xmem;
   CEN_xmem_q <= CEN_xmem;
   WEN_xmem_q <= WEN_xmem;
   A_pmem_q   <= A_pmem;
   CEN_pmem_q <= CEN_pmem;
   WEN_pmem_q <= WEN_pmem;
   A_xmem_q   <= A_xmem;
   ofifo_rd_q <= ofifo_rd;
   acc_q      <= acc;
   ififo_wr_q <= ififo_wr;
   ififo_rd_q <= ififo_rd;
   l0_rd_q    <= l0_rd;
   l0_wr_q    <= l0_wr ;
   execute_q  <= execute;
   load_q     <= load;
end


endmodule




