`timescale 1ns/1ns

// -------------------------------------------------------
// 6-by-6 unsigned fxp mult for 'implicit + mantissa' mult
// Not working yet
// -------------------------------------------------------

module mul_fp52 (
 clk
,op_a_man	  //|< r
,op_b_man   //|< r
,op_c_man   //|< r
,op_a_exp
,op_b_exp
,op_c_exp
,sign_a
,sign_b
,sign_c
,denorm_a
,denorm_b
,denorm_c
,res
 );

input               clk;
input          denorm_a;  // denorm=1 means implicit bit=0 (denormals)
input          denorm_b;
input          denorm_c;
input          sign_a;
input          sign_b;
input          sign_c;
input    [4:0] op_a_man;  // 5-bit unsigned mantissa, thus 6-bit ftactional part
input    [4:0] op_b_man;
input    [4:0] op_c_man;
input    [2:0] op_a_exp;  // 2-bit exponent
input    [2:0] op_b_exp;
input    [2:0] op_c_exp; 
output  [17:0] res;       //12 + max(3+3,3) = 18 bits

reg           denorm_a_reg;
reg           denorm_b_reg;
reg           denorm_c_reg;
reg           sign_a_reg;
reg           sign_b_reg;
reg           sign_c_reg;
reg    	 [4:0] op_a_man_reg;
reg    	 [4:0] op_b_man_reg;
reg    	 [4:0] op_c_man_reg;
reg    	 [2:0] op_a_exp_reg;
reg    	 [2:0] op_b_exp_reg;
reg    	 [2:0] op_c_exp_reg;
wire   	[17:0] res_wire;
reg    	[17:0] res;

always@(posedge clk)
begin
    denorm_a_reg <= denorm_a;
    denorm_b_reg <= denorm_b;
    denorm_c_reg <= denorm_c;
    sign_a_reg   <= sign_a;
    sign_b_reg   <= sign_b;
    sign_c_reg   <= sign_c;
    op_a_man_reg <= op_a_man;				
    op_b_man_reg <= op_b_man;
    op_c_man_reg <= op_c_man;	
    op_a_exp_reg <= op_a_exp;				
    op_b_exp_reg <= op_b_exp;
    op_c_exp_reg <= op_c_exp;			
	  res 		     <= res_wire;
end

	mul u_mul( 
     .op_a_man(op_a_man_reg)
    ,.op_b_man(op_b_man_reg)
    ,.op_c_man(op_c_man_reg)
    ,.op_a_exp(op_a_exp_reg)
    ,.op_b_exp(op_b_exp_reg)
    ,.op_c_exp(op_c_exp_reg)
    ,.denorm_a(denorm_a_reg)
    ,.denorm_b(denorm_b_reg)
    ,.denorm_c(denorm_c_reg)
    ,.sign_a(sign_a_reg)
    ,.sign_b(sign_b_reg)
    ,.sign_c(sign_c_reg)
	  ,.res(res_wire)
    ,.clk(clk)
	);
	
endmodule   // wrapper

//==================
// mul unit fp(2,5)
//==================
// for fp(e,m)=fp(2,5), we have
// 6-bit fraction = 1/0 + mantissa
// 2-bit exponent = [0,3] - bias = {-1,0,1,2}
module mul (
 op_a_man	//|< r
,op_b_man	//|< r
,op_c_man //|< r
,op_a_exp
,op_b_exp
,op_c_exp
,sign_a
,sign_b
,sign_c
,denorm_a
,denorm_b
,denorm_c
,res
,clk
 );

input               clk;
input          denorm_a;
input          denorm_b;
input          denorm_c;
input          sign_a;
input          sign_b;
input          sign_c;
input    [4:0] op_a_man;  // 5-bit unsigned mantissa, thus 6-bit ftactional part
input    [4:0] op_b_man;
input    [4:0] op_c_man;
input    [2:0] op_a_exp;  // 2-bit exponent
input    [2:0] op_b_exp;
input    [2:0] op_c_exp; 
output  [17:0] res;       //12 + max(3+3,3) = 18 bits

reg            sign;
reg      [5:0] op_a_dat;  // 6-bit ftactional part
reg      [5:0] op_b_dat;
reg      [5:0] op_c_dat;

wire     [6:0] sel_data_0;
wire     [6:0] sel_data_1;
wire     [6:0] sel_data_2;
wire     [6:0] sel_data_3;
wire           sel_inv_0;
wire           sel_inv_1;
wire           sel_inv_2;
wire           sel_inv_3;

reg      [8:0] code_lo;
reg      [2:0] code_0;
reg      [2:0] code_1;
reg      [2:0] code_2;
reg      [2:0] code_3;

reg     [19:0] ppre_0;
reg     [19:0] ppre_1;
reg     [19:0] ppre_2;
reg     [19:0] ppre_3;
reg     [19:0] ppre_4;

reg     [19:0] ppre_0_sft;
reg     [19:0] ppre_1_sft;
reg     [19:0] ppre_2_sft;
reg     [19:0] ppre_3_sft;
reg     [19:0] ppre_4_sft;
reg     [19:0] ppre_5_sft;
/*
reg     [119:0] pp_in_l0n0;
wire    [17:0] pp_out_l0n0_0;
wire    [17:0] pp_out_l0n0_1;
*/
reg     [19:0] res;
//==========================================================
// Booth recoding and selection, radix-4
//==========================================================
always @(
    op_a_man
    or op_b_man
    or op_c_man
    or sign_a
    or sign_b
    or sign_c
  ) begin
    op_a_dat = {~denorm_a, op_a_man};   // 6 bits: implicit bit + 5-bit mantissa
    op_b_dat = {~denorm_b, op_b_man};
    op_c_dat = {~denorm_c, op_c_man};
    // sign = sign_a ^ sign_b;
end

always @(
	op_b_dat
  ) begin
    code_lo = {2'b0, op_b_dat, 1'b0};   // 9 bits
    code_0 = code_lo[2:0];
    code_1 = code_lo[4:2];
	code_2 = code_lo[6:4];
    code_3 = code_lo[8:6];
end

NV_NVDLA_CMAC_CORE_MAC_booth u_booth_0 (
   .code     (code_0[2:0])          //|< r
  ,.sign     (sign)
  ,.src_data (op_a_dat)   	        //|< r		
  ,.out_data (sel_data_0)           //|> w
  ,.out_inv  (sel_inv_0)            //|> w
  );

NV_NVDLA_CMAC_CORE_MAC_booth u_booth_1 (
   .code     (code_1[2:0])          //|< r
  ,.sign     (sign)
  ,.src_data (op_a_dat)  			      //|< r
  ,.out_data (sel_data_1)           //|> w
  ,.out_inv  (sel_inv_1)            //|> w
  );
  
NV_NVDLA_CMAC_CORE_MAC_booth u_booth_2 (
   .code     (code_2[2:0])          //|< r
  ,.sign     (sign)
  ,.src_data (op_a_dat)   			    //|< r
  ,.out_data (sel_data_2)           //|> w
  ,.out_inv  (sel_inv_2)            //|> w
  );

NV_NVDLA_CMAC_CORE_MAC_booth u_booth_3 (
   .code     (code_3[2:0])          //|< r
  ,.sign     (sign)
  ,.src_data (op_a_dat)   			    //|< r
  ,.out_data (sel_data_3)           //|> w
  ,.out_inv  (sel_inv_3)            //|> w
  );
  
//==========================================================
// Partial products generation (Baugh-Wooley)
//==========================================================
always @(
  sel_data_0
  or sel_data_1
  or sel_data_2
  or sel_data_3
  or sel_inv_0
  or sel_inv_1
  or sel_inv_2
  or sel_inv_3
  ) begin
    ppre_0 = {13'b0, sel_data_0};   // 20 bits	
    ppre_1 = {11'b0, sel_data_1, 1'b0, sel_inv_0};
    ppre_2 = {9'b0, sel_data_2, 1'b0, sel_inv_1, 2'b0};
    ppre_3 = {7'b0, sel_data_3, 1'b0, sel_inv_2, 4'b0};
    ppre_4 = {13'b0, sel_inv_3, 6'b0};
end

// flaoting-point exponent shift
always @(
  ppre_4
  or ppre_3
  or ppre_2
  or ppre_1
  or ppre_0
  or op_c_dat
  ) begin
    ppre_0_sft = ppre_0 << (op_a_exp+op_b_exp);
    ppre_1_sft = ppre_1 << (op_a_exp+op_b_exp);
    ppre_2_sft = ppre_2 << (op_a_exp+op_b_exp);
    ppre_3_sft = ppre_3 << (op_a_exp+op_b_exp);
    ppre_4_sft = ppre_4 << (op_a_exp+op_b_exp);
    ppre_5_sft = {14'b0, op_c_dat} << op_c_exp;
end

always @(
  // posedge clk
  ppre_5_sft
  or ppre_4_sft
  or ppre_3_sft
  or ppre_2_sft
  or ppre_1_sft
  or ppre_0_sft
  ) begin
    res = ppre_5_sft + ppre_4_sft + ppre_3_sft + ppre_2_sft + ppre_1_sft + ppre_0_sft - 18'd5440;
end

/*
//==========================================================
// CSA tree (level 1)
//==========================================================
always @(
  posedge clk
  ) begin
    pp_in_l0n0 = {ppre_5_sft, ppre_4_sft, ppre_3_sft, ppre_2_sft, ppre_1_sft, ppre_0_sft}; 
end

NV_DW02_tree #(6, 20) u_tree_l0n0 (							
   .INPUT    (pp_in_l0n0[119:0])      //|< r
  ,.OUT0     (pp_out_l0n0_0[19:0])   //|> sum
  ,.OUT1     (pp_out_l0n0_1[19:0])   //|> carry
  );

//=======================
// Output selection
//=======================
always @(
  pp_out_l0n0_0
  or pp_out_l0n0_1
  ) begin
    res = pp_out_l0n0_0 + pp_out_l0n0_1 - 18'd5440;
end
*/
endmodule // mul

//==========================================================
//
// Sub unit for mul
// Booth's recoder and Booth's selector with inversed sign flag
//
//==========================================================
module NV_NVDLA_CMAC_CORE_MAC_booth (
   code
  ,sign
  ,src_data
  ,out_data
  ,out_inv
  );

input    [2:0] code;
input          sign;
input    [5:0] src_data;
output   [6:0] out_data;
output         out_inv;

reg      [2:0] in_code;
reg      [6:0] out_data;
reg            out_inv;

always @(
  sign
  or code
  ) begin
    in_code = {3{sign}} ^ code;
end

always @(
  code
  or src_data
  ) begin
    // case(in_code)
    case(code)
        ///////// for 6 bit /////////
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