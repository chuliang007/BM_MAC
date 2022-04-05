`timescale 1ns/1ns

module mul_fp52_tb;
reg            clk;
reg      [6:0] op_a_dat;
reg      [6:0] op_b_dat;
reg      [6:0] op_c_dat;
reg      [1:0] op_a_exp;
reg      [1:0] op_b_exp;    
reg      [1:0] op_c_exp; 
wire    [19:0] res;

/*
//f = 100MHz		
initial	clk = 0;
always	#10 clk = ~clk;

initial op_a_dat = 7'd31;
initial op_b_dat = 7'd31;
initial op_c_dat = 7'd31;

initial op_a_exp = 3'd3;
initial op_b_exp = 3'd3;
initial op_c_exp = 3'd3;
            
mul_fp52 u_mul_fp52(
     .op_a_dat(op_a_dat)
    ,.op_b_dat(op_b_dat)
    ,.op_c_dat(op_c_dat)
    ,.op_a_exp(op_a_exp)
    ,.op_b_exp(op_b_exp)
    ,.op_c_exp(op_c_exp)
    ,.res(res)
    ,.clk(clk)
    );

endmodule   */

///*
//f = 100MHz		
initial	clk = 0;
always	#5 clk = ~clk;

integer i, j, k, ii, jj, kk;
integer o;

initial begin #25
    for (i=-64; i<=63; i=i+1) begin 
        for (j=-64; j<=63; j=j+1) begin 
            for (k=-64; k<=63; k=k+1) begin
                ii= 0+{$random}%4;
                jj= 0+{$random}%4;
                kk= 0+{$random}%4;
                op_a_dat = i;
                op_b_dat = j;
                op_c_dat = k;
                op_a_exp = ii;
                op_b_exp = jj;
                op_c_exp = kk;
                #20 o = i*(2**ii) * j*(2**jj) + k*(2**kk);
            end
        end
    end
end

    mul_fp52 u_mul_fp52(
         .op_a_dat(op_a_dat)
        ,.op_b_dat(op_b_dat)
        ,.op_c_dat(op_c_dat)
        ,.op_a_exp(op_a_exp)
        ,.op_b_exp(op_b_exp)
        ,.op_c_exp(op_c_exp)
        ,.res(res)
        ,.clk(clk)
        );

endmodule //*/
