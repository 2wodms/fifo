module fifo_sjpark
#(
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH = 8,
    parameter ADDR_WIDTH = log2(MEM_DEPTH)
)(
    input wire                      clk,
    input wire                      rstn,
    input wire                      wr,
    input wire                      rd,
    output reg                      full,
    output reg                      empty,
    input wire [DATA_WIDTH - 1:0]   din,
    output reg [DATA_WIDTH - 1:0]   dout
);

reg [ADDR_WIDTH - 1:0] wr_ptr;
reg [ADDR_WIDTH - 1:0] rd_ptr;
reg [DATA_WIDTH - 1:0] mem_reg;

wire full_next;
wire empty_next;

    assign wr_en = ((wr & (!full_next))) | (wr & rd);
    assign rd_en = rd & (!empty_next);
    
//write
always @(posedge clk, negedge rstn) begin
    if(!rstn)
        wr_ptr <= 0;
    else if(wr_en) begin
        wr_ptr <= wr_ptr + 1'b1;
        mem_reg[wr_ptr] <= din;
    end
end

//read
always@(posedge clk, negedge rstn) begin
    if(!rstn)
        rd_ptr <= 0;
    else if(rd_en)begin
        dout <= mem_reg[rd_ptr];
        rd_ptr <= rd_ptr + 1'b1;
    end
end

//full & empty
assign full_next = ((wr_ptr + 1'b1) == rd_ptr) ? 1'b1 : 1'b0;
assign empty_next = (wr_ptr == rd_ptr) ? 1'b1 : 1'b0;

always@(posedge clk, negedge rstn)begin
    if(!rstn) begin
        full <= 1'b0;
        empty <= 1'b1;
    end 
    else begin
        full <= full_next;
        empty <= empty_next;
    end
end

function  integer log2;
input integer value;

begin
    value = value - 1;
    for(log2 = 0; value > 0; log2 = log2 + 1)
        value = value >> 1;
end
endfunction
endmodule




`timescale 1 ns / 100 ps

module tb_lab_fifo;

parameter DATA_WIDTH = 32;
parameter MEM_DEPTH = 8;
parameter ADDR_WIDTH = log2(MEM_DEPTH);

reg                      clk;
reg                      rstn;
reg                      wr;
reg                      rd;
wire                     empty;
wire                     full;
reg  [DATA_WIDTH - 1:0]   din;
wire [DATA_WIDTH - 1:0]   dout;

parameter CLK_PERIOD = 10;
parameter CLK_H_PERIOD = CLK_PERIOD / 2.0;


integer idx;

initial begin
   clk = 0;
   forever #CLK_H_PERIOD clk = ~clk;
end

initial begin 
   rstn = 0;
   repeat(10) @(posedge clk); #0.1;
   rstn = 1;
end

initial begin
   din = 0;
   wr = 0;
   rd = 0;
end

initial begin
   wait(rstn); #0.1;

// case 1 write to full & read to empty 
   repeat(10) @(posedge clk); #0.1;
   mem_wr(2);
   repeat(5) @(posedge clk); #0.1;

   for (idx = 1; idx < MEM_DEPTH+20; idx = idx + 1) begin
      mem_wr(idx);
   end
   
   repeat(10) @(posedge clk); #0.1;
   mem_rd(1);
   repeat(5) @(posedge clk); #0.1;
   for (idx = 1; idx < MEM_DEPTH+20; idx = idx + 1) begin
    mem_rd(1);
   end 

//case2 write to full simultaneous read/write at full
//   repeat(10) @(posedge clk); #0.1;
//   for (idx = 0; idx < MEM_DEPTH; idx = idx + 1)begin
//      mem_wr(idx);
//   end
//   
//   repeat(10) @(posedge clk); #0.1;
//   mem_wrrd(0);
//   repeat(5) @(posedge clk); #0.1;
//   for (idx = 1; idx < MEM_DEPTH ; idx = idx + 1 )begin
//      mem_wrrd(idx);
//   end

////case3 read to empty & simultaneous read/write
//   repeat(10) @(posedge clk); #0.1;
//   for (idx=0; idx<MEM_DEPTH; idx = idx +1) begin
//      mem_wr(idx);
//   end
//
//
//   repeat(10) @(posedge clk); #0.1;
//   for (idx=0; idx<MEM_DEPTH ; idx = idx+1) begin
//      mem_rd;
//   end
//
//   repeat(10) @(posedge clk); #0.1;
//   mem_wrrd(0);
//   repeat(5) @(posedge clk); #0.1;
//   for (idx = 1; idx<MEM_DEPTH; idx = idx + 1) begin
//      mem_wrrd(idx);
//   end

//case4 partial write /read at full
//   repeat(10) @(posedge clk); #0.1;
//   for (idx = 0; idx < MEM_DEPTH; idx = idx + 1)begin
//      mem_wr(idx);
//   end
//
//   repeat(10) @(posedge clk); #0.1;
//   for (idx=0; idx < 5 ; idx = idx+1) begin
//      mem_rd;
//   end
//
//   repeat(10) @(posedge clk); #0.1;
//   for (idx = 0; idx < 6; idx = idx + 1)begin
//      mem_wr(idx);
//   end

////case5 partial write /read at empty
//   repeat(10) @(posedge clk); #0.1;
//   for (idx = 0; idx < MEM_DEPTH; idx = idx + 1)begin
//      mem_wr(idx);
//   end
//
//   repeat(10) @(posedge clk); #0.1;
//   for (idx=0; idx<MEM_DEPTH ; idx = idx+1) begin
//      mem_rd;
//   end
//
//  repeat(10) @(posedge clk); #0.1;
//   for (idx = 0; idx < 5; idx = idx + 1)begin
//      mem_wr(idx);
//   end
//
//
//   repeat(10) @(posedge clk); #0.1;
//   for (idx=0; idx < 5 ; idx = idx+1) begin
//      mem_rd;
//   end
//
//
   repeat(50) @(posedge clk); #0.1;
   
   $finish;
end

fifo_sjpark #(
   .DATA_WIDTH ( DATA_WIDTH ),
   .MEM_DEPTH ( MEM_DEPTH ),
   .ADDR_WIDTH (ADDR_WIDTH)
) u_dut(
   .clk     (clk),
   .rstn    (rstn),
   .wr      (wr),
   .rd      (rd),
   .empty   (empty),
   .full    (full),
   .din     (din),
   .dout    (dout)
);

task mem_wr (
   input [DATA_WIDTH - 1:0] t_din
);
begin
   din = t_din;
   wr = 1;
   repeat(1) @(posedge clk); #0.1;
   wr = 0;
end
endtask

task mem_rd (
    input [DATA_WIDTH - 1:0] t_din
);
begin
    din = t_din;
   rd = 1;
   repeat(1) @(posedge clk); #0.1;
   rd = 0;
end
endtask

task mem_wrrd (
   input [DATA_WIDTH - 1:0] t_din
);
begin
   din = t_din;
   wr = 1;
   rd = 1;
   repeat(1) @(posedge clk); #0.1;
   wr = 0;
   rd = 0;
end
endtask


function integer log2;
input integer value;
begin
   value = value - 1;
   for (log2=0; value>0; log2=log2+1)begin
         value = value >> 1;
   end
end
endfunction


    initial begin
        $dumpfile("fifo.vcd");
        $dumpvars;
    end
endmodule
