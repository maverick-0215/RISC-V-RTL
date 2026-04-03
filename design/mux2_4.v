module mux2_4 (a,b,c,d,sel,out);
    input wire [31:0] a,b,c,d;
    input wire [1:0] sel;

    output reg [31:0] out;

    always @ (*) begin
        case (sel)
            2'b00 : out = a;
            2'b01 : out = b;
            2'b10 : out = c;
            2'b11 : out = d;
            default: out = 32'b0;
        endcase
    end
endmodule
// MODULE_BRIEF: 4:1 multiplexer utility module used by datapath routing.
