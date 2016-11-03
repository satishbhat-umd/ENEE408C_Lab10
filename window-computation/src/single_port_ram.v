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
*******************************************************************************/

/*******************************************************************************
This is a single port RAM (random access memory) module.

--- INPUTS: ---

data:  data to be written into the RAM

addr:  RAM address for writing data

rd_addr: RAM address for reading data

wr_en: enable signal for activating write operation (active high)

rd_en: enable signal for activating reading operation (active high)

clk: clock

--- OUTPUT: ---

q: data that is read out of the RAM

--- PARAMETERS: ---    

size: the number of tokens (integers) in each input vector. So, if size =
N, then this actor performs an N x N inner product.  

width: the bit width for the integer data type used in the inner product 
operations
*******************************************************************************/

`timescale 1ns/1ps
module single_port_ram
        #(parameter size = 3, width = 10)(  
        input [width - 1 : 0] data,
        input [log2(size) - 1 : 0] addr,
        input [log2(size) - 1 : 0] rd_addr,
        input wr_en, re_en, clk,
        output [width - 1 : 0] q);

    /* Declare the RAM variable */
    reg [width - 1 : 0] ram[size - 1 : 0];
	
    /* Variable to hold the registered read address */
    reg [log2(size) - 1 : 0] addr_reg;
	
    always @ (posedge clk)
    begin
        /* Write */
        if (wr_en)
            ram[addr] <= data;
    end
		
		/* Read */
    assign q = (re_en) ? ram[rd_addr] : 0;
 
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
