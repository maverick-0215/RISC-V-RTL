`timescale 1ns / 1ps

module type_decoder (opcode,r_type,i_type,load,store,branch,jal,jalr,lui,auipc,valid,load_signal_controller);

    input wire [6:0]opcode;
    input wire valid;
    input wire load_signal_controller; 
    
    output reg r_type;
    output reg i_type; 
    output reg load;
    output reg store;
    output reg branch; 
    output reg jal;
    output reg jalr;
    output reg lui;
    output reg auipc;

    always @(*)begin  
        case(opcode)
            7'b0110011:begin 
                r_type = 1'b1;
                i_type = 1'b0;
                store = 1'b0;
                load = 1'b0;
                branch = 1'b0;
                auipc = 1'b0; 
                jal = 1'b0; 
                jalr = 1'b0; 
                lui = 1'b0;
            end 
            7'b0010011:begin 
                r_type = 1'b0;
                i_type = 1'b1;
                store = 1'b0;
                load = 1'b0;
                branch = 1'b0;
                auipc = 1'b0; 
                jal = 1'b0; 
                jalr = 1'b0; 
                lui = 1'b0;
            end
            7'b0100011:begin 
                r_type = 1'b0;
                i_type = 1'b0;
                store = 1'b1;
                load = 1'b0;
                branch = 1'b0;
                auipc = 1'b0; 
                jal = 1'b0; 
                jalr = 1'b0; 
                lui = 1'b0;
            end
            7'b0000011:begin
                r_type = 1'b0;
                i_type = 1'b0;
                store = 1'b0;
                load = 1'b1;
                branch = 1'b0;
                auipc = 1'b0; 
                jal = 1'b0; 
                jalr = 1'b0; 
                lui = 1'b0;
            end
            7'b1100011:begin 
                r_type = 1'b0;
                i_type = 1'b0;
                store = 1'b0;
                load = 1'b0;
                branch = 1'b1;
                auipc = 1'b0; 
                jal = 1'b0; 
                jalr = 1'b0; 
                lui = 1'b0;
            end
            7'b0010111:begin 
                r_type = 1'b0;
                i_type = 1'b0;
                store = 1'b0;
                load = 1'b0;
                branch = 1'b0;
                auipc = 1'b1;
                jal = 1'b0; 
                jalr = 1'b0; 
                lui = 1'b0;
            end
            7'b1101111:begin 
                r_type = 1'b0;
                i_type = 1'b0;
                store = 1'b0;
                load = 1'b0;
                branch = 1'b0;
                auipc = 1'b0;
                jal = 1'b1;
                jalr = 1'b0; 
                lui = 1'b0;
            end
            7'b1100111:begin 
                r_type = 1'b0;
                i_type = 1'b0;
                store = 1'b0;
                load = 1'b0;
                branch = 1'b0;
                auipc = 1'b0;
                jal = 1'b0;
                jalr = 1'b1;
                lui = 1'b0;
            end
            7'b0110111:begin 
                r_type = 1'b0;
                i_type = 1'b0;
                store = 1'b0;
                load = 1'b0;
                branch = 1'b0;
                auipc = 1'b0; 
                jal = 1'b0; 
                jalr = 1'b0; 
                lui = 1'b1;
            end

            default:begin 
                r_type = 1'b0;
                i_type = 1'b0;
                store= 1'b0;
                load = 1'b0;
                branch = 1'b0;
                auipc = 1'b0;
                jal = 1'b0; 
                jalr = 1'b0; 
                lui = 1'b0; 
            end
        endcase
    end  
endmodule
// MODULE_BRIEF: Classifies instructions into RV32I format/type groups for control generation.
