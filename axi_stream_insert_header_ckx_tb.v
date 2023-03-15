`timescale 1ns / 1ns
module axi_stream_insert_header_ckx_tb();
parameter PERIOD = 10 ;
 parameter DATA_WD = 32 ; 
 parameter DATA_BYTE_WD = DATA_WD / 8 ; 
 parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);
    
    // axi_stream_insert_header Inputs
    reg   clk;                               
    reg   rst_n;                            
    reg   valid_in;                          
    reg   [DATA_WD-1 : 0]  data_in;           
    reg   [DATA_BYTE_WD-1 : 0]  keep_in;     
    reg   ready_out;                          
    reg   valid_insert;                       
    reg   [DATA_WD-1 : 0]  data_insert;     
    reg   [DATA_BYTE_WD-1 : 0]  keep_insert;  
    reg   [BYTE_CNT_WD : 0]  byte_insert_cnt; 
    
    // axi_stream_insert_header Outputs
    wire  ready_in;
    wire  valid_out;                          
    wire  [DATA_WD-1 : 0]  data_out;            
    wire  [DATA_BYTE_WD-1 : 0]  keep_out;       
    wire  last_out;                             
    wire  ready_insert;                        
    reg  last_in;                              


axi_stream_insert_header_ckx #(
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
    .data_insert           (data_insert    [DATA_WD-1 : 0]),
    .keep_insert             (keep_insert      [DATA_BYTE_WD-1 : 0]),
    .byte_insert_cnt         (byte_insert_cnt  [BYTE_CNT_WD : 0]),
    
    .ready_in                (ready_in),
    .valid_out               (valid_out),
    .data_out                (data_out         [DATA_WD-1 : 0]),
    .keep_out                (keep_out         [DATA_BYTE_WD-1 : 0]),
    .last_out                (last_out),
    .ready_insert            (ready_insert)
    );
initial clk = 1;
always #10 clk = !clk;
reg [1:0]data_cnt;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_cnt <= 0;
    else 
        data_cnt <= data_cnt + 1;
end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_in <= 0;
    else
        case(data_cnt)
            0:data_in <= 32'h12345678;
            1:data_in <= 32'h87654321;
            2:data_in <= 32'h9abcdef0;
            3:begin data_in <= 32'h0fedcba9; last_in <= 1; end
        endcase
end   

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        valid_in <= 0;
    else
        valid_in <= 1;
end
 
initial begin
rst_n = 0;
byte_insert_cnt = 0;
keep_insert = 0;
valid_insert = 0;
data_insert = 0;
last_in = 0;
keep_in = 0;
ready_out = 0;
#201;
rst_n = 1;
keep_insert = 4'b0001;
keep_in = 4'b1111;
ready_out = 1;
valid_insert = 1;
data_insert = 32'h00000001;
byte_insert_cnt = 1;
end

endmodule
