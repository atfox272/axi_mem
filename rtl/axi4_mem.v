module axi4_mem
#(
    // AXI4 BUS 
    parameter ATX_DATA_W        = 256,
    parameter ATX_ADDR_W        = 32,
    parameter ATX_ID_W          = 5,
    parameter ATX_LEN_W         = 8,
    parameter ATX_SIZE_W        = 3,
    parameter ATX_RESP_W        = 2,
    parameter ATX_OUSTD_NUM     = 1, // Number of outstanding AXI transactions
    // Memory
    parameter MEM_BASE_ADDR     = 32'h0000_0000,    // Address mapping - BASE
    parameter MEM_OFFSET        = (ATX_DATA_W/8),       // Address mapping - OFFSET ---> Address (byte-access) = (base + offset*n)
    parameter MEM_DATA_W        = ATX_DATA_W,           // Memory's data width
    parameter MEM_ADDR_W        = 5,                // Memory's address width
    parameter MEM_LATENCY       = 1,                // Memory latency
    parameter MEM_INIT_FILE     = "",               // Initial value in Memory
    // Memory region 
    parameter NUM_REGION        = 1,
    parameter [NUM_REGION*ATX_ADDR_W-1:0] REGION_BASE_ADDR  = {NUM_REGION{MEM_BASE_ADDR}},
    parameter [NUM_REGION*32-1:0]         REGION_SIZE       = {NUM_REGION{32'd0}},
) (
    // -- Global 
    input                           clk,
    input                           rst_n,
    // -- -- AW channel         
    input   [ATX_ID_W-1:0]          s_awid_i,
    input   [ATX_ADDR_W-1:0]        s_awaddr_i,
    input   [1:0]                   s_awburst_i,        
    input   [ATX_LEN_W-1:0]         s_awlen_i,
    input                           s_awvalid_i,
    output                          s_awready_o,
    // -- -- W channel          
    input   [ATX_DATA_W-1:0]        s_wdata_i,
    input                           s_wlast_i,
    input                           s_wvalid_i,
    output                          s_wready_o,
    // -- -- B channel          
    output  [ATX_ID_W-1:0]          s_bid_o,
    output  [ATX_RESP_W-1:0]        s_bresp_o,
    output                          s_bvalid_o,
    input                           s_bready_i,
    // -- -- AR channel         
    input   [ATX_ID_W-1:0]          s_arid_i,
    input   [ATX_ADDR_W-1:0]        s_araddr_i,
    input   [1:0]                   s_arburst_i,
    input   [ATX_LEN_W-1:0]         s_arlen_i,
    input                           s_arvalid_i,
    output                          s_arready_o,
    // -- -- R channel          
    output  [ATX_ID_W-1:0]          s_rid_o,
    output  [ATX_DATA_W-1:0]        s_rdata_o,
    output  [ATX_RESP_W-1:0]        s_rresp_o,
    output                          s_rlast_o,
    output                          s_rvalid_o,
    input                           s_rready_i
);
    // Internal signal
    wire                    mem_wr_rdy;
    wire [MEM_DATA_W-1:0]   mem_rd_data;
    wire                    mem_rd_rdy;
    wire [MEM_DATA_W-1:0]   mem_wr_data;
    wire [MEM_ADDR_W-1:0]   mem_wr_addr;
    wire                    mem_wr_vld;
    wire [MEM_ADDR_W-1:0]   mem_rd_addr;
    wire                    mem_rd_vld;
generate
if(NUM_REGION == 1) begin : PASS_DIRECTLY
    // Module instantiation
    axi4_ctrl #(
        .AXI4_CTRL_CONF     (0),
        .AXI4_CTRL_STAT     (0),
        .AXI4_CTRL_MEM      (1),
        .AXI4_CTRL_WR_ST    (0),
        .AXI4_CTRL_RD_ST    (0),
        .MEM_BASE_ADDR      (MEM_BASE_ADDR),
        .MEM_OFFSET         (MEM_OFFSET),
        .MEM_DATA_W         (MEM_DATA_W),
        .MEM_ADDR_W         (MEM_ADDR_W),
        .MEM_SIZE           (REGION_SIZE),
        .MEM_LATENCY        (MEM_LATENCY),
        .DATA_W             (ATX_DATA_W),
        .ADDR_W             (ATX_ADDR_W),
        .MST_ID_W           (ATX_ID_W),
        .TRANS_DATA_LEN_W   (ATX_LEN_W),
        .TRANS_DATA_SIZE_W  (ATX_SIZE_W),
        .TRANS_RESP_W       (ATX_RESP_W)
    ) axi4_ctrl (
        .clk                (clk),
        .rst_n              (rst_n),
        .m_awid_i           (s_awid_i),
        .m_awaddr_i         (s_awaddr_i),
        .m_awburst_i        (s_awburst_i),
        .m_awlen_i          (s_awlen_i),
        .m_awvalid_i        (s_awvalid_i),
        .m_wdata_i          (s_wdata_i),
        .m_wlast_i          (s_wlast_i),
        .m_wvalid_i         (s_wvalid_i),
        .m_bready_i         (s_bready_i),
        .m_arid_i           (s_arid_i),
        .m_araddr_i         (s_araddr_i),
        .m_arburst_i        (s_arburst_i),
        .m_arlen_i          (s_arlen_i),
        .m_arvalid_i        (s_arvalid_i),
        .m_rready_i         (s_rready_i),
        .mem_wr_rdy_i       (mem_wr_rdy),
        .mem_rd_data_i      (mem_rd_data),
        .mem_rd_rdy_i       (mem_rd_rdy),
        .stat_reg_i         (),
        .wr_st_rd_vld_i     (),
        .rd_st_wr_data_i    (),
        .rd_st_wr_vld_i     (),
        .m_awready_o        (s_awready_o),
        .m_wready_o         (s_wready_o),
        .m_bid_o            (s_bid_o),
        .m_bresp_o          (s_bresp_o),
        .m_bvalid_o         (s_bvalid_o),
        .m_arready_o        (s_arready_o),
        .m_rid_o            (s_rid_o),
        .m_rdata_o          (s_rdata_o),
        .m_rresp_o          (s_rresp_o),
        .m_rlast_o          (s_rlast_o),
        .m_rvalid_o         (s_rvalid_o),
        .conf_reg_o         (),
        .mem_wr_data_o      (mem_wr_data),
        .mem_wr_addr_o      (mem_wr_addr),
        .mem_wr_vld_o       (mem_wr_vld),
        .mem_rd_addr_o      (mem_rd_addr),
        .mem_rd_vld_o       (mem_rd_vld),
        .wr_st_rd_data_o    (),
        .wr_st_rd_rdy_o     (),
        .rd_st_wr_rdy_o     ()
    );

    memory #(
        .DATA_W             (MEM_DATA_W),
        .ADDR_W             (MEM_ADDR_W),
        .MEM_SIZE           (REGION_SIZE),
        .MEM_FILE           (MEM_INIT_FILE)
    ) mem (
        .clk                (clk),
        .rst_n              (rst_n),
        .wr_data_i          (mem_wr_data),
        .wr_addr_i          (mem_wr_addr),
        .wr_vld_i           (mem_wr_vld),
        .rd_addr_i          (mem_rd_addr),
        .rd_vld_i           (mem_rd_vld),
        .wr_rdy_o           (mem_wr_rdy),
        .rd_data_o          (mem_rd_data),
        .rd_rdy_o           (mem_rd_rdy)
    );
end
endgenerate
endmodule