Project README
-------
Instructions to Run Parallelized (Control+FIFO16 Model):
1. 8 Input Channels x 8 Output Channels configuration
- Place input.txt, weight.txt, output.txt files (generated for 8x8 format) in "stimulus_files/1_ic_per_pe/"
- Run:
    - iverilog -o compiled -c filelist
    - vvp compiled
2. 16 Input Channels x 8 Output Channels configuration
- Place input.txt, weight.txt, output.txt files (generated for 16x8 format) in "stimulus_files/2_ic_per_pe/"
- Run:
    - iverilog -o compiled -c filelist_2_ic_per_pe
    - vvp compiled

Instructions to run Parallelized+Clock-Gated Model:
1. 8 Input Channels x 8 Output Channels configuration
- Place input.txt, weight.txt, output.txt files (generated for 8x8 format) in "stimulus_files/1_ic_per_pe/"
- Run:
    - iverilog -o compiled -c filelist_gated
    - vvp compiled
2. 16 Input Channels x 8 Output Channels configuration
- Place input.txt, weight.txt, output.txt files (generated for 16x8 format) in "stimulus_files/2_ic_per_pe/"
- Run:
    - iverilog -o compiled -c filelist_2_ic_per_pe_gated
    - vvp compiled

-------
Module heirarchy
Core
- Corelet
    - L0
    - MAC Array
    - OFIFO
    - SFP
- PSUM Memory (SRAM)
    - Simple memory that TB (Control) writes into and Corelet reads out of (via TB Control)
- Activation Memory (SRAM)
    - Simple memory that TB (Control) writes into and Corelet reads out of (via TB Control)
