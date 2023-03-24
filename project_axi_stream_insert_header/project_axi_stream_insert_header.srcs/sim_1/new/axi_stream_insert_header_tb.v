`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/24 14:40:39
// Design Name: 
// Module Name: axi_stream_insert_header_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module axi_stream_insert_header_tb;
  parameter PERIOD = 10 ;
   parameter DATA_WD = 32 ;
   parameter DATA_BYTE_WD = DATA_WD / 8 ; 
   parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);
   parameter tb_datain_depth = 4;

    // axi_stream_insert_header Inputs
    reg   clk                                = 0 ;
    reg   rst_n                              = 0 ;
    reg   valid_in                           = 0 ;
    reg   [DATA_WD-1 : 0]  data_in           = 0 ;
    reg   [DATA_BYTE_WD-1 : 0]  keep_in      = 0 ;
    reg   ready_out                          = 1 ;
    reg   valid_insert                       = 0 ;
    reg   [DATA_WD-1 : 0]  header_insert     = 0 ;
    reg   [DATA_BYTE_WD-1 : 0]  keep_insert  = 0 ;
    reg   [BYTE_CNT_WD : 0]  byte_insert_cnt = 0 ;

    // axi_stream_insert_header Outputs
    wire  ready_in                             ;
    wire  valid_out                            ;
    wire  [DATA_WD-1 : 0]  data_out            ;
    wire  [DATA_BYTE_WD-1 : 0]  keep_out       ;
    wire  last_out                             ;
    wire  ready_insert                         ;
    wire  last_in                              ;


    initial
    begin
        forever #(PERIOD/2)  clk = ~clk;
    end

    initial
    begin
        #(PERIOD*2) rst_n = 1;
         #(PERIOD*200);
          $finish;
    end

    axi_stream_insert_header #(
    .DATA_WD      (DATA_WD),
    .DATA_BYTE_WD (DATA_BYTE_WD),
    .BYTE_CNT_WD  (BYTE_CNT_WD))
    u_axi_stream_insert_header (
    .clk                     (clk),
    .rst_n                   (rst_n),
    .valid_in                (valid_in),
    .data_in                 (data_in          [DATA_WD-1 : 0]),
    .keep_in                 (keep_in          [DATA_BYTE_WD-1 : 0]),
    .last_in                 (last_in),
    .ready_out               (ready_out),
    .valid_insert            (valid_insert),
    .header_insert           (header_insert    [DATA_WD-1 : 0]),
    .keep_insert             (keep_insert      [DATA_BYTE_WD-1 : 0]),
    .byte_insert_cnt         (byte_insert_cnt  [BYTE_CNT_WD : 0]),

    .ready_in                (ready_in),
    .valid_out               (valid_out),
    .data_out                (data_out         [DATA_WD-1 : 0]),
    .keep_out                (keep_out         [DATA_BYTE_WD-1 : 0]),
    .last_out                (last_out),
    .ready_insert            (ready_insert)
    );
    
   integer seed									 ;
initial begin	                                 
	seed 	=		2							 ;
end

// 随机产生1拍header数据
initial begin
	forever #(PERIOD)	begin
	    header_insert	=	$random(seed)		;
		keep_insert		=	{$random(seed)}%2?({$random(seed)}%2?4'b0001:4'b0011):({$random(seed)}%2?4'b0111:4'b1111);
	end
end
 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_insert            <= 0;
        else if (ready_insert) valid_insert <= 1;
        else valid_insert                   <= 0;
    end


    reg [3:0] cnt = 0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) data_in <= 32'h0;
        else if (ready_in)
        case(cnt)
            0: data_in       <= $random(seed);
            1: data_in       <= $random(seed);
            2: data_in       <= $random(seed);
            3: data_in       <= $random(seed);
            4: data_in       <= $random(seed);
            default: data_in <= 0;
        endcase
        else data_in <= data_in;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) keep_in <= 0;
        else if (ready_in)
        case(cnt)
            0: keep_in       <= 4'b1111;
            1: keep_in       <= 4'b1111;
            2: keep_in       <= 4'b1111;
            3: keep_in       <= 4'b1111;
            4: keep_in       <= 4'b1100;
            default: keep_in <= {$random(seed)}%2?({$random(seed)}%2?4'b1111:4'b1110):({$random(seed)}%2?4'b1100:4'b1000);
        endcase
        else keep_in <= keep_in;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_in <= 0;
        else if (ready_in)
        case(cnt)
            0: valid_in       <= 1;
            1: valid_in       <= 1;
            2: valid_in       <= 1;
            3: valid_in       <= 1;
            4: valid_in       <= 1;
            default: valid_in <= 0;
        endcase
        else valid_in <= valid_in;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 0;
        else if (ready_in && cnt == 0) cnt <= cnt + 1;
        else if (ready_in && valid_in) cnt <= cnt + 1;
        else if(cnt == (tb_datain_depth+1)) cnt <= 0;
        else cnt                           <= cnt;
    end

    assign 		last_in	= (cnt == tb_datain_depth) ? 1: 0;

    initial
    begin

        header_insert   = 32'h55555555;
        keep_insert     = 4'b0011;
        byte_insert_cnt = 3'b001;
    end


endmodule



