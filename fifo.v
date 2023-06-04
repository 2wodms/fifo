module fifo
#(
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 8,
    parameter ADDR_WIDTH = log2(MEM_DEPTH)
)(
    input wire                      clk, 
    input wire                      rstn,
    input wire [DATA_WIDTH - 1:0]   data_in,
    input wire                      wr,
    input wire                      rd,
    output reg [DATA_WIDTH - 1:0]   data_out,
    output reg                      full,
    output reg                      empty
);

reg [DATA_WIDTH - 1:0] wr_ptr;
reg [DATA_WIDTH - 1:0] rd_ptr;
reg [DATA_WIDTH - 1:0] mem_reg;

wire full_next;
wire empty_next;

assign wr_en = (wr & (!full_next) | (wr & rd));
assign rd_en = (rd & (!empty_next));

//write
always@(posedge clk, negedge rstn) begin
    if(!rstn) begin
        wr_ptr <= 1'b0;
    end
    else if(wr_en) begin
        mem_reg[wr_ptr] <= data_in;
        wr_ptr <= wr_ptr + 1;
    end
end

//read
always@(posedge clk, negedge rstn) begin
    if(!rstn) begin
        rd_ptr <= 1'b0;
    end
    else if(rd_en) begin
        data_out <= mem_reg[rd_ptr];
        rd_ptr = rd_ptr + 1;
    end
end

//full
assign full_next = ((wr_ptr + 1) == rd_ptr) ? 1'b1 : 1'b0;
always@(posedge clk, negedge rstn) begin
    if(!rstn) begin
        full <= 1'b0;
    end else
        full <= full_next;
end

//empty
assign empty_next = (wr_ptr == rd_ptr) ? 1'b1 : 1'b0;
always@(posedge clk, negedge rstn) begin
    if(!rstn) begin
        empty <= 1'b1
    end else
        empty <= empty_next;
end

function  integer log2;
input integer value;

begin
    value = value - 1;
    for(log2 = 0; value > 0; log2 = log2 + 1)
        value = value >> 1;
end
endfunction

initial begin
	$dumpfile("jack.vcd");
	$dumpvars;
end

endmodule
