/*******************************************************************************
@ddblock_begin copyright
Copyright (c) 1997-2016
Maryland DSPCAD Research Group, The University of Maryland at College Park 
All rights reserved.

IN NO EVENT SHALL THE UNIVERSITY OF MARYLAND BE LIABLE TO ANY PARTY
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
THE UNIVERSITY OF MARYLAND HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

THE UNIVERSITY OF MARYLAND SPECIFICALLY DISCLAIMS ANY WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE
PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
MARYLAND HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
ENHANCEMENTS, OR MODIFICATIONS.

@ddblock_end copyright
******************************************************************************/

/******************************************************************************
* Name        : tb_inner_product_FSM
* Description : testbench for inner_product actor
* Sub modules : Two input fifos, one output fifos, inner_product invoke/enable
*               modules
******************************************************************************/

/*******************************************************************************
*  Parameters     : A. size -- the numer of tokens (integers) in each
*                   input vector. So, if size = N, then this actor
*                   performs an N x N inner product.
*                   B. width -- the bit width for the integer data type
*                   used in the inner product operations
*******************************************************************************/

`timescale 1ns/1ps
module tb_stream_comp_FSM();

    parameter buffer_size = 5, width = 10, buffer_size_out = 1;
    parameter SETUP_COMP = 2'b00, COMP = 2'b01, OUTPUT = 2'b10;

    /* Input vector size. */
    parameter size = 5;
  
    reg clk, rst; 
    reg invoke;
    reg wr_en_input;
    reg [width - 1:0] data_in;
    reg [1 : 0] next_mode_in;
    reg rd_en_fifo1;
    
    /* Input memories. */
    reg [width - 1 : 0] mem [0 : size - 1];
	reg [1 : 0] command_in [0 : 2];
	reg [width - 1 : 0] length_in [0 : 2];

    wire [1:0] next_mode_out;  
    wire [width - 1 : 0] data_in_fifo1, data_out, data_out_fifo1;
    wire [log2(buffer_size) - 1:0] pop_in_fifo1;
    wire [log2(buffer_size_out) - 1 : 0] pop_out_fifo1;
    wire [log2(buffer_size) - 1 : 0] free_space_fifo1;
    wire [log2(buffer_size_out) - 1 : 0] free_space_out_fifo1;
    wire FC; 
 
    integer i, j, k;
	integer length_file, command_file;
	
    /***************************************************************************
    Instantiate the input and output FIFOs for the actor under test.
    ***************************************************************************/

    fifo #(buffer_size, width) 
            in_fifo1 
            (clk, rst, wr_en_input, rd_in_fifo1, data_in, 
            pop_in_fifo1, free_space_fifo1, data_in_fifo1);

    fifo #(buffer_size_out, width) out_fifo1 
            (clk, rst, wr_out_fifo1, rd_en_fifo1, data_out, 
            pop_out_fifo1, free_space_out_fifo1, data_out_fifo1);

    /***************************************************************************
    Instantiate the enable and invoke modules for the actor under test.
    ***************************************************************************/

    stream_comp_invoke_top_module_1 #(.size(size), .width(width)) 
            invoke_module(clk, rst, 
            data_in_fifo1, length_in, command_in, invoke, next_mode_in,
            rd_in_fifo1, next_mode_out, FC, wr_out_fifo1, 
            data_out);
  
    stream_comp_enable #(.size(size), .buffer_size(buffer_size), 
            .buffer_size_out(buffer_size_out)) enable_module(rst, pop_in_fifo1, 
            free_space_out_fifo1, next_mode_in, enable);    

    integer descr;

    /***************************************************************************
    Generate the clock waveform for the test.
    The clock period is 2 time units.
    ***************************************************************************/
    initial 
    begin
        clk <= 0;
        for(j = 0; j < 100; j = j + 1)
        begin 
            #1 clk <= 1;
            #1 clk <= 0;
        end
    end
 
    /***************************************************************************
    Try to carry out three actor firings (to cycle through the three
    CFDF modes of the actor under test).
    ***************************************************************************/
    initial 
    begin 
        /* Set up a file to store the test output */
        descr = $fopen("out.txt");
        
        /* Read text files and load the data into memory for input of inner 
        product actor
        */
        $readmemh("data.txt", mem);
		length_file = $fopen("length.txt", "r");
		command_file = $fopen("command.txt", "r");

        #1;
        rst <= 0;
        wr_en_input <= 0;
        data_in_one <= 0;
		invoke <= 0;
        next_mode_in <= SETUP_COMP;		  
		rd_en_fifo1 <= 0;
		#2 rst <= 1;
        #2; 
    
        /* Write data into the input FIFOs. The FIFO requires a write enable
         * signal before the data is loaded, so "size" loop intereation are 
         * required here.
         */

		for (i = 0; i < 3; i = i + 1)
		begin
			$fscanf(length_file, "%d\n", length_in[i]);
			$fscanf(command_file, "%d\n", command_in[i]);
		end

        $fdisplay(descr, "Setting up input FIFOs");
        for (i = 0; i < size; i = i + 1)
        begin 
               #2; 
               data_in <= mem[i];
               #2;
               wr_en_input <= 1;
               $fdisplay(descr, "input1[%d] = %d", i, data_in);
               #2;
               wr_en_input  <= 0;
        end
 
        #2;     /* ensure that data is stored into memory before continuing */
        next_mode_in <= SETUP_COMP;
        #2;
        if (enable)
        begin
            $fdisplay(descr, "Executing firing for mode no. 1");
            invoke <= 1;
        end
        else  
        begin
            /* end the simulation here if we don't have enough data to fire */
            $fdisplay (descr, "Not enough data to fire the actor under test");
            $finish;
        end
        #2 invoke <= 0;

        /* Wait for mode 1 to complete */ 
        wait (FC) #2 next_mode_in <= COMP;
        #2;
        if (enable)
        begin
            $fdisplay(descr, "Executing firing for mode no. 2");
            invoke <= 1;
        end 
        else 
        begin 
            /* end the simulation here if we don't have enough data to fire */
            $fdisplay (descr, "Not enough data to fire the actor under test");
            $finish;
        end
        #2 invoke <= 0;
        
        /* Wait for mode 2 to complete */ 
        wait(FC) #2 next_mode_in <= OUTPUT;
        #2;
        if (enable)
        begin
            $fdisplay(descr, "Executing firing for mode no. 2");
            invoke <= 1;
        end 
        else 
        begin 
            /* end the simulation here if we don't have enough data to fire */
            $fdisplay (descr, "Not enough data to fire the actor under test");
            $finish;
        end
        #2 invoke <= 0;
        
        /* Wait for mode 3 to complete */ 
        wait(FC) #2;
        #2/* Read actor output value from result FIFO */
        rd_en_fifo1 <= 1;        
		
	    #2 
		rd_en_fifo1 <= 0;  
               
        #2;
		next_mode_in <= SETUP_COMP;
		
        /* Set up recording of results */
        $fdisplay(descr, "time = %d, FIFO[0] = %d", $time, out_fifo1.FIFO_RAM[0]);
        $fdisplay(descr, "time = %d, Result = %d", $time, data_out_fifo1);
        $display("time = %d, Result = %d", $time, data_out_fifo1);               
    end
 
    function integer log2;
    input [31 : 0] value;
	 integer i;
    begin
		  if(value==1)
				log2=1;
		  else
			  begin
			  i = value - 1;
			  for (log2 = 0; i > 0; log2 = log2 + 1) begin
					i = i >> 1;
			  end
			  end
    end
    endfunction 
  
endmodule


