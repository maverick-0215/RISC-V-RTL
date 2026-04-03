module alu (a_i,b_i,op_i,res_o);

    input wire [31:0]a_i;
    input wire [31:0]b_i;
    input wire [4:0]op_i;

    output reg [31:0]res_o;

    always @(*) begin

        if (op_i==5'b00000) begin
            res_o = a_i + b_i; //add
        end
        else if (op_i==5'b00001) begin
            res_o = a_i - b_i; //sub
        end
        else if (op_i==5'b00010) begin
            res_o = a_i << b_i[4:0]; //shift left logical
        end
        else if (op_i==5'b00011) begin
            res_o = $signed (a_i) < $signed (b_i); //shift less then
        end 
        else if (op_i==5'b00100) begin
            res_o = a_i < b_i; //shift less then unsigned
        end          
        else if (op_i==5'b00101) begin
            res_o = a_i ^ b_i; //xor
        end
        else if (op_i==5'b00110) begin
            res_o = a_i >> b_i[4:0]; //shift right logical
        end
        else if (op_i==5'b00111) begin
            res_o = $signed(a_i) >>> b_i[4:0]; //shift right arithmetic
        end
        else if (op_i==5'b01000) begin
            res_o = a_i | b_i; //or
        end
        else if (op_i==5'b01001) begin
            res_o = a_i & b_i; //and
        end
        else if (op_i==5'b01111) begin
            res_o = b_i; //for lui 
        end
        else begin
            res_o = 0;
        end
    end
endmodule
// MODULE_BRIEF: Implements RV32I arithmetic and logical operations selected by ALU control.
