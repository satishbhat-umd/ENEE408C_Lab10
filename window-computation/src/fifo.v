/******************************************************************************
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
* Name: fifo module
* Description: LWDF-V fifo module 
* Sub modules: None
* Input ports: wr_en: write enable for the fifo 
*              rd_en: read enable for the fifo
*              data_in: data for writing into the fifo
* Output ports: data_out: data that is read out of the fifo
*               population: number of tokens in the fifo
			    free_space: current free space level (number of empty tokens) in the fifo
* Regs & wires: rd_addr: fifo read address (read pointer)
*               wr_addr: fifo write address (write pointer)
* Parameters: buffer_size: max. number of tokens that can coexist in the fifo
*             width: bit width of each token
******************************************************************************/

`timescale 1ns / 1ns

module fifo #(parameter buffer_size = 5, width = 6)
(
    input clk, rst,
    input wr_en, rd_en,
    input[width - 1 : 0] data_in,
    output reg [log2(buffer_size) - 1 : 0] population,
    output [log2(buffer_size) - 1 : 0] free_space,
    output reg [width - 1 : 0] data_out     
);
    reg [width - 1 : 0] FIFO_RAM [0 : buffer_size - 1];
    reg [log2(buffer_size) - 1 : 0] rd_addr, wr_addr;
	reg full;
	
	always @(posedge clk)
	    if(wr_en)
		    FIFO_RAM[wr_addr] <= data_in;
			
	always @(posedge clk)
	    if(rd_en)
		    data_out <= FIFO_RAM[rd_addr];
	
	/*Write address update*/
    always @(posedge clk or negedge rst)
	    if(!rst)
			wr_addr <= 0;
		else if(wr_en)
			wr_addr <= (wr_addr != buffer_size - 1) ? wr_addr + 1 : 0;
	 
	/*Read address update*/
	always @(posedge clk or negedge rst)
	    if(!rst)
			rd_addr <= 0;
		else if(rd_en)
			rd_addr <= (rd_addr != buffer_size - 1) ? rd_addr + 1 : 0;

	always @(posedge clk)
		if(population == buffer_size - 1 && (wr_en&&!rd_en))
			full <= 1;
		else if(population!=buffer_size && (!wr_en&&rd_en))
			full <= 0;
		else if(population==0)
			full <= 0;
	
	/*Population update*/
	always @(wr_addr or rd_addr or full)
		if (full)
			population = buffer_size;
		else if(wr_addr == rd_addr)
			population = 0;
		else if(wr_addr > rd_addr)
			population = wr_addr - rd_addr;
		else
			population = buffer_size - (rd_addr - wr_addr);
	
    assign free_space = buffer_size-population;
      
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
