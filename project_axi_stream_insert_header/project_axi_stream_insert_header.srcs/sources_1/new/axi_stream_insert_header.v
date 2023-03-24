`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/24 09:32:08
// Design Name: 
// Module Name: axi_stream_insert_header
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


module axi_stream_insert_header #(
    parameter DATA_WD = 32,
    parameter DATA_BYTE_WD = DATA_WD / 8,
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD),
    parameter DATA_DEPTH = 32
    ) (
    input wire clk,
    input wire rst_n,
    // AXI Stream input original data
    input wire valid_in,
    input wire [DATA_WD-1 : 0] data_in,
    input wire [DATA_BYTE_WD-1 : 0] keep_in,
    input wire last_in,
    output ready_in,
    // AXI Stream output with header inserted
    output valid_out,
    output [DATA_WD-1 : 0] data_out,
    output [DATA_BYTE_WD-1 : 0] keep_out,
    output last_out,
    input  wire ready_out,
    // The header to be inserted to AXI Stream input
    input  wire valid_insert,
    input  wire [DATA_WD-1 : 0] header_insert,
    input  wire [DATA_BYTE_WD-1 : 0] keep_insert,
    input  wire [BYTE_CNT_WD : 0] byte_insert_cnt,
    output ready_insert
);
// Your code here
    

    `define  IDLE               3'h0      // ��ֹ״̬
	`define  READ_HEADER        3'h1      // ����ͷ��������
    `define  WAIT_AXIS          3'h2      // �ȴ���Ч����;�������   
    `define  READ_AXIS          3'h3      // ��ȡ��������    
    `define  WAIT_INSERT        3'h4      // �ȴ���Ч����ߵ�ƽ
    `define  WRITE_NEW_AXIS     3'h5      // ���ʹ��б�ͷ��axi������
    `define  TO_IDLE            3'h6      // ��������һ��CLK����

    reg       [2:0]  now_state;       // ����״̬�Ĵ���
	reg       [2:0]  next_state;      // ��һ��״̬��ֵ

    //store data
    reg [7:0] data_mem [0:DATA_DEPTH-1];
    reg [$clog2(DATA_DEPTH):0] front;// ������ȥ��ͷ��Ч���ֽ�
    reg [$clog2(DATA_DEPTH):0] rear; // ��¼�洢����Ч��ĩβλ��

    // output reg
    reg [DATA_WD-1 : 0]      data_out_reg;
    reg [DATA_BYTE_WD-1 : 0] keep_out_reg;

    assign ready_insert = now_state == `IDLE ? 1 : 0;                                   // ready_insert:�����źţ���ʾaxi_stream_insert_header���Բ���ͷ����
    assign ready_in     = now_state == `READ_AXIS ? 1 : 0;                              // ready_in:�����źţ���ʾaxi_stream_insert_header���Խ�������
    assign valid_out    = now_state == `WRITE_NEW_AXIS ? 1 : 0;                         // valid_out:���������Ч�ź�
    assign last_out     = now_state == `WRITE_NEW_AXIS && front >= rear ? 1 : 0;        // last_out:������һ����Ч����
    assign data_out     = data_out_reg;                                                 // data_out:�������
    assign keep_out     = keep_out_reg;                                                 // keep_out:������ݵ���Чλ�Ĵ�


    always @(*) begin
		case ( now_state )
			`IDLE           :      
                            if ( valid_insert == 1'b1 && ready_insert == 1'b1 ) next_state = `READ_AXIS;       
                            else next_state = `IDLE;			
            `READ_AXIS      :
                            if ( last_in == 1'b1 ) next_state = `WRITE_NEW_AXIS;
                            else next_state = `READ_AXIS;
            `WRITE_NEW_AXIS :
                            if ( last_out == 1'b1) next_state = `TO_IDLE;
                            else next_state = `WRITE_NEW_AXIS;
			`TO_IDLE        : next_state = `IDLE;
			 default        : next_state = `IDLE;
		endcase
	end

	always @(posedge clk or negedge rst_n ) begin
		if ( !rst_n ) now_state <= `IDLE;
		else now_state <= next_state;        
	end

    // calculate the 1's number
    function [DATA_WD:0]swar;
        input [DATA_WD:0] data_in;
        reg [DATA_WD:0] i;
        begin
            i = data_in;
            i = (i & 32'h55555555) + ({0, i[DATA_WD:1]} & 32'h55555555);
            i = (i & 32'h33333333) + ({0, i[DATA_WD:2]} & 32'h33333333);
            i = (i & 32'h0F0F0F0F) + ({0, i[DATA_WD:4]} & 32'h0F0F0F0F);
            i = i * (32'h01010101);
            swar = i[31:24];    
        end        
    endfunction

    // data_mem initial
    genvar j;
    generate for (j = 32'd0; j < DATA_DEPTH; j=j+1) begin
        always @(posedge clk or negedge rst_n ) begin
          if(!rst_n)begin
          now_state <= `IDLE && next_state <= `IDLE;
          end 
          else if ( now_state == `IDLE && next_state == `IDLE )begin
                data_mem[j] <= 0;
                end
            else if ( now_state == `IDLE && j >= rear && j < rear + DATA_BYTE_WD )begin
                data_mem[j] <= header_insert[DATA_WD - 1 - (j-rear) * 8 -: 8];
                end
            else if ( now_state == `READ_AXIS && ready_in == 1'b1 && valid_in == 1'b1 && j >= rear && j < rear + DATA_BYTE_WD)begin                
                data_mem[j] <= data_in[DATA_WD - 1 -(j-rear) * 8 -: 8];
                end
            else begin
                data_mem[j] <= data_mem[j];
                end
        end
   end
    endgenerate

    // front
   always @(posedge clk or negedge rst_n ) begin
          if(!rst_n)begin
          now_state <= `IDLE && next_state <= `IDLE;
          end 
		else if ( now_state == `IDLE && next_state == `IDLE )begin
            front <= 0;
            end
        else if ( now_state == `IDLE && next_state == `READ_AXIS )begin
            front <= front + DATA_BYTE_WD - byte_insert_cnt;
            end
        else if ( now_state == `READ_AXIS && next_state != `READ_AXIS && ready_out || now_state == `WRITE_NEW_AXIS )begin
            front <= front + DATA_BYTE_WD;
            end
        else begin
            front <= front;
            end
	end

    // rear
   always @(posedge clk or negedge rst_n ) begin
          if(!rst_n)begin
          now_state <= `IDLE && next_state <= `IDLE;
          end 
		else if (  now_state == `IDLE && next_state == `IDLE )begin
            rear <= 0;
            end
        else if ( now_state == `IDLE && next_state == `READ_AXIS )begin
            rear <= rear + DATA_BYTE_WD;
            end
        else if ( now_state == `READ_AXIS )begin            
            rear <= rear + swar(keep_in);
            end
        else begin
            rear <= rear;            
            end
	end


    genvar i;
    generate for (i = 32'd0; i < DATA_BYTE_WD; i=i+1) begin
       always @(posedge clk or negedge rst_n ) begin
          if(!rst_n)begin
          now_state <= `IDLE;
          end 
           else if ( now_state == `IDLE ) begin
                data_out_reg[DATA_WD-1-i*8 : DATA_WD-(i+1)*8] <= 0;
                end
            else if ( next_state == `WRITE_NEW_AXIS ) begin
                data_out_reg[DATA_WD-1-i*8 : DATA_WD-(i+1)*8] <= data_mem[front+i];  
                end     
            else begin
                data_out_reg[DATA_WD-1-i*8 : DATA_WD-(i+1)*8] <= data_out_reg[DATA_WD-1-i*8 : DATA_WD-(i+1)*8]; 
                end      
        end
    end
    endgenerate

    generate for (i = 32'd0; i < DATA_BYTE_WD; i=i+1) begin
       always @(posedge clk or negedge rst_n ) begin
          if(!rst_n)begin
          now_state <= `IDLE;
          end 
           else if ( now_state == `IDLE )begin
                keep_out_reg[i] <= 0;
                end
            else if ( next_state == `WRITE_NEW_AXIS ) begin
                keep_out_reg[DATA_BYTE_WD-i-1] <= front + i < rear ? 1 : 0;
                end       
            else begin
                keep_out_reg[i] <= keep_out_reg[i];
                end     
        end
    end
    endgenerate

endmodule
