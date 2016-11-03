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
* Name            : stream invoke module 
* Description     : top-level for invoke module of stream actor
* FSM description : IDLE state -- the actor is not executing
*                   FIRING_START state -- the actor start to execute by 
*                   entering sub-level FSM                   
*                   FIRING_WAIT state -- the actor is executing before  
*                   done_out signal  
* Sub modules     : firing_state_FSM2 (level 2 FSM for execution part of actor)
* Input ports     : data_FIFO -- data from input fifo1
*                   length_FIFO -- length from input fifo2
		    command_FIFO -- command from input fifo3
*                   invoke - LWDF-V standard actor invoke signal
*                   next_mode_in -- LWDF-V standard next mode in signal
* Output ports    : rd_in_fifo1 -- read enable signal for input fifo1
*                   rd_in_fifo2 -- read enable signal for input fifo2
*                   rd_in_fifo3 -- read enable signal for input fifo3
*                   next_mode_out -- LWDF-V standard next mode out signal
*                   FC - LWDF-V standard firing complete signal  
*                   wr_out_fifo1 -- output fifo write enable signal
*                   data_out -- output data for writing into output fifo
*  Parameters     : A. size -- the number of tokens (integers) in each
*                   input vector. So, if size = N, then this actor
*                   performs an N x N inner product.
*                   B. width -- the bit width for the integer data type
*                   used in the inner product operations
*
* The actor is a CFDF actor.
* The actor has three modes: m1, m2, m3.
* For each dataflow input edge, and each mode m, the actor has
* the same consumption rate C on each edge. The production rate
* on the output edge is denoted by P. The following table shows
* the production and consumption rates for the actors modes.
* -------------------
* Mode      C       P
* -------------------
* setup_comp 0 1 1 0
* comp       L 0 0 0
* output     0 0 0 1
* -------------------
******************************************************************************/
`timescale 1ns/1ps

module stream_comp_invoke_top_module_1
        #(parameter size = 3, width = 10)(    
        input clk,rst,
        input [width - 1 : 0] data_FIFO,
        input [width - 1 : 0] length_FIFO, 
        input [width - 1 : 0] command_FIFO, 
        input invoke,
        input [1 : 0] next_mode_in,
        output rd_in_data_FIFO,
        output rd_in_length_FIFO,
        output rd_in_command_FIFO,
        output [1 : 0] next_mode_out,
        output FC,
        output wr_out_fifo1,
        output [width - 1 : 0] data_out);

    localparam STATE_IDLE = 2'b00, STATE_FIRING_START = 2'b01, 
               STATE_FIRING_WAIT = 2'b10;
    localparam SETUP_COMP = 2'b00, COMP = 2'b01, OUTPUT = 2'b10;
      
    reg [1 : 0] state_module, next_state_module;
    reg start_in_child;
    
    wire done_out_child;

    assign FC = done_out_child;

    /* Instantiation of nested FSM for actor firing state. */         
    firing_state_FSM2 #(.size(size), .width(width)) 
            FSM2(clk, rst, data_FIFO, 
            length_FIFO, command_FIFO, start_in_child, next_mode_in, rd_in_data_FIFO, 
            rd_in_length_FIFO, rd_in_command_FIFO, next_mode_out, done_out_child, wr_out_fifo1, data_out);
         
    always @(posedge clk) 
    begin 
        if (!rst)
        begin 
            state_module <= STATE_IDLE;
        end
        else
        begin 
            state_module <= next_state_module;
        end
    end
   
    /* State evolution of the top-level FSM for this module */ 
    always @(state_module, invoke, done_out_child) 
    begin 
        case (state_module)
        STATE_IDLE:
        begin
            /* This is a leaf-level state */
            if (invoke)
            begin
                next_state_module <= STATE_FIRING_START;
            end    
            else
            begin
                next_state_module <= STATE_IDLE;
            end
        end
        STATE_FIRING_START:
        begin 
            /* Configure and execute nested FSM */
            next_state_module <= STATE_FIRING_WAIT;
        end
        STATE_FIRING_WAIT:
        begin
            /* Continue after nested FSM completes */
            if (done_out_child) 
                next_state_module <= STATE_IDLE;
            else
                next_state_module <= STATE_FIRING_WAIT;
        end
        default:
        begin
            next_state_module <= STATE_IDLE;
        end
        endcase
    end
	
	/* start_in_child signal assignment */
	always @(state_module) 
	begin
        case (state_module)
			STATE_IDLE:  start_in_child <= 0;

			STATE_FIRING_START: start_in_child <= 1;
	 
			STATE_FIRING_WAIT: start_in_child <= 0;
			  
			default: start_in_child <= 0;
        endcase
	end
    
endmodule    
