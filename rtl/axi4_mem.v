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
    parameter MEM_OFFSET        = (ATX_DATA_W/8),   // Address mapping - OFFSET ---> Address (byte-access) = (base + offset*n)
    parameter MEM_DATA_W        = ATX_DATA_W,       // Memory's data width
    parameter MEM_ADDR_W        = 5,                // Memory's address width
    parameter MEM_SIZE          = 1<<MEM_ADDR_W,    // Memory size
    parameter MEM_LATENCY       = 1,                // Memory latency
    parameter MEM_INIT_FILE     = "",               // Initial value in Memory
    // Memory region
    parameter NUM_REGION        = 4,
    parameter [NUM_REGION*ATX_ADDR_W-1:0] REGION_BASE_ADDR  = {32'h0000_0000, 32'h0000_1000, 32'h0000_2000, 32'h0000_3000},
    parameter [NUM_REGION*32-1:0]         REGION_SIZE       = {NUM_REGION{32'd8}}
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
    // Internal variables
    genvar region_idx;
    // Internal signal
    
    // -- AW channel         
    wire    [ATX_ID_W-1:0]              m_awid;
    wire    [ATX_ADDR_W-1:0]            m_awaddr;
    wire    [1:0]                       m_awburst;        
    wire    [ATX_LEN_W-1:0]             m_awlen;
    wire    [NUM_REGION-1:0]            m_awvalid;
    wire    [NUM_REGION-1:0]            m_awready;
    // -- W channel          
    wire    [ATX_DATA_W-1:0]            m_wdata;
    wire                                m_wlast;
    wire    [NUM_REGION-1:0]            m_wvalid;
    wire    [NUM_REGION-1:0]            m_wready;
    // -- B channel          
    wire    [NUM_REGION*ATX_ID_W-1:0]   m_bid;
    wire    [NUM_REGION*ATX_RESP_W-1:0] m_bresp;
    wire    [NUM_REGION-1:0]            m_bvalid;
    wire    [NUM_REGION-1:0]            m_bready;
    // -- AR channel         
    wire    [ATX_ID_W-1:0]              m_arid;
    wire    [ATX_ADDR_W-1:0]            m_araddr;
    wire    [1:0]                       m_arburst;
    wire    [ATX_LEN_W-1:0]             m_arlen;
    wire    [NUM_REGION-1:0]            m_arvalid;
    wire    [NUM_REGION-1:0]            m_arready;
    // -- R channel          
    wire    [NUM_REGION*ATX_ID_W-1:0]   m_rid;
    wire    [NUM_REGION*ATX_DATA_W-1:0] m_rdata;
    wire    [NUM_REGION*ATX_RESP_W-1:0] m_rresp;
    wire    [NUM_REGION-1:0]            m_rlast;
    wire    [NUM_REGION-1:0]            m_rvalid;
    wire    [NUM_REGION-1:0]            m_rready;
    wire                    mem_wr_rdy  [0:NUM_REGION-1];
    wire [MEM_DATA_W-1:0]   mem_rd_data [0:NUM_REGION-1];
    wire                    mem_rd_rdy  [0:NUM_REGION-1];
    wire [MEM_DATA_W-1:0]   mem_wr_data [0:NUM_REGION-1];
    wire [MEM_ADDR_W-1:0]   mem_wr_addr [0:NUM_REGION-1];
    wire                    mem_wr_vld  [0:NUM_REGION-1];
    wire [MEM_ADDR_W-1:0]   mem_rd_addr [0:NUM_REGION-1];
    wire                    mem_rd_vld  [0:NUM_REGION-1];

    // Module instantiation
    // -- AXI4 Dispatch
    amem_dispath #(
        .ATX_DATA_W         (ATX_DATA_W),
        .ATX_ADDR_W         (ATX_ADDR_W),
        .ATX_ID_W           (ATX_ID_W),
        .ATX_LEN_W          (ATX_LEN_W),
        .ATX_SIZE_W         (ATX_SIZE_W),
        .ATX_RESP_W         (ATX_RESP_W),
        .ATX_OUSTD_NUM      (ATX_OUSTD_NUM),
        .MEM_BASE_ADDR      (MEM_BASE_ADDR),
        .NUM_REGION         (NUM_REGION),
        .REGION_BASE_ADDR   (REGION_BASE_ADDR),
        .REGION_SIZE        (REGION_SIZE)
    ) dispath (
        .clk                (clk),
        .rst_n              (rst_n),
        .s_awid_i           (s_awid_i),
        .s_awaddr_i         (s_awaddr_i),
        .s_awburst_i        (s_awburst_i),
        .s_awlen_i          (s_awlen_i),
        .s_awvalid_i        (s_awvalid_i),
        .s_awready_o        (s_awready_o),
        .s_wdata_i          (s_wdata_i),
        .s_wlast_i          (s_wlast_i),
        .s_wvalid_i         (s_wvalid_i),
        .s_wready_o         (s_wready_o),
        .s_bid_o            (s_bid_o),
        .s_bresp_o          (s_bresp_o),
        .s_bvalid_o         (s_bvalid_o),
        .s_bready_i         (s_bready_i),
        .s_arid_i           (s_arid_i),
        .s_araddr_i         (s_araddr_i),
        .s_arburst_i        (s_arburst_i),
        .s_arlen_i          (s_arlen_i),
        .s_arvalid_i        (s_arvalid_i),
        .s_arready_o        (s_arready_o),
        .s_rid_o            (s_rid_o),
        .s_rdata_o          (s_rdata_o),
        .s_rresp_o          (s_rresp_o),
        .s_rlast_o          (s_rlast_o),
        .s_rvalid_o         (s_rvalid_o),
        .s_rready_i         (s_rready_i),
        .m_awid             (m_awid),
        .m_awaddr           (m_awaddr),
        .m_awburst          (m_awburst),
        .m_awlen            (m_awlen),
        .m_awvalid          (m_awvalid),
        .m_awready          (m_awready),
        .m_wdata            (m_wdata),
        .m_wlast            (m_wlast),
        .m_wvalid           (m_wvalid),
        .m_wready           (m_wready),
        .m_bid              (m_bid),
        .m_bresp            (m_bresp),
        .m_bvalid           (m_bvalid),
        .m_bready           (m_bready),
        .m_arid             (m_arid),
        .m_araddr           (m_araddr),
        .m_arburst          (m_arburst),
        .m_arlen            (m_arlen),
        .m_arvalid          (m_arvalid),
        .m_arready          (m_arready),
        .m_rid              (m_rid),
        .m_rdata            (m_rdata),
        .m_rresp            (m_rresp),
        .m_rlast            (m_rlast),
        .m_rvalid           (m_rvalid),
        .m_rready           (m_rready)
    );
generate
for(region_idx = 0; region_idx < NUM_REGION; region_idx = region_idx + 1) begin : MEM_REGION_GEN
    axi4_ctrl #(
        .AXI4_CTRL_CONF     (0),
        .AXI4_CTRL_STAT     (0),
        .AXI4_CTRL_MEM      (1),
        .AXI4_CTRL_WR_ST    (0),
        .AXI4_CTRL_RD_ST    (0),
        .MEM_BASE_ADDR      (REGION_BASE_ADDR[(region_idx+1)*ATX_ADDR_W-1-:ATX_ADDR_W]),
        .MEM_OFFSET         (MEM_OFFSET),
        .MEM_DATA_W         (MEM_DATA_W),
        .MEM_ADDR_W         (MEM_ADDR_W),
        .MEM_SIZE           (REGION_SIZE[(region_idx+1)*32-1-:32]),
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
        .m_awid_i           (m_awid),
        .m_awaddr_i         (m_awaddr),
        .m_awburst_i        (m_awburst),
        .m_awlen_i          (m_awlen),
        .m_awvalid_i        (m_awvalid[region_idx]),
        .m_awready_o        (m_awready[region_idx]),
        .m_wdata_i          (m_wdata),
        .m_wlast_i          (m_wlast),
        .m_wvalid_i         (m_wvalid[region_idx]),
        .m_wready_o         (m_wready[region_idx]),

        .m_bid_o            (m_bid[(region_idx+1)*ATX_ID_W-1-:ATX_ID_W]),
        .m_bresp_o          (m_bresp[(region_idx+1)*ATX_RESP_W-1-:ATX_RESP_W]),
        .m_bvalid_o         (m_bvalid[region_idx]),
        .m_bready_i         (m_bready[region_idx]),

        .m_arid_i           (m_arid),
        .m_araddr_i         (m_araddr),
        .m_arburst_i        (m_arburst),
        .m_arlen_i          (m_arlen),
        .m_arvalid_i        (m_arvalid[region_idx]),
        .m_arready_o        (m_arready[region_idx]),

        .m_rid_o            (m_rid[(region_idx+1)*ATX_ID_W-1-:ATX_ID_W]),
        .m_rdata_o          (m_rdata[(region_idx+1)*ATX_DATA_W-1-:ATX_DATA_W]),
        .m_rresp_o          (m_rresp[(region_idx+1)*ATX_RESP_W-1-:ATX_RESP_W]),
        .m_rlast_o          (m_rlast[region_idx]),
        .m_rvalid_o         (m_rvalid[region_idx]),
        .m_rready_i         (m_rready[region_idx]),

        .mem_wr_rdy_i       (mem_wr_rdy[region_idx]),
        .mem_rd_data_i      (mem_rd_data[region_idx]),
        .mem_rd_rdy_i       (mem_rd_rdy[region_idx]),
        .stat_reg_i         (),
        .wr_st_rd_vld_i     (),
        .rd_st_wr_data_i    (),
        .rd_st_wr_vld_i     (),
        .conf_reg_o         (),
        .mem_wr_data_o      (mem_wr_data[region_idx]),
        .mem_wr_addr_o      (mem_wr_addr[region_idx]),
        .mem_wr_vld_o       (mem_wr_vld[region_idx]),
        .mem_rd_addr_o      (mem_rd_addr[region_idx]),
        .mem_rd_vld_o       (mem_rd_vld[region_idx]),
        .wr_st_rd_data_o    (),
        .wr_st_rd_rdy_o     (),
        .rd_st_wr_rdy_o     ()
    );

    memory #(
        .DATA_W             (MEM_DATA_W),
        .ADDR_W             (MEM_ADDR_W),
        .MEM_SIZE           (REGION_SIZE[(region_idx+1)*32-1-:32]),
        .MEM_FILE           (MEM_INIT_FILE)
    ) mem (
        .clk                (clk),
        .rst_n              (rst_n),
        .wr_data_i          (mem_wr_data[region_idx]),
        .wr_addr_i          (mem_wr_addr[region_idx]),
        .wr_vld_i           (mem_wr_vld[region_idx]),
        .rd_addr_i          (mem_rd_addr[region_idx]),
        .rd_vld_i           (mem_rd_vld[region_idx]),
        .wr_rdy_o           (mem_wr_rdy[region_idx]),
        .rd_data_o          (mem_rd_data[region_idx]),
        .rd_rdy_o           (mem_rd_rdy[region_idx])
    );
end
endgenerate
endmodule