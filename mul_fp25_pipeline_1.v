`timescale 1ns/1ns

// --------------------------------------------------------------------------
// The very raw implementation of 6-by-6 signed fxp mult and Kulisch addition
// --------------------------------------------------------------------------

module mul_fp52 (
 clk
,op_a_dat	//|< r
,op_b_dat	//|< r
,op_c_dat	//|< r
,op_a_exp
,op_b_exp
,op_c_exp
,res
 );

// parameter op_a_exp = 0;		// exponent of op_a_dat
// parameter op_b_exp = 0;		// exponent of op_b_dat
// parameter op_c_exp = 0;		// exponent of op_c_dat

input                 clk;
input    [5:0] op_a_dat;  // 6 bits
input    [5:0] op_b_dat;  // 6 bits
input    [5:0] op_c_dat;  // 6 bits
input    [2:0] op_a_exp;  // 2 bits
input    [2:0] op_b_exp;  // 2 bits
input    [2:0] op_c_exp;  // 2 bits
output  [17:0] res;       //12 + max(3+3,3) = 18 bits

reg    	 [5:0] op_a_dat_reg;
reg    	 [5:0] op_b_dat_reg;
reg    	 [5:0] op_c_dat_reg;
reg    	 [5:0] op_a_exp_reg;
reg    	 [5:0] op_b_exp_reg;
reg    	 [5:0] op_c_exp_reg;
wire   	[17:0] res_wire;
reg    	[17:0] res;

always@(posedge clk)
begin
    op_a_dat_reg <= op_a_dat;				
    op_b_dat_reg <= op_b_dat;
    op_c_dat_reg <= op_c_dat;	
    op_a_exp_reg <= op_a_exp;				
    op_b_exp_reg <= op_b_exp;
    op_c_exp_reg <= op_c_exp;			
	  res 		     <= res_wire;
end

	mul u_mul( 
     .op_a_dat(op_a_dat_reg)
	  ,.op_b_dat(op_b_dat_reg)
    ,.op_c_dat(op_c_dat_reg)
    ,.op_a_exp(op_a_exp_reg)
    ,.op_b_exp(op_b_exp_reg)
    ,.op_c_exp(op_c_exp_reg)
    ,.res(res_wire)
    ,.clk(clk)
	);
	
endmodule

//==================
// mul unit fp(2,5)
//==================
// for fp(e,m)=fp(2,5), we have
// 6-bit fraction = 1/0 + mantissa
// 2-bit exponent = [0,3] - bias = {-1,0,1,2}
module mul (
 op_a_dat	//|< r
,op_b_dat	//|< r
,op_c_dat   //|< r
,op_a_exp
,op_b_exp
,op_c_exp
,res
,clk
 );

input          clk;
input    [5:0] op_a_dat;	// 6 bits (1-bit implicit + 5-bit mantissa)
input    [5:0] op_b_dat;	// 6 bits
input    [5:0] op_c_dat;	// 6 bits
input    [2:0] op_a_exp;    // 2 bits
input    [2:0] op_b_exp;    // 2 bits
input    [2:0] op_c_exp;    // 2 bits
output  [17:0] res;		    //12+xx bits

wire     [6:0] sel_data_0;
wire     [6:0] sel_data_1;
wire     [6:0] sel_data_2;
wire           sel_inv_0;
wire           sel_inv_1;
wire           sel_inv_2;

reg      [6:0] code_lo;
reg      [2:0] code_0;
reg      [2:0] code_1;
reg      [2:0] code_2;

reg     [17:0] ppre_0;
reg     [17:0] ppre_1;
reg     [17:0] ppre_2;
reg     [17:0] ppre_3;

reg     [17:0] ppre_0_sft;
reg     [17:0] ppre_1_sft;
reg     [17:0] ppre_2_sft;
reg     [17:0] ppre_3_sft;
reg     [17:0] ppre_4_sft;

reg     [89:0] pp_in_l0n0;
wire    [17:0] pp_out_l0n0_0;
wire    [17:0] pp_out_l0n0_1;

reg     [17:0] res;
// reg     [17:0] out;
//==========================================================
// Booth recoding and selection, radix-4
//==========================================================
always @(
	op_b_dat
  ) begin
    code_lo = {op_b_dat[5:0], 1'b0};
    code_0 = code_lo[2:0];
    code_1 = code_lo[4:2];
	  code_2 = code_lo[6:4];
end

NV_NVDLA_CMAC_CORE_MAC_booth u_booth_0 (
   .code     (code_0[2:0])          //|< r
  ,.src_data (op_a_dat)   	        //|< r		
  ,.out_data (sel_data_0)           //|> w
  ,.out_inv  (sel_inv_0)            //|> w
  );

NV_NVDLA_CMAC_CORE_MAC_booth u_booth_1 (
   .code     (code_1[2:0])          //|< r
  ,.src_data (op_a_dat)  			      //|< r
  ,.out_data (sel_data_1)           //|> w
  ,.out_inv  (sel_inv_1)            //|> w
  );
  
NV_NVDLA_CMAC_CORE_MAC_booth u_booth_2 (
   .code     (code_2[2:0])          //|< r
  ,.src_data (op_a_dat)   			    //|< r
  ,.out_data (sel_data_2)           //|> w
  ,.out_inv  (sel_inv_2)            //|> w
  );
  
//==========================================================
// Partial products generation (Baugh-Wooley)
//==========================================================
always @(
  sel_data_0
  or sel_data_1
  or sel_data_2
  or sel_inv_0
  or sel_inv_1
  or sel_inv_2
  ) begin
    ppre_0 = {11'b0, sel_data_0};    //18 bits			
    ppre_1 = {9'b0, sel_data_1, 1'b0, sel_inv_0};
    ppre_2 = {7'b0, sel_data_2, 1'b0, sel_inv_1, 2'b0};    
    ppre_3 = {13'b11_1111_1010_110, sel_inv_2, 4'b0};
end

// sign extension for fractional parts
always @( posedge clk
  /* ppre_3
  or ppre_2
  or ppre_1
  or ppre_0
  or op_c_dat */
  ) begin
    ppre_0_sft = ppre_0 << (op_a_exp+op_b_exp);
    ppre_1_sft = ppre_1 << (op_a_exp+op_b_exp);
    ppre_2_sft = ppre_2 << (op_a_exp+op_b_exp);
    ppre_3_sft = ppre_3 << (op_a_exp+op_b_exp);
    ppre_4_sft = $signed({op_c_dat, 6'b0}) >>> (6 - op_c_exp);
end

//==========================================================
// CSA tree (level 1)
//==========================================================
always @(
  ppre_4_sft
  or ppre_3_sft
  or ppre_2_sft
  or ppre_1_sft
  or ppre_0_sft
  ) begin
    pp_in_l0n0 = {ppre_4_sft, ppre_3_sft, ppre_2_sft, ppre_1_sft, ppre_0_sft};          
end

NV_DW02_tree #(5, 18) u_tree_l0n0 (							
   .INPUT    (pp_in_l0n0[89:0])      //|< r
  ,.OUT0     (pp_out_l0n0_0[17:0])   //|> sum
  ,.OUT1     (pp_out_l0n0_1[17:0])   //|> carry
  );

//=======================
// Shift psum by exponent
//=======================
always @(
  pp_out_l0n0_0
  or pp_out_l0n0_1
  ) begin
    res = pp_out_l0n0_0 + pp_out_l0n0_1;
end

endmodule // mul

//==========================================================
//
// Sub unit for mul
// Booth's recoder and Booth's selector with inversed sign flag
//
//==========================================================
module NV_NVDLA_CMAC_CORE_MAC_booth (
   code
  ,src_data
  ,out_data
  ,out_inv
  );

input    [2:0] code;
input    [5:0] src_data;
output   [6:0] out_data;
output         out_inv;
reg      [6:0] out_data;
reg            out_inv;

always @(
	 code
  or src_data
  ) begin
    case(code)
        ///////// for 4bit /////////
        // +/- 0*src_data
        3'b000,
        3'b111:
        begin
            out_data = 7'b100_0000;
            out_inv = 1'b0;
        end

        // + 1*src_data
        3'b001,
        3'b010:
        begin
            out_data = {~src_data[5], src_data};
            out_inv = 1'b0;
        end

        // - 1*src_data
        3'b101,
        3'b110:
        begin
            out_data = {src_data[5], ~src_data};
            out_inv = 1'b1;
        end

        // + 2*src_data
        3'b011:
        begin
            out_data = {~src_data[5], src_data[4:0], 1'b0};	//shift
            out_inv = 1'b0;
        end

        // - 2*src_data
        3'b100:
        begin
            out_data = {src_data[5], ~src_data[4:0], 1'b1};	//shift and add
            out_inv = 1'b1;
        end
		
		default:
        begin
            out_data = 7'b100_0000;
            out_inv = 1'b0;
        end
    endcase
end
endmodule // NV_NVDLA_CMAC_CORE_MAC_booth