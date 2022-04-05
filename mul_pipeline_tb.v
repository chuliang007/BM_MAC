`timescale 1ns/1ns

module mul_cfg_syn_tb;
reg            clk;
reg            denorm_a;
reg            denorm_b;
reg            denorm_c;
reg            sign_a;
reg            sign_b;
reg            sign_c;
reg      [4:0] op_a_man;
reg      [4:0] op_b_man;
reg      [4:0] op_c_man;
reg      [2:0] op_a_exp;    // 2-bit unsigned, use 3-bit signed to present
reg      [2:0] op_b_exp;    
reg      [2:0] op_c_exp;    
wire    [17:0] res;

//f = 100MHz		
initial	clk = 0;
always	#10 clk = ~clk;

initial denorm_a = 1;   // 1 for denormals
initial denorm_b = 1;
initial denorm_c = 1;

initial sign_a = 0;     // 1 for negatives
initial sign_b = 0;
initial sign_c = 0;

initial op_a_man = 5'd31;
initial op_b_man = 5'd31;
initial op_c_man = 5'd0;

initial op_a_exp = 3'd1;
initial op_b_exp = 3'd1;
initial op_c_exp = 3'd3;
            
mul_fp52 u_mul_fp52(
     .op_a_man(op_a_man)
    ,.op_b_man(op_b_man)
    ,.op_c_man(op_c_man)
    ,.op_a_exp(op_a_exp)
    ,.op_b_exp(op_b_exp)
    ,.op_c_exp(op_c_exp)
    ,.denorm_a(denorm_a)
    ,.denorm_b(denorm_b)
    ,.denorm_c(denorm_c)
    ,.sign_a(sign_a)
    ,.sign_b(sign_b)
    ,.sign_c(sign_c)
    ,.res(res)
    ,.clk(clk)
    );

endmodule
