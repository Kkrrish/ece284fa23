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
    #0.5 clk = 1'b0;
    A_xmem = start_addr;
    WEN_xmem = 1;
    CEN_xmem = 0;
    l0_wr = 1;
    l0_rd = 0;
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0; A_xmem = A_xmem + 1;
    #0.5 clk = 1'b1;
    for (t=0; t<count; t=t+1) begin  
      #0.5 clk = 1'b0;
      A_xmem = A_xmem + 1;
      if(data_is_weights == 1) begin
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
      end 
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
    #0.5 clk = 1'b0;
    l0_rd = 1;  // Read out from L0
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0;
    load = ld_;   // Load into MAC
    execute = execute_;
    #0.5 clk = 1'b1;
    tick_tock(1);
    for (t=0; t<number_of_cycles; t=t+1) begin
      #0.5 clk = 1'b0;
      if(t>(number_of_cycles-col-2)) begin
        load = 0; execute = 0;
      end
      l0_data_out = core_instance.corelet_inst.l0_data_out;
      $display("[%4d] [%2dth] [L0 to MAC]   %h", clk_cnt, t, core_instance.corelet_inst.l0_data_out);
      //$display("[%4d]                               OUT_S: %h", clk_cnt, core_instance.corelet_inst.mac_array_inst.row_num[1].mac_row_instance.out_s);
      //$display("[%4d]                               IN_N : %h", clk_cnt, core_instance.corelet_inst.mac_array_inst.row_num[1].mac_row_instance.col_num[1].mac_tile_instance.in_n);
      //$display("[%4d]                               A_Q : %h", clk_cnt, core_instance.corelet_inst.mac_array_inst.row_num[1].mac_row_instance.col_num[1].mac_tile_instance.a_q);
      //$display("[%4d]                               B_Q : %h", clk_cnt, core_instance.corelet_inst.mac_array_inst.row_num[1].mac_row_instance.col_num[1].mac_tile_instance.b_q);
      //$display("[%4d]                               C_Q : %h", clk_cnt, core_instance.corelet_inst.mac_array_inst.row_num[1].mac_row_instance.col_num[1].mac_tile_instance.c_q);
      //$display("[%4d] MAC inst %h, input %h, load_ready_q %b, weight %b", clk_cnt, core_instance.corelet_inst.mac_array_inst.row_num[8].mac_row_instance.col_num[8].mac_tile_instance.inst_w, core_instance.corelet_inst.mac_array_inst.row_num[8].mac_row_instance.col_num[8].mac_tile_instance.in_w, core_instance.corelet_inst.mac_array_inst.row_num[8].mac_row_instance.col_num[8].mac_tile_instance.load_ready_q, core_instance.corelet_inst.mac_array_inst.row_num[8].mac_row_instance.col_num[8].mac_tile_instance.b_q );
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
    $display("==== Writing OFIFO data for kij %2d to PMEM ====", kij);
    #0.5 clk = 1'b0;
    ofifo_rd = 1;
    A_pmem = start_addr;
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0;
    WEN_pmem = 0;
    CEN_pmem = 0; 
    #0.5 clk = 1'b1;
    for (t=0; t<number_of_cycles; t=t+1) begin  
      #0.5 clk = 1'b0;
      A_pmem = A_pmem + 1;
      //$display("[%4d] [%2dth] [SFP to PMEM] %h, Valid: %b", clk_cnt, t, core_instance.pmem_data_in, core_instance.pmem_wr_en);
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  WEN_pmem = 1;  CEN_pmem = 1; ofifo_rd = 0;
    #0.5 clk = 1'b1;
  end
endtask

task check_kernel_loading_at_mac;
  input bool dummy;
  begin
    //$display("[%4d] [check_kernel_loading_at_mac] Col %0d Row %0d:  RTL weight %h", clk_cnt, 0, 0, core_instance.corelet_inst.mac_array_inst.row_num[1].mac_row_instance.col_num[1].mac_tile_instance.b_q);
    //for (i=0; i<col; i=i+1) begin
    //  for (j=0; j<row; j=j+1) begin
        //if(core_instance.corelet_inst.mac_array_inst.mac_row_instance[j].mac_tile_instance[i].mac_instance.b_q != weight[t][bw*(j+1)-1:bw*j]) begin
        //  $display("[%4d] [check_kernel_loading_at_mac] Col %0d Row %0d:  RTL weight %4b, DV weight %4b", clk_cnt, i, j, weight[t][bw*(j+1)-1:bw*j], core_instance.corelet_inst.mac_array_inst.mac_row_instance[j].mac_tile_instance[i].mac_instance.b_q);
        //end
    //    $display("[%4d] [check_kernel_loading_at_mac] Col %0d Row %0d:  RTL weight %h", clk_cnt, i, j, core_instance.corelet_inst.mac_array_inst.row_num[j].mac_row_instance.col_num[i].mac_tile_instance.b_q);
    //  end
    //end
  end
