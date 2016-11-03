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
* Name: inner product enable module
* Description: enable module for inner product actor, this actor has three
*              modes (MODE_ONE, MODE_TWO, MODE_THREE)
* Sub modules: None
* Input ports: pop_in_fifo1 - population of input fifo1
*              pop_in_fifo2 - population of input fifo2 
*              free_space_fifo1 - free space of output fifo1
*              mode - inner product actor mode for checking enable condition
* Output port: enable (active high)
*
* Refer to the corresponding invoke module (invoke_top_module_1.v) for 
* documentation about the actor modes and their production and consumption 
* rates.
******************************************************************************/

`timescale 1ns / 1ps
module innner_product_enable
        #(parameter size = 3, buffer_size = 5, buffer_size_out = 1)(
        input rst,
        input [log2(buffer_size) - 1 : 0] pop_in_fifo1,
        input [log2(buffer_size) - 1 : 0] pop_in_fifo2,
        input [log2(buffer_size_out) - 1 : 0] free_space_fifo1,
        input [1 : 0] mode,
        output reg enable);
  
    localparam MODE_ONE = 2'b00, MODE_TWO = 2'b01, MODE_THREE = 2'b10;
 
    always @(mode, pop_in_fifo1, pop_in_fifo2, free_space_fifo1)
    begin 
        case (mode)
        MODE_ONE:
        begin
            if (pop_in_fifo1 >= size && pop_in_fifo2 >= size)
                enable <= 1;
            else
                enable <= 0;
        end
        MODE_TWO:
        begin
            enable <= 1;
        end    
        MODE_THREE:
        begin 
            if (free_space_fifo1 >= 1)
                enable <= 1;
        end
        default:
        begin 
            enable <= 0;
        end
        endcase
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
