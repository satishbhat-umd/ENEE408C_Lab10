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

/*******************************************************************************
This FSM implements the core computational mode for the inner product actor.
*******************************************************************************/

/*******************************************************************************
*  Parameters:      A. size -- the number of tokens (integers) in each
*                   input vector. So, if size = N, then this actor
*                   performs an N x N inner product.
*   
*                   B. width -- the bit width for the integer data type
*                   used in the inner product operations
*******************************************************************************/
`timescale 1ns/1ps

module accumulator_mode_FSM_3
        #(parameter size = 3, width = 10)(  
        input clk, rst,
        input start_in,
        input [width - 1 : 0] ram_out1,
		input [width - 1 : 0] length_in [0 : 2],
		input [1 : 0] command_in [0 : 2],
        output reg done_out,
        output reg rd_en,
        output [log2(size) - 1 : 0] rd_addr,
        output reg [width - 1 : 0] acc);

    localparam START = 2'b00, STATE0 = 2'b01, STATE1 = 2'b10, END = 2'b11;
  
    reg [1 : 0] state, next_state;
    reg [width - 1 : 0] next_acc;
    reg [log2(size) - 1 : 0] counter, next_counter;
  	reg [width - 1 : 0] length, next_length;
	reg [1 : 0] command, next_command;

    always @(posedge clk or negedge rst)
    begin
        if (!rst)
        begin 
            state <= START;
            acc <= 0;
	        counter <= 0;
        	length <= length_in[0]
			command <= command_in[0];
		end
        else
        begin 
            state <= next_state;
            acc <= next_acc;
	        counter <= next_counter;
			length <= next_length;
			command <= next_command;
        end
    end
  
    assign rd_addr = counter;

    always @(state, start_in, counter)
    begin 
        case (state)
	      START:
	      begin
            if (start_in)
                next_state <= STATE0;
            else
                next_state <= START;		    
        end
        STATE0:
        begin 
            next_state <= STATE1;
        end
        STATE1:
        begin 
            if (counter == (size - 1))
                next_state <= END;
            else
                next_state <= STATE1;
        end
        END:
        begin 	    
            next_state <= START;
        end
        endcase
    end
	
	always @(state, start_in, ram_out1, counter, acc)
        case (state)
	        START:
				begin
				done_out <= 0;
				next_acc <= acc;
				next_counter <= 0;
				next_length <= 0;
				next_command <= 0;
				rd_en <= 0;    
				end
            STATE0:
				begin 		
				done_out <= 0;
				next_acc <= ram_out1;
				next_counter <= counter + 1;
				next_length <= 0; 
				rd_en <= 1;  
				end
            STATE1:
				begin 		
				done_out <= 0;
				next_acc <= acc + ram_out1 * ram_out2;
				next_counter <= counter + 1;
				rd_en <= 1; 
				end
            END:
				begin 
				done_out <= 1;
				next_acc <= acc;
				next_counter <= 0;
				rd_en <= 0;            	    
				end
		    default:
				begin
				done_out <= 0;
				next_acc <= acc;
				next_counter <= 0;
				rd_en <= 0;    
				end
        endcase

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
  
