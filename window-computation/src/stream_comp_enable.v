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
* Name: stream_comp enable module
* Description: enable module for stream_comp actor, this actor has three
*              modes (SETUP_COMP, COMP, OUTPUT)
* Sub modules: None
* Input ports: pop_data - population of input fifo1
*              pop_length - population of input fifo2 
			   pop_command - population of input fifo3
*              free_space - free space of output fifo1
*              mode - stream_comp actor mode for checking enable condition
* Output port: enable (active high)
*
* Refer to the corresponding invoke module (invoke_top_module_1.v) for 
* documentation about the actor modes and their production and consumption 
* rates.
******************************************************************************/

`timescale 1ns / 1ps
module stream_comp_enable
        #(parameter size = 3, buffer_size = 5, buffer_size_out = 1)(
        input rst,
        input [log2(buffer_size) - 1 : 0] pop_data,
		input [log2(buffer_size) - 1 : 0] pop_length,
        input [log2(buffer_size) - 1 : 0] pop_command,
        input [log2(buffer_size_out) - 1 : 0] free_space,
        input [1 : 0] mode,
        output reg enable);
  
    localparam SETUP_COMP = 2'b00, COMP = 2'b01, OUTPUT = 2'b10;
 
    always @(mode, pop_data, pop_length, pop_command, free_space)
    begin 
        case (mode)
        SETUP_COMP:
        begin
            if (pop_data >= size && pop_length >= size && pop_command >= size)
                enable <= 1;
            else
                enable <= 0;
        end
        COMP:
        begin
            enable <= 1;
        end    
        OUTPUT:
        begin 
            if (free_space >= 1)
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
