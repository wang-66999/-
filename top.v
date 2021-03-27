module top(
	//key input
	input sys_key0,

	//led output
	output [3:0] led,
	
	//i2c
	input scl,
	inout sda,	
		
	//hdmi output
	output hdmi_out_clk,
	output hdmi_out_hs,
	output hdmi_out_vs,
	output hdmi_out_de,
	output[7:0]  hdmi_out_rgb_b,
	output[7:0]  hdmi_out_rgb_g,
	output[7:0]  hdmi_out_rgb_r,
	
	//vga output
	output vga_out_clk,         
	output vga_out_hs,          
	output vga_out_vs,          
	output vga_out_de,          
	output[23:0]  vga_out_data,
	
	//cvbs input
	input cvbs_in_clkp,
	input cvbs_in_clkn,
	input[7:0] cvbs_in_data,
	
	//ddr3
`ifdef Xilinx	
	inout  [15:0]             mcb3_dram_dq,
	output [13:0]             mcb3_dram_a,
	output [2:0]              mcb3_dram_ba,
	output                    mcb3_dram_ras_n,
	output                    mcb3_dram_cas_n,
	output                    mcb3_dram_we_n,
	output                    mcb3_dram_odt,
	output                    mcb3_dram_reset_n,
	output                    mcb3_dram_cke,
	output                    mcb3_dram_dm,
	inout                     mcb3_dram_udqs,
	inout                     mcb3_dram_udqs_n,
	inout                     mcb3_rzq,
	inout                     mcb3_zio,
	output                    mcb3_dram_udm,
	inout                     mcb3_dram_dqs,
	inout                     mcb3_dram_dqs_n,
	output                    mcb3_dram_ck,
	output                    mcb3_dram_ck_n,
`else
	output  wire[0 : 0]  mem_cs_n,
	output  wire[0 : 0]  mem_cke,
	output  wire[12: 0]  mem_addr,
	output  wire[2 : 0]  mem_ba,
	output  wire  mem_ras_n,
	output  wire  mem_cas_n,
	output  wire  mem_we_n,
	inout  wire[0 : 0]  mem_clk,
	inout  wire[0 : 0]  mem_clk_n,
	output  wire[3 : 0]  mem_dm,
	inout  wire[31: 0]  mem_dq,
	inout  wire[3 : 0]  mem_dqs,
	output[0:0]	mem_odt,
`endif	
	//clock input
	input clk_50m,
	input clk_27m
);
assign sda = 1'bz;
assign led = 4'd2;

parameter H_ACTIVE = 16'd1920;
parameter H_FP = 16'd88;
parameter H_SYNC = 16'd44;
parameter H_BP = 16'd148; 
parameter V_ACTIVE = 16'd1080;
parameter V_FP 	= 16'd4;
parameter V_SYNC  = 16'd5;
parameter V_BP	= 16'd36;
parameter H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP;
parameter V_TOTAL = V_ACTIVE + V_FP + V_SYNC + V_BP;
parameter VCH_NUM = 4;
parameter CH0 = 1;
parameter CH1 = 1;
parameter MEM_DATA_BITS = 64;

wire rst_n;
wire phy_clk;
wire ch0_rd_burst_req;
wire[9:0] ch0_rd_burst_len;
wire[23:0] ch0_rd_burst_addr;
wire  ch0_rd_burst_data_valid;
wire[63:0] ch0_rd_burst_data;
wire ch0_rd_burst_finish;

wire ch0_wr_burst_req;
wire[9:0] ch0_wr_burst_len;
wire[23:0] ch0_wr_burst_addr;
wire ch0_wr_burst_data_req;
wire[63:0] ch0_wr_burst_data;
wire ch0_wr_burst_finish;

wire ch1_rd_burst_req;
wire[9:0] ch1_rd_burst_len;
wire[23:0] ch1_rd_burst_addr;
wire  ch1_rd_burst_data_valid;
wire[63:0] ch1_rd_burst_data;
wire ch1_rd_burst_finish;

wire ch1_wr_burst_req;
wire[9:0] ch1_wr_burst_len;
wire[23:0] ch1_wr_burst_addr;
wire ch1_wr_burst_data_req;
wire[63:0] ch1_wr_burst_data;
wire ch1_wr_burst_finish;

wire ch2_rd_burst_req;
wire[9:0] ch2_rd_burst_len;
wire[23:0] ch2_rd_burst_addr;
wire  ch2_rd_burst_data_valid;
wire[63:0] ch2_rd_burst_data;
wire ch2_rd_burst_finish;

wire ch2_wr_burst_req;
wire[9:0] ch2_wr_burst_len;
wire[23:0] ch2_wr_burst_addr;
wire ch2_wr_burst_data_req;
wire[63:0] ch2_wr_burst_data;
wire ch2_wr_burst_finish;

wire ch3_rd_burst_req;
wire[9:0] ch3_rd_burst_len;
wire[23:0] ch3_rd_burst_addr;
wire  ch3_rd_burst_data_valid;
wire[63:0] ch3_rd_burst_data;
wire ch3_rd_burst_finish;

wire ch3_wr_burst_req;
wire[9:0] ch3_wr_burst_len;
wire[23:0] ch3_wr_burst_addr;
wire ch3_wr_burst_data_req;
wire[63:0] ch3_wr_burst_data;
wire ch3_wr_burst_finish;

wire[VCH_NUM -  1 :  0] is_pal;

wire video_clk;
wire cvbs_27m;

wire ch0_de;
wire ch0_vs;
wire[15:0] ch0_yc_data;
wire ch0_f;

wire ch1_de;
wire ch1_vs;
wire[15:0] ch1_yc_data;
wire ch1_f;

wire ch2_de;
wire ch2_vs;
wire[15:0] ch2_yc_data;
wire ch2_f;

wire ch3_de;
wire ch3_vs;
wire[15:0] ch3_yc_data;
wire ch3_f;

wire[7:0] cvbs_data_ch0;
wire[7:0] cvbs_data_ch1;
wire[7:0] cvbs_data_ch2;
wire[7:0] cvbs_data_ch3;

reg[7:0] vin_ch0_data;
reg[7:0] vin_ch1_data;
reg[7:0] vin_ch2_data;
reg[7:0] vin_ch3_data;

wire tw2867_108m;
wire tw2867_27m;

wire video_hs;
wire video_vs;
wire video_de;
wire[7:0] video_r;
wire[7:0] video_g;
wire[7:0] video_b;

wire vga_hs;
wire vga_vs;
wire vga_de;
wire[7:0] vga_r;
wire[7:0] vga_g;
wire[7:0] vga_b;

wire hdmi_hs;
wire hdmi_vs;
wire hdmi_de;
wire[7:0] hdmi_r;
wire[7:0] hdmi_g;
wire[7:0] hdmi_b;

reset reset_m0(
	.clk(video_clk),
	.rst_n(rst_n)
);
`ifdef Xilinx
pll pll_m0(
	.inclk0(clk_27m),
	.c0(),
	.c1(video_clk));
`else
pll pll_m0(
	.inclk0(clk_50m),
	.c0(),
	.c1(video_clk));
`endif
clock_out clock_out_m0
(
	.clk_in(video_clk),
	.clk_out(hdmi_out_clk)
);
clock_in clock_in_clkp_buf
(
	.clk_in(cvbs_in_clkp),
	.clk_out(tw2867_108m)
);
clock_in clock_in_clkn_buf
(
	.clk_in(cvbs_in_clkn),
	.clk_out(tw2867_27m)
);
wire DB_key;
reg DB_key_d0;
reg[2:0] video_sel_cnt;
DeBounce DeBounce_m0
(
	.clk(tw2867_27m), 
	.n_reset(1'b1), 
	.button_in(sys_key0),
	.DB_out(DB_key)
);	
always@(posedge tw2867_27m)
begin
	DB_key_d0 <= DB_key;
	if(DB_key_d0 && ~DB_key)
		video_sel_cnt <= (video_sel_cnt == 3'd4) ? 3'd0 : video_sel_cnt + 3'd1;
end			
demux demux_m0(
	.clk_108m(tw2867_108m),
	.clk_27m(tw2867_27m),
	.vin_data(cvbs_in_data),
	.vout_data_ch0(cvbs_data_ch0),
	.vout_data_ch1(cvbs_data_ch1),
	.vout_data_ch2(cvbs_data_ch2),
	.vout_data_ch3(cvbs_data_ch3)
);


wire[7:0] pat_data;

sd_source sd_source_m0(
	.MODE_SELECT_8B(8'd0),
	.clk_in(tw2867_27m),
						
	.o_itu_656_clk(),
	.o_itu_656_data_8b(pat_data)
						);
						
always@(posedge tw2867_27m)
begin
	vin_ch1_data <= cvbs_data_ch1;
	vin_ch2_data <= cvbs_data_ch2;
	vin_ch3_data <= cvbs_data_ch3;
	case(video_sel_cnt)
		3'd1: vin_ch0_data <= cvbs_data_ch0;
		3'd2: vin_ch0_data <= cvbs_data_ch1;
		3'd3: vin_ch0_data <= cvbs_data_ch2;
		3'd4: vin_ch0_data <= cvbs_data_ch3;
		default:vin_ch0_data <= pat_data;
	endcase
end	
				
bt656_decode bt656_decode_m0(
	.clk(tw2867_27m),
	.bt656_in(vin_ch0_data),
	.yc_data_out(ch0_yc_data),
	.vs(ch0_vs),
	.hs(),
	.field(ch0_f),
	.de(ch0_de),
	.is_pal(is_pal[CH0-1])
);

bt656_decode bt656_decode_m1(
	.clk(tw2867_27m),
	.bt656_in(vin_ch1_data),
	.yc_data_out(ch1_yc_data),
	.vs(ch1_vs),
	.hs(),
	.field(ch1_f),
	.de(ch1_de),
	.is_pal(is_pal[CH1-1])
);

bt656_decode bt656_decode_m2(
	.clk(tw2867_27m),
	.bt656_in(vin_ch2_data),
	.yc_data_out(ch2_yc_data),
	.vs(ch2_vs),
	.hs(),
	.field(ch2_f),
	.de(ch2_de),
	.is_pal()
);

bt656_decode bt656_decode_m3(
	.clk(tw2867_27m),
	.bt656_in(vin_ch3_data),
	.yc_data_out(ch3_yc_data),
	.vs(ch3_vs),
	.hs(),
	.field(ch3_f),
	.de(ch3_de),
	.is_pal()
);

wire ch0_vout_rd_req;
wire[23:0] ch0_vout_ycbcr;
video_pro video_pro_m0(
	.rst_n(1'b1),
	.vin_pixel_clk(tw2867_27m),
	.vin_vs(ch0_vs),
	.vin_f(ch0_f),
	.vin_pixel_de(ch0_de),
	.vin_pixel_yc(ch0_yc_data),
	.vin_s_width(12'd720),
	.vin_s_height(12'd576),
	.clipper_left(12'd0),
	.clipper_width(12'd720),
	.clipper_top(12'd0),
	.clipper_height(12'd576),
	.vout_pixel_clk(video_clk),
	.vout_vs(hdmi_out_vs),
	.vout_pixel_rd_req(ch0_vout_rd_req),
	.vout_pixel_ycbcr(ch0_vout_ycbcr),
	.vout_scaler_clk(video_clk),
	.vout_t_width(12'd720),
	.vout_t_height(12'd576),
	.vout_K_h(16'h0100),
	.vout_K_v(16'h0100),
	.mem_clk(phy_clk),
	.wr_burst_req(ch0_wr_burst_req),
	.wr_burst_len(ch0_wr_burst_len),
	.wr_burst_addr(ch0_wr_burst_addr),
	.wr_burst_data_req(ch0_wr_burst_data_req),
	.wr_burst_data(ch0_wr_burst_data),
	.wr_burst_finish(ch0_wr_burst_finish),
	.rd_burst_req(ch0_rd_burst_req),
	.rd_burst_len(ch0_rd_burst_len),
	.rd_burst_addr(ch0_rd_burst_addr),
	.rd_burst_data_valid(ch0_rd_burst_data_valid),
	.rd_burst_data(ch0_rd_burst_data),
	.rd_burst_finish(ch0_rd_burst_finish),
	.base_addr(2'd0)
);
defparam
	video_pro_m0.MEM_DATA_BITS = MEM_DATA_BITS;
	
wire ch1_vout_rd_req;
wire[23:0] ch1_vout_ycbcr;
video_pro video_pro_m1(
	.rst_n(1'b1),
	.vin_pixel_clk(tw2867_27m),
	.vin_vs(ch1_vs),
	.vin_f(ch1_f),
	.vin_pixel_de(ch1_de),
	.vin_pixel_yc(ch1_yc_data),
	.vin_s_width(12'd720),
	.vin_s_height(12'd576),
	.clipper_left(12'd0),
	.clipper_width(12'd720),
	.clipper_top(12'd0),
	.clipper_height(12'd576),
	.vout_pixel_clk(video_clk),
	.vout_vs(hdmi_out_vs),
	.vout_pixel_rd_req(ch1_vout_rd_req),
	.vout_pixel_ycbcr(ch1_vout_ycbcr),
	.vout_scaler_clk(video_clk),
	.vout_t_width(12'd720),
	.vout_t_height(12'd576),
	.vout_K_h(16'h0100),
	.vout_K_v(16'h0100),
	.mem_clk(phy_clk),
	.wr_burst_req(ch1_wr_burst_req),
	.wr_burst_len(ch1_wr_burst_len),
	.wr_burst_addr(ch1_wr_burst_addr),
	.wr_burst_data_req(ch1_wr_burst_data_req),
	.wr_burst_data(ch1_wr_burst_data),
	.wr_burst_finish(ch1_wr_burst_finish),
	.rd_burst_req(ch1_rd_burst_req),
	.rd_burst_len(ch1_rd_burst_len),
	.rd_burst_addr(ch1_rd_burst_addr),
	.rd_burst_data_valid(ch1_rd_burst_data_valid),
	.rd_burst_data(ch1_rd_burst_data),
	.rd_burst_finish(ch1_rd_burst_finish),
	.base_addr(2'd1)
);
defparam
	video_pro_m1.MEM_DATA_BITS = MEM_DATA_BITS;
	
wire ch2_vout_rd_req;
wire[23:0] ch2_vout_ycbcr;
video_pro video_pro_m2(
	.rst_n(1'b1),
	.vin_pixel_clk(tw2867_27m),
	.vin_vs(ch2_vs),
	.vin_f(ch2_f),
	.vin_pixel_de(ch2_de),
	.vin_pixel_yc(ch2_yc_data),
	.vin_s_width(12'd720),
	.vin_s_height(12'd576),
	.clipper_left(12'd0),
	.clipper_width(12'd720),
	.clipper_top(12'd0),
	.clipper_height(12'd576),
	.vout_pixel_clk(video_clk),
	.vout_vs(hdmi_out_vs),
	.vout_pixel_rd_req(ch2_vout_rd_req),
	.vout_pixel_ycbcr(ch2_vout_ycbcr),
	.vout_scaler_clk(video_clk),
	.vout_t_width(12'd720),
	.vout_t_height(12'd576),
	.vout_K_h(16'h0100),
	.vout_K_v(16'h0100),
	.mem_clk(phy_clk),
	.wr_burst_req(ch2_wr_burst_req),
	.wr_burst_len(ch2_wr_burst_len),
	.wr_burst_addr(ch2_wr_burst_addr),
	.wr_burst_data_req(ch2_wr_burst_data_req),
	.wr_burst_data(ch2_wr_burst_data),
	.wr_burst_finish(ch2_wr_burst_finish),
	.rd_burst_req(ch2_rd_burst_req),
	.rd_burst_len(ch2_rd_burst_len),
	.rd_burst_addr(ch2_rd_burst_addr),
	.rd_burst_data_valid(ch2_rd_burst_data_valid),
	.rd_burst_data(ch2_rd_burst_data),
	.rd_burst_finish(ch2_rd_burst_finish),
	.base_addr(2'd2)
);
defparam
	video_pro_m2.MEM_DATA_BITS = MEM_DATA_BITS;
	
wire ch3_vout_rd_req;
wire[23:0] ch3_vout_ycbcr;
video_pro video_pro_m3(
	.rst_n(1'b1),
	.vin_pixel_clk(tw2867_27m),
	.vin_vs(ch3_vs),
	.vin_f(ch3_f),
	.vin_pixel_de(ch3_de),
	.vin_pixel_yc(ch3_yc_data),
	.vin_s_width(12'd720),
	.vin_s_height(12'd576),
	.clipper_left(12'd0),
	.clipper_width(12'd720),
	.clipper_top(12'd0),
	.clipper_height(12'd576),
	.vout_pixel_clk(video_clk),
	.vout_vs(hdmi_out_vs),
	.vout_pixel_rd_req(ch3_vout_rd_req),
	.vout_pixel_ycbcr(ch3_vout_ycbcr),
	.vout_scaler_clk(video_clk),
	.vout_t_width(12'd720),
	.vout_t_height(12'd576),
	.vout_K_h(16'h0100),
	.vout_K_v(16'h0100),
	.mem_clk(phy_clk),
	.wr_burst_req(ch3_wr_burst_req),
	.wr_burst_len(ch3_wr_burst_len),
	.wr_burst_addr(ch3_wr_burst_addr),
	.wr_burst_data_req(ch3_wr_burst_data_req),
	.wr_burst_data(ch3_wr_burst_data),
	.wr_burst_finish(ch3_wr_burst_finish),
	.rd_burst_req(ch3_rd_burst_req),
	.rd_burst_len(ch3_rd_burst_len),
	.rd_burst_addr(ch3_rd_burst_addr),
	.rd_burst_data_valid(ch3_rd_burst_data_valid),
	.rd_burst_data(ch3_rd_burst_data),
	.rd_burst_finish(ch3_rd_burst_finish),
	.base_addr(2'd3)
);
defparam
	video_pro_m3.MEM_DATA_BITS = MEM_DATA_BITS;
	

vout_display_pro vout_display_pro_m0(
	.rst_n(rst_n),
	.dp_clk(video_clk),
	.h_fp(H_FP[11:0]),
	.h_sync(H_SYNC[11:0]),
	.h_bp(H_BP[11:0]),
	.h_active(H_ACTIVE[11:0]),
	.h_total(H_TOTAL[11:0]),
	
	.v_fp(V_FP[11:0]),
	.v_sync(V_SYNC[11:0]),
	.v_bp(V_BP[11:0]), 
	.v_active(V_ACTIVE[11:0]),
	.v_total(V_TOTAL[11:0]),
	
	.hs(video_hs),
	.vs(video_vs),
	.de(video_de),
	
	.rgb_r(video_r),
	.rgb_g(video_g),
	.rgb_b(video_b),
	
	.layer0_top(12'd0),
	.layer0_left(12'd219),
	.layer0_width(12'd720),
	.layer0_height(12'd576),
	.layer0_alpha(8'hff),
	.layer0_rdreq(ch0_vout_rd_req),
	.layer0_ycbcr(ch0_vout_ycbcr),
	
	.layer1_top(12'd0),
	.layer1_left(12'd949),
	.layer1_width(12'd720),
	.layer1_height(12'd576),
	.layer1_alpha(8'hff),
	.layer1_rdreq(ch1_vout_rd_req),
	.layer1_ycbcr(ch1_vout_ycbcr),
	
	.layer2_top(12'd576),
	.layer2_left(12'd219),
	.layer2_width(12'd720),
	.layer2_height(12'd576),
	.layer2_alpha(12'hff),
	.layer2_rdreq(ch2_vout_rd_req),
	.layer2_ycbcr(ch2_vout_ycbcr),
	
	.layer3_top(12'd576),
	.layer3_left(12'd949),
	.layer3_width(12'd720),
	.layer3_height(12'd576),
	.layer3_alpha(12'hff),
	.layer3_rdreq(ch3_vout_rd_req),
	.layer3_ycbcr(ch3_vout_ycbcr)
);
mem_ctrl
#(
	.MEM_DATA_BITS(MEM_DATA_BITS)
)
mem_ctrl_m0(
	.rst_n(rst_n),
	.source_clk(clk_50m),
	.phy_clk(phy_clk),
	.ch0_rd_burst_req(ch0_rd_burst_req),
	.ch0_rd_burst_len(ch0_rd_burst_len),
	.ch0_rd_burst_addr(ch0_rd_burst_addr),
	.ch0_rd_burst_data_valid(ch0_rd_burst_data_valid),
	.ch0_rd_burst_data(ch0_rd_burst_data),
	.ch0_rd_burst_finish(ch0_rd_burst_finish),
		   
	.ch0_wr_burst_req(ch0_wr_burst_req),
	.ch0_wr_burst_len(ch0_wr_burst_len),
	.ch0_wr_burst_addr(ch0_wr_burst_addr),
	.ch0_wr_burst_data_req(ch0_wr_burst_data_req),
	.ch0_wr_burst_data(ch0_wr_burst_data),
	.ch0_wr_burst_finish(ch0_wr_burst_finish),
	
	.ch1_rd_burst_req(ch1_rd_burst_req),
	.ch1_rd_burst_len(ch1_rd_burst_len),
	.ch1_rd_burst_addr(ch1_rd_burst_addr),
	.ch1_rd_burst_data_valid(ch1_rd_burst_data_valid),
	.ch1_rd_burst_data(ch1_rd_burst_data),
	.ch1_rd_burst_finish(ch1_rd_burst_finish),
		   
	.ch1_wr_burst_req(ch1_wr_burst_req),
	.ch1_wr_burst_len(ch1_wr_burst_len),
	.ch1_wr_burst_addr(ch1_wr_burst_addr),
	.ch1_wr_burst_data_req(ch1_wr_burst_data_req),
	.ch1_wr_burst_data(ch1_wr_burst_data),
	.ch1_wr_burst_finish(ch1_wr_burst_finish),

	.ch2_rd_burst_req(ch2_rd_burst_req),
	.ch2_rd_burst_len(ch2_rd_burst_len),
	.ch2_rd_burst_addr(ch2_rd_burst_addr),
	.ch2_rd_burst_data_valid(ch2_rd_burst_data_valid),
	.ch2_rd_burst_data(ch2_rd_burst_data),
	.ch2_rd_burst_finish(ch2_rd_burst_finish),
	
	.ch2_wr_burst_req(ch2_wr_burst_req),
	.ch2_wr_burst_len(ch2_wr_burst_len),
	.ch2_wr_burst_addr(ch2_wr_burst_addr),
	.ch2_wr_burst_data_req(ch2_wr_burst_data_req),
	.ch2_wr_burst_data(ch2_wr_burst_data),
	.ch2_wr_burst_finish(ch2_wr_burst_finish),
	
	.ch3_rd_burst_req(ch3_rd_burst_req),
	.ch3_rd_burst_len(ch3_rd_burst_len),
	.ch3_rd_burst_addr(ch3_rd_burst_addr),
	.ch3_rd_burst_data_valid(ch3_rd_burst_data_valid),
	.ch3_rd_burst_data(ch3_rd_burst_data),
	.ch3_rd_burst_finish(ch3_rd_burst_finish),
	
	.ch3_wr_burst_req(ch3_wr_burst_req),
	.ch3_wr_burst_len(ch3_wr_burst_len),
	.ch3_wr_burst_addr(ch3_wr_burst_addr),
	.ch3_wr_burst_data_req(ch3_wr_burst_data_req),
	.ch3_wr_burst_data(ch3_wr_burst_data),
	.ch3_wr_burst_finish(ch3_wr_burst_finish),
	
`ifdef Xilinx	
	.mcb3_dram_dq         (mcb3_dram_dq       ),
	.mcb3_dram_a          (mcb3_dram_a        ),
	.mcb3_dram_ba         (mcb3_dram_ba       ),
	.mcb3_dram_ras_n      (mcb3_dram_ras_n    ),
	.mcb3_dram_cas_n      (mcb3_dram_cas_n    ),
	.mcb3_dram_we_n       (mcb3_dram_we_n     ),
	.mcb3_dram_odt        (mcb3_dram_odt      ),
	.mcb3_dram_reset_n    (mcb3_dram_reset_n  ),
	.mcb3_dram_cke        (mcb3_dram_cke      ),
	.mcb3_dram_dm         (mcb3_dram_dm       ),
	.mcb3_dram_udqs       (mcb3_dram_udqs     ),
	.mcb3_dram_udqs_n     (mcb3_dram_udqs_n   ),
	.mcb3_rzq             (mcb3_rzq           ),
	.mcb3_zio             (mcb3_zio           ),
	.mcb3_dram_udm        (mcb3_dram_udm      ),
	.mcb3_dram_dqs        (mcb3_dram_dqs      ),
	.mcb3_dram_dqs_n      (mcb3_dram_dqs_n    ),
	.mcb3_dram_ck         (mcb3_dram_ck       ),
	.mcb3_dram_ck_n       (mcb3_dram_ck_n     )
`else
	.mem_cs_n(mem_cs_n),
	.mem_cke(mem_cke),
	.mem_addr(mem_addr),
	.mem_ba(mem_ba),
	.mem_ras_n(mem_ras_n),
	.mem_cas_n(mem_cas_n),
	.mem_we_n(mem_we_n),
	.mem_clk(mem_clk),
	.mem_clk_n(mem_clk_n),
	.mem_dm(mem_dm),
	.mem_dq(mem_dq),
	.mem_dqs(mem_dqs),
	.mem_odt(mem_odt)
`endif
);

common_std_logic_vector_delay#
(
	.WIDTH(27),
	.DELAY(1)
)
common_std_logic_vector_delay_m0
(
	.clock(video_clk),
	.reset(1'b0),
	.ena(1'b1),
	.data({video_hs,video_vs,video_de,video_r,video_g,video_b}),
	.q({hdmi_out_hs,hdmi_out_vs,hdmi_out_de,hdmi_out_rgb_r,hdmi_out_rgb_g,hdmi_out_rgb_b})
);

common_std_logic_vector_delay#
(
	.WIDTH(27),
	.DELAY(1)
)
common_std_logic_vector_delay_m1
(
	.clock(video_clk),
	.reset(1'b0),
	.ena(1'b1),
	.data({video_hs,video_vs,video_de,video_r,video_g,video_b}),
	.q({vga_hs,vga_vs,vga_de,vga_r,vga_g,vga_b})
);

vga_out_io vga_out_io_m0
(
	.vga_clk      (video_clk    ),
	.vga_hs       (vga_hs       ),
	.vga_vs       (vga_vs       ),
	.vga_de       (vga_de       ),
	.vga_rgb      ({vga_r,vga_g,vga_b}),
	.vga_out_clk  (vga_out_clk  ),
	.vga_out_hs   (vga_out_hs   ),
	.vga_out_de   (vga_out_de   ),
	.vga_out_vs   (vga_out_vs   ),
	.vga_out_data (vga_out_data )
);
endmodule