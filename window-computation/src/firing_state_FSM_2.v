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
* Name            : Inner product invoke firing state FSM level 2
* Description     : A level 2 FSM. This FSM helps to implement the firing state 
*                   of the invoke module for the inner product actor 
*
* FSM description : STATE_START - nested FSM start state
*
*                   STATE_MODE_ONE_START - nested FSM for mode 1 start state
*                   
*                   STATE_MODE_ONE_WAIT - execute CFDF mode 1 for the inner 
*                   product actor (read input vectors in to local actor 
*                   memory). This state has two sub-states associated with 
*                   executing a nested FSM.
*                                    
*                   STATE_MODE_TWO_START - nested FSM for mode 2 start state
*
*                   STATE_MODE_TWO_WAIT - execute CFDF mode 2 for the inner 
*                   product actor (computer the inner product from local 
*                   memory). This state has two sub-states associated with 
*                   executing a nested FSM.
*
*                   STATE_MODE_THREE - execute CFDF mode 3 for the inner
*                   product actor (write the inner product result to the
*                   the output FIFO.
*
*                   STATE_END - nested FSM end state.
*                              
* Input ports     : data_in_fifo1 - data from input fifo1
*                   data_in_fifo2 - data from input fifo2
*                   start_in - nested FSM start signal from parent FSM
*                   next_mode_in - selected actor mode
*
* Output ports    : rd_in_fifo1 - read enable signal for input fifo1
*                   rd_in_fifo2 - read enable signal for input fifo2
*                   next_mode_out - CFDF next mode output for actor firing
*                   done_out - nested FSM end signal to parent FSM
*                   wr_out_fifo1 - output fifo write enable signal
*                   data_out - output data for writing into output fifo
*
*  Parameters     : A. size -- the number of tokens (integers) in each
*                   input vector. So, if size = N, then this actor
*                   performs an N x N inner product.
*                   B. width -- the bit width for the integer data type
*                   used in the inner product operations

******************************************************************************/
`timescale 1ns/1ps

module firing_state_FSM2
        #(parameter size = 3, width = 10)(
        input clk,rst,
        input [width - 1 : 0] data_in_fifo1,
        input [width - 1 : 0] data_in_fifo2, 
        input start_in,
        input [1 : 0] next_mode_in,
        output rd_in_fifo1,
        output rd_in_fifo2,
        output reg [1 : 0] next_mode_out,
        output reg done_out,
        output reg wr_out_fifo1,
        output reg [width - 1 : 0] data_out 
        );

    localparam MODE_ONE = 2'b00, MODE_TWO = 2'b01, MODE_THREE = 2'b10;
    localparam STATE_START = 3'b000, STATE_MODE_ONE_START = 3'b001, 
	        STATE_MODE_ONE_WAIT = 3'b010, STATE_MODE_TWO_START = 3'b011,
	        STATE_MODE_TWO_WAIT = 3'b100, STATE_MODE_THREE = 3'b101,
            STATE_END = 3'b110;

    reg [2 : 0] state_module, next_state_module;
    reg start_in_child_mode1, start_in_child_mode2;
    
    wire [width - 1 : 0] acc_out;
    wire [width - 1 : 0] ram_out1, ram_out2;
    wire [log2(size) - 1 : 0] wr_addr, rd_addr;
    wire [width - 1 : 0] data_out_one, data_out_two;
    wire rd_en;
        
    single_port_ram #(.size(size), .width(width))
            RAM1(data_out_one, wr_addr, rd_addr, wr_en_ram, rd_en, clk, 
            ram_out1);
    single_port_ram #(.size(size), .width(width))
            RAM2(data_out_two, wr_addr, rd_addr, wr_en_ram, rd_en, clk, 
            ram_out2);

    /* Instantiation of nested FSM for core compuation CFDF mode 1. */	    
    load_loc_mem_FSM_3 #(.size(size), .width(width))
            loc_mem(clk, rst, start_in_child_mode1, data_in_fifo1, 
            data_in_fifo2, rd_in_fifo1, rd_in_fifo2, done_out_child_mode1, 
            wr_en_ram, wr_addr, data_out_one, data_out_two);

    /* Instantiation of nested FSM for core compuation CFDF mode 2. */
    accumulator_mode_FSM_3 #(.size(size), .width(width)) accumulator(clk, rst, 
            start_in_child_mode2, ram_out1, ram_out2, done_out_child_mode2, 
            rd_en, rd_addr, acc_out);
       
    always @(posedge clk or negedge rst)
    begin 
        if(!rst)
        begin
            state_module <= STATE_START;
        end
        else
        begin 
            state_module <= next_state_module;
        end
    end
    
    /* State evolution of FSM_2 */ 	
    always @(state_module, start_in, done_out_child_mode1, 
            done_out_child_mode2, next_mode_in)
    begin 
        case (state_module)
        STATE_START:
        begin
            if (start_in)
                if(next_mode_in == MODE_ONE)
                    next_state_module <= STATE_MODE_ONE_START;
                else if (next_mode_in == MODE_TWO)
                    next_state_module <= STATE_MODE_TWO_START;
                else if (next_mode_in == MODE_THREE)
                    next_state_module <= STATE_MODE_THREE;
                else
                    next_state_module <= STATE_START;    
            else
                next_state_module <= STATE_START;
        end

        /***********************************************************************
        CFDF firing mode: "mode one"
        -- Consumption rate is size for each input FIFO.
        -- Production rate is 0 for the output FIFO.
        ***********************************************************************/
        STATE_MODE_ONE_START:
        /* This is a hierarchical state --- the core computaitonal mode */
        begin 
            next_state_module <= STATE_MODE_ONE_WAIT;
        end

        STATE_MODE_ONE_WAIT:
        begin
            /* Continue after nested FSM completes */
            if (done_out_child_mode1)
            begin
                next_state_module <= STATE_END;
            end
            else 
            begin
                next_state_module <= STATE_MODE_ONE_WAIT;
            end
        end

        /***********************************************************************
        CFDF firing mode: "mode two"
        -- Consumption rate is 0 for each input FIFO.
        -- Production rate is 0 for the output FIFO.
        This mode updates the internal state (accumulated inner product value)
        associated with the inner product.
        ***********************************************************************/
        STATE_MODE_TWO_START:
        begin
            /* Configure and execute nested FSM */
            next_state_module <= STATE_MODE_TWO_WAIT;
        end
        STATE_MODE_TWO_WAIT:
        begin
            /* Continue after nested FSM completes */
            if (done_out_child_mode2)
            begin
                next_state_module <= STATE_END;
            end
            else 
            begin
                next_state_module <= STATE_MODE_TWO_WAIT;
            end
        end

        /***********************************************************************
        CFDF firing mode: "mode three"
        -- Consumption rate is 0 for each input FIFO.
        -- Production rate is 1 for the output FIFO.
        ***********************************************************************/
        STATE_MODE_THREE:
        /* This is a leaf-level state (no nested FSM) */
        begin 
            next_state_module <= STATE_END;
        end
        STATE_END:
        /* This is a leaf-level state (no nested FSM) */
        begin 
            next_state_module <= STATE_START;
        end
        default:
        begin
            next_state_module <= STATE_START;
        end
        endcase
    end
	
	/*Output signal assignments*/
	always @(state_module, acc_out)
    begin 
        case (state_module)
        STATE_START:
        begin
            wr_out_fifo1 <= 0;
            start_in_child_mode1 <= 0;
            start_in_child_mode2 <= 0;
            done_out <= 0;
			data_out <= acc_out;
        end

        /***********************************************************************
        CFDF firing mode: "mode one"
        -- Consumption rate is size for each input FIFO.
        -- Production rate is 0 for the output FIFO.
        ***********************************************************************/
        STATE_MODE_ONE_START:
        /* This is a hierarchical state --- the core computaitonal mode */
        begin 
			wr_out_fifo1 <= 0;
            start_in_child_mode1 <= 1;
            start_in_child_mode2 <= 0;
            done_out <= 0;
			data_out <= acc_out;
        end

        STATE_MODE_ONE_WAIT:
        begin
            /* Continue after nested FSM completes */		
			wr_out_fifo1 <= 0;
            start_in_child_mode1 <= 0;
            start_in_child_mode2 <= 0;
            done_out <= 0; 
			data_out <= acc_out;
        end

        /***********************************************************************
        CFDF firing mode: "mode two"
        -- Consumption rate is 0 for each input FIFO.
        -- Production rate is 0 for the output FIFO.
        This mode updates the internal state (accumulated inner product value)
        associated with the inner product.
        ***********************************************************************/
        STATE_MODE_TWO_START:
        begin
			wr_out_fifo1 <= 0;
            start_in_child_mode1 <= 0;
            start_in_child_mode2 <= 1;
            done_out <= 0;
			data_out <= acc_out;
            /* Configure and execute nested FSM */
        end
        STATE_MODE_TWO_WAIT:
        begin
            /* Continue after nested FSM completes */
			wr_out_fifo1 <= 0;
            start_in_child_mode1 <= 0;
            start_in_child_mode2 <= 0;
            done_out <= 0;
			data_out <= acc_out;
         end

        /***********************************************************************
        CFDF firing mode: "mode three"
        -- Consumption rate is 0 for each input FIFO.
        -- Production rate is 1 for the output FIFO.
        ***********************************************************************/
        STATE_MODE_THREE:
        /* This is a leaf-level state (no nested FSM) */
        begin 
			wr_out_fifo1 <= 1;
            start_in_child_mode1 <= 0;
            start_in_child_mode2 <= 0;
            done_out <= 0;
			data_out <= acc_out;
        end
        STATE_END:
        /* This is a leaf-level state (no nested FSM) */
        begin 
			wr_out_fifo1 <= 0;
            start_in_child_mode1 <= 0;
            start_in_child_mode2 <= 0;
            done_out <= 1;
			data_out <= acc_out;
        end
        default:
        begin 
			wr_out_fifo1 <= 0;
            start_in_child_mode1 <= 0;
            start_in_child_mode2 <= 0;
            done_out <= 0;
			data_out <= acc_out;
        end
        endcase
    end

    function integer log2;
    input [31 : 0] value;
	integer i;
    begin
		  if(value==1)
				i=1;
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
               
