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
This FSM implements a nested FSM for mode 1 of the inner product actor.
*******************************************************************************/

/*******************************************************************************
*  Parameters:      A. size -- the number of tokens (integers) in each
*                   input vector. So, if size = N, then this actor
*                   performs an N x N inner product.
*                   B. width -- the bit width for the integer data type
*                   used in the inner product operations
*******************************************************************************/
`timescale 1ns/1ps

module load_loc_mem_FSM_3
        #(parameter size = 3, width = 10)(  
        input clk, rst,
        input start_in,
        input [width - 1 : 0] data_in_fifo1,
        output reg rd_in_fifo1,
        output reg done_out,
        output reg wr_en,
        output reg [log2(size) - 1 : 0] wr_addr,
        output reg [width - 1 : 0] data_out_one);

    localparam START = 3'b000, STATE0_REN = 3'b001, STATE0_R = 3'b010, STATE1 = 3'b011, END = 3'b100;
  
    reg [2 : 0] state, next_state;
    reg [width - 1 : 0] temp_reg_one, next_temp_reg_one;
    reg [log2(size) - 1 : 0] counter, next_counter;
  
    always @(posedge clk or negedge rst)
    begin
        if (!rst)
        begin 
            state <= START;
            counter <= 0;
	        temp_reg_one <= 0;
        end
        else
        begin 
            state <= next_state;
            counter <= next_counter;
            temp_reg_one <= next_temp_reg_one;
        end
    end

    always @(state, start_in, counter)
        case (state)
        START:
            if (start_in)
                next_state <= STATE0_REN;
            else
                next_state <= START;		    

        STATE0_REN:
            next_state <= STATE0_R;
		
		STATE0_R:
            next_state <= STATE1;

        STATE1:
            if (counter == (size - 1))
                next_state <= END;
            else
                next_state <= STATE0_REN;
					 
        END:
            next_state <= START;
			
		 default:
				next_state <= START;
        endcase

	 
	 always @(state, start_in, counter,data_in_fifo1,temp_reg_one)
    begin 
        case (state)
        START:
	      begin 
            wr_en <= 0;
            done_out <= 0;
            next_counter <= 0;
            rd_in_fifo1 <= 0;
            wr_addr <= counter;
			next_temp_reg_one <= temp_reg_one;
			data_out_one <= temp_reg_one;
        end
        STATE0_REN:
        begin 			
			wr_en <= 0;
            done_out <= 0;
            next_counter <= counter;
            rd_in_fifo1 <= 1;
            wr_addr <= counter;
			next_temp_reg_one <= temp_reg_one;
			data_out_one <= temp_reg_one;
        end
        STATE0_R:
        begin 			
			wr_en <= 0;
            done_out <= 0;
            next_counter <= counter;
            rd_in_fifo1 <= 0;
            wr_addr <= counter;
			next_temp_reg_one <= data_in_fifo1;
			data_out_one <= temp_reg_one;
        end
        STATE1:
        begin 			
			wr_en <= 1;
            done_out <= 0;
            next_counter <= counter + 1;
            rd_in_fifo1 <= 0;
            wr_addr <= counter;
			next_temp_reg_one <= temp_reg_one;
			data_out_one <= temp_reg_one;

        end
        END:
        begin 
			wr_en <= 0;
            done_out <= 1;
            next_counter <= 0;
            rd_in_fifo1 <= 0;
            wr_addr <= counter;
			next_temp_reg_one <= temp_reg_one;
			data_out_one <= temp_reg_one;
        end
		  default:
			begin
		    wr_en <= 0;
            done_out <= 0;
            next_counter <= counter;
            rd_in_fifo1 <= 0;
            wr_addr <= 0;
			next_temp_reg_one <= temp_reg_one;
			data_out_one <= temp_reg_one;
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
  
