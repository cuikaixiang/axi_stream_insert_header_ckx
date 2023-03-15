module axi_stream_insert_header_ckx #(

    parameter DATA_WD = 32,
    parameter DATA_BYTE_WD = DATA_WD / 8,//字节宽度
    parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)//log2
    
    ) (
    input clk,
    input rst_n,
    
    // 原始数据
    input valid_in,
    input [DATA_WD-1 : 0] data_in,
    input [DATA_BYTE_WD-1 : 0] keep_in,
    input last_in,
    output reg ready_in,
    
    // 被插入的header数据
    input valid_insert,
    input [DATA_WD-1 : 0] data_insert,
    input [DATA_BYTE_WD-1 : 0] keep_insert,
    input [BYTE_CNT_WD : 0] byte_insert_cnt,
    output reg ready_insert,
    
    // 输出数据
    output reg valid_out,
    output reg [DATA_WD-1 : 0] data_out,
    output reg [DATA_BYTE_WD-1 : 0] keep_out,
    output reg last_out,
    input ready_out
    
);

    // Your code here 
    //定义一个width和depth全为8的寄存器变量用于存储header中的有效位和data信号
    reg [7:0] data_reg [0:7];
    
    genvar j;
    generate for (j = 3'b0; j < 8; j=j+1) begin
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n)
                data_reg[j] <= 8'b0;
            //输入header中的有效位
            else if(ready_insert == 1 && valid_insert == 1 && j >= 0 && j < byte_insert_cnt)begin
                data_reg[j] <= data_insert[DATA_WD - 1 - (DATA_BYTE_WD - byte_insert_cnt + j) * 8 - : 8];
            end
            //输入data信号到寄存器
            else if(ready_in == 1 && valid_in == 1 && j >= byte_insert_cnt && j < (byte_insert_cnt + DATA_BYTE_WD))begin
                data_reg[j] <= data_in[DATA_WD - 1 - (j - byte_insert_cnt) * 8 - : 8];
            end
            //最后一位data信号到来时补零
            else if(j >= (byte_insert_cnt + DATA_BYTE_WD) && last_in)begin
                data_reg[j] <= 0;
            end
            //每次将后四位的值赋给前四位，然后将新的data信号写入寄存器
            else if(ready_out == 1 && ready_insert == 0 && ready_in == 1)begin
                if(j >= byte_insert_cnt && j < (byte_insert_cnt + DATA_BYTE_WD))
                    data_reg[j] <= data_in[DATA_WD - 1 - (j - byte_insert_cnt) * 8 - : 8];
                else if(j >= 0 && j < 4)
                    data_reg[j] <= data_reg[j+4];
            end
            //其他情况下保持寄存器中的数据稳定不变 
            else begin
                data_reg[j] <= data_reg[j]; 
            end   
        end
    end
    endgenerate


    //控制ready信号配合上面进行数据传输
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            ready_insert <= 1;
            ready_in <= 1;
        end 
        else begin 
            if(valid_in == 1 && valid_insert == 1)begin
                ready_insert <= 0;
            end
            if(last_in) begin
                ready_in <= 0;    
            end
        end
     end  
     
     //定义一个变量，用于记录header信号和最后一位data信号中一共有效位的个数
     reg [3:0]valid_cnt;
     
     //求有效位个数
     always@(posedge clk or negedge rst_n)begin
     if(!rst_n)
        valid_cnt <= 0;
      //swar函数下面定义过了
     else if(last_in)
        valid_cnt <= swar(keep_in) + byte_insert_cnt;        
    else
        valid_cnt <= valid_cnt;
    end
    
    //yu为valid_cnt与4取余的结果
    wire [2:0]yu;
    assign yu = (valid_cnt % 4);
    
    //找出余数个数与keep_out之间的数学关系，因为只有四位所以用case来写
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            keep_out <= 0;
        else begin
            case(yu) 
                0:keep_out <= 4'b1111;
                1:keep_out <= 4'b1000;
                2:keep_out <= 4'b1100;
                3:keep_out <= 4'b1110;
            endcase
        end
    end
    
    //打两拍以达到用last_in控制最后一位输出的效果
    reg [1:0]r_last_in;
    always@(posedge clk)begin
        r_last_in[0] <= last_in;
        r_last_in[1] <= r_last_in[0];
    end
    
    //data_out与存储数据寄存器之间的传输关系
    integer i; 
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            last_out <= 0;
            data_out <= 32'b0;
            valid_out <= 0;
        end
        //每一次都将data_reg的前四位赋值给data_out
        else if(ready_out == 1 && ready_insert == 0 && r_last_in[1] == 0)begin
            valid_out <= 1;
            for (i = 0; i < DATA_BYTE_WD; i = i + 1) begin
                data_out[((DATA_BYTE_WD-i)*8-1)-:8] <= data_reg[i];
            end
        end
        //last_in信号来到，将data_reg的后四位赋值给data_out
        else if(r_last_in[1])begin
            last_out <= 1;
            for (i = 0; i < DATA_BYTE_WD; i = i + 1) begin
                data_out[((DATA_BYTE_WD-i)*8-1)-:8] <= data_reg[i + 4];
            end
        end
        //其余情况下保持data_out的值不变
        else begin 
            for (i = 0; i < DATA_BYTE_WD; i = i + 1) begin
                data_out[((DATA_BYTE_WD-i)*8-1)-:8] <=data_out[((DATA_BYTE_WD-i)*8-1)-:8];
            end 
        end
    end
    
    
    // 计算1的个数的函数
    function [DATA_WD-1:0]swar;
        input [DATA_WD-1:0] data_in;
        reg [DATA_WD-1:0] i;
        begin
            i = data_in;
            i = (i & 32'h55555555) + ({1'b0, i[DATA_WD-1:1]} & 32'h55555555);
            i = (i & 32'h33333333) + ({1'b0, i[DATA_WD-1:2]} & 32'h33333333);
            i = (i & 32'h0F0F0F0F) + ({1'b0, i[DATA_WD-1:4]} & 32'h0F0F0F0F);
            i = i * (32'h01010101);
            swar = i[31:24];    
        end        
    endfunction

endmodule