endtask

// Separate thread to maintain clock count
initial begin
  forever begin
    #0.5; clk_cnt=clk_cnt+1;
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

  //@FIXME
  x_file = $fopen("./stimulus_files/activation_tile0.txt", "r");
  // Following three lines are to remove the first three comment lines of the file
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);

  //////// Reset /////////
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 

  tick_tock(5);

  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 

  #0.5 clk = 1'b0;   
  #0.5 clk = 1'b1;   
  /////////////////////////

  //@FIXME
  /////// Activation data writing to memory ///////
  $display("==== Writing activation data to XMEM ====");
  for (t=0; t<len_nij; t=t+1) begin  
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


  for (kij=0; kij<9; kij=kij+1) begin  // kij loop

    //@FIXME
    case(kij)
     0: w_file_name = "./stimulus_files/weight_itile0_otile0_kij0.txt";
     1: w_file_name = "./stimulus_files/weight_itile0_otile0_kij1.txt";
     2: w_file_name = "./stimulus_files/weight_itile0_otile0_kij2.txt";
     3: w_file_name = "./stimulus_files/weight_itile0_otile0_kij3.txt";
     4: w_file_name = "./stimulus_files/weight_itile0_otile0_kij4.txt";
     5: w_file_name = "./stimulus_files/weight_itile0_otile0_kij5.txt";
     6: w_file_name = "./stimulus_files/weight_itile0_otile0_kij6.txt";
     7: w_file_name = "./stimulus_files/weight_itile0_otile0_kij7.txt";
     8: w_file_name = "./stimulus_files/weight_itile0_otile0_kij8.txt";
    endcase

    //@FIXME
    w_file_name = "./stimulus_files/weight.txt";
    

    w_file = $fopen(w_file_name, "r");
    // Following three lines are to remove the first three comment lines of the file
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);

    #0.5 clk = 1'b0;   reset = 1;
    #0.5 clk = 1'b1; 

    tick_tock(5);

    #0.5 clk = 1'b0;   reset = 0;
    #0.5 clk = 1'b1; 
    
    tick_tock(1);  

    /////// Kernel data writing to memory ///////
    $display("==== Writing kernel data for kij %2d to XMEM ====", kij);
    A_xmem = 11'b10000000000;

    for (t=0; t<col; t=t+1) begin  
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
    /////////////////////////////////////

    tick_tock(5);

    /////// Kernel data writing to L0 ///////
    kernel_loading_sram_to_l0(11'b10000000000, col, 1);
    /////////////////////////////////////

    /////// Kernel loading to PEs ///////
    loading_l0_to_mac(2*col-1, 1, 0);
    /////////////////////////////////////

    ////// provide some intermission to clear up the kernel loading ///
    tick_tock(col);
    check_kernel_loading_at_mac(0);
    /////////////////////////////////////

    /////// Activation data writing to L0 ///////
    kernel_loading_sram_to_l0(11'b00000000000, len_nij, 0);
    /////////////////////////////////////

    /////// Execution ///////
    loading_l0_to_mac(len_nij+col-1, 0, 1);
    /////////////////////////////////////

    tick_tock(col);

    //////// OFIFO READ ////////
    // Ideally, OFIFO should be read while execution, but we have enough ofifo
    // depth so we can fetch out after execution.
    read_ofifo_to_pmem(A_pmem, len_nij);
    /////////////////////////////////////


  end  // end of kij loop

  tick_tock(20);

  ////////// Accumulation /////////
  //out_file = $fopen("out.txt", "r");  

  // Following three lines are to remove the first three comment lines of the file
  //out_scan_file = $fscanf(out_file,"%s", answer); 
  //out_scan_file = $fscanf(out_file,"%s", answer); 
  //out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;

  $display("############ Verification Start during accumulation #############"); 
  
  for (i=0; i<len_onij+1; i=i+1) begin 

    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1; 

    if (i>0) begin
      $display("[%4d] [%2dth] sfp_out: %h", clk_cnt, i, core_instance.sfp_out);
      /*out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
      if (sfp_out == answer)
        $display("%2d-th output featuremap Data matched! :D", i); 
      else begin
        $display("%2d-th output featuremap Data ERROR!!", i); 
        $display("sfpout: %128b", sfp_out);
        $display("answer: %128b", answer);
        error = 1;
      end*/
    end
   
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

  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 

  end

  //////////////////////////////////

  tick_tock(100);
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




