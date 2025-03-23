module amem_dispath #(
    // AXI4 BUS 
    parameter ATX_DATA_W        = 256,
    parameter ATX_ADDR_W        = 32,
    parameter ATX_ID_W          = 5,
    parameter ATX_LEN_W         = 8,
    parameter ATX_SIZE_W        = 3,
    parameter ATX_RESP_W        = 2,
    parameter ATX_OUSTD_NUM     = 2, // Number of outstanding AXI transactions
    // Memory
    parameter MEM_BASE_ADDR     = 32'h0000_0000,    // Address mapping - BASE
    // Memory region 
    parameter NUM_REGION        = 1,
    parameter [NUM_REGION*ATX_ADDR_W-1:0] REGION_BASE_ADDR  = {32'h0000_0000, 32'h0000_1000, 32'h0000_2000, 32'h0000_3000},
    parameter [NUM_REGION*32-1:0]         REGION_SIZE       = {NUM_REGION{32'd8}}
) (    
    // -- Global 
    input                               clk,
    input                               rst_n,
    // -- -- AW channel         
    input   [ATX_ID_W-1:0]              s_awid_i,
    input   [ATX_ADDR_W-1:0]            s_awaddr_i,
    input   [1:0]                       s_awburst_i,        
    input   [ATX_LEN_W-1:0]             s_awlen_i,
    input                               s_awvalid_i,
    output                              s_awready_o,
    // -- -- W channel          
    input   [ATX_DATA_W-1:0]            s_wdata_i,
    input                               s_wlast_i,
    input                               s_wvalid_i,
    output                              s_wready_o,
    // -- -- B channel          
    output  [ATX_ID_W-1:0]              s_bid_o,
    output  [ATX_RESP_W-1:0]            s_bresp_o,
    output                              s_bvalid_o,
    input                               s_bready_i,
    // -- -- AR channel         
    input   [ATX_ID_W-1:0]              s_arid_i,
    input   [ATX_ADDR_W-1:0]            s_araddr_i,
    input   [1:0]                       s_arburst_i,
    input   [ATX_LEN_W-1:0]             s_arlen_i,
    input                               s_arvalid_i,
    output                              s_arready_o,
    // -- -- R channel          
    output  [ATX_ID_W-1:0]              s_rid_o,
    output  [ATX_DATA_W-1:0]            s_rdata_o,
    output  [ATX_RESP_W-1:0]            s_rresp_o,
    output                              s_rlast_o,
    output                              s_rvalid_o,
    input                               s_rready_i,
    
    // -- -- AW channel         
    output  [ATX_ID_W-1:0]              m_awid,
    output  [ATX_ADDR_W-1:0]            m_awaddr,
    output  [1:0]                       m_awburst,        
    output  [ATX_LEN_W-1:0]             m_awlen,
    output  [NUM_REGION-1:0]            m_awvalid,
    input   [NUM_REGION-1:0]            m_awready,
    // -- -- W channel          
    output  [ATX_DATA_W-1:0]            m_wdata,
    output                              m_wlast,
    output  [NUM_REGION-1:0]            m_wvalid,
    input   [NUM_REGION-1:0]            m_wready,
    // -- -- B channel          
    input   [NUM_REGION*ATX_ID_W-1:0]   m_bid,
    input   [NUM_REGION*ATX_RESP_W-1:0] m_bresp,
    input   [NUM_REGION-1:0]            m_bvalid,
    output  [NUM_REGION-1:0]            m_bready,
    // -- -- AR channel         
    output  [ATX_ID_W-1:0]              m_arid,
    output  [ATX_ADDR_W-1:0]            m_araddr,
    output  [1:0]                       m_arburst,
    output  [ATX_LEN_W-1:0]             m_arlen,
    output  [NUM_REGION-1:0]            m_arvalid,
    input   [NUM_REGION-1:0]            m_arready,
    // -- -- R channel          
    input   [NUM_REGION*ATX_ID_W-1:0]   m_rid,
    input   [NUM_REGION*ATX_DATA_W-1:0] m_rdata,
    input   [NUM_REGION*ATX_RESP_W-1:0] m_rresp,
    input   [NUM_REGION-1:0]            m_rlast,
    input   [NUM_REGION-1:0]            m_rvalid,
    output  [NUM_REGION-1:0]            m_rready
);
    // Module instantiation
generate
if(NUM_REGION > 1) begin : MULT_REGION_GEN
    // -- Write channel
    amem_dsp_write #(
        .ATX_DATA_W     (ATX_DATA_W),
        .ATX_ADDR_W     (ATX_ADDR_W),
        .ATX_ID_W       (ATX_ID_W),
        .ATX_LEN_W      (ATX_LEN_W),
        .ATX_SIZE_W     (ATX_SIZE_W),
        .ATX_RESP_W     (ATX_RESP_W),
        .ATX_OUSTD_NUM  (ATX_OUSTD_NUM),
        .MEM_BASE_ADDR  (MEM_BASE_ADDR),
        .NUM_REGION     (NUM_REGION),
        .REGION_BASE_ADDR(REGION_BASE_ADDR),
        .REGION_SIZE    (REGION_SIZE)
    ) dsp_wr (
        .clk            (clk),
        .rst_n          (rst_n),
        .s_awid_i       (s_awid_i),
        .s_awaddr_i     (s_awaddr_i),
        .s_awburst_i    (s_awburst_i),
        .s_awlen_i      (s_awlen_i),
        .s_awvalid_i    (s_awvalid_i),
        .s_awready_o    (s_awready_o),
        .s_wdata_i      (s_wdata_i),
        .s_wlast_i      (s_wlast_i),
        .s_wvalid_i     (s_wvalid_i),
        .s_wready_o     (s_wready_o),
        .s_bid_o        (s_bid_o),
        .s_bresp_o      (s_bresp_o),
        .s_bvalid_o     (s_bvalid_o),
        .s_bready_i     (s_bready_i),
        .m_awid         (m_awid),
        .m_awaddr       (m_awaddr),
        .m_awburst      (m_awburst),
        .m_awlen        (m_awlen),
        .m_awvalid      (m_awvalid),
        .m_awready      (m_awready),
        .m_wdata        (m_wdata),
        .m_wlast        (m_wlast),
        .m_wvalid       (m_wvalid),
        .m_wready       (m_wready),
        .m_bid          (m_bid),
        .m_bresp        (m_bresp),
        .m_bvalid       (m_bvalid),
        .m_bready       (m_bready)
    );  
    // -- Read channel
    amem_dsp_read #(
        .ATX_DATA_W     (ATX_DATA_W),
        .ATX_ADDR_W     (ATX_ADDR_W),
        .ATX_ID_W       (ATX_ID_W),
        .ATX_LEN_W      (ATX_LEN_W),
        .ATX_SIZE_W     (ATX_SIZE_W),
        .ATX_RESP_W     (ATX_RESP_W),
        .ATX_OUSTD_NUM  (ATX_OUSTD_NUM),
        .MEM_BASE_ADDR  (MEM_BASE_ADDR),
        .NUM_REGION     (NUM_REGION),
        .REGION_BASE_ADDR(REGION_BASE_ADDR),
        .REGION_SIZE    (REGION_SIZE)
    ) dsp_rd (
        .clk            (clk),
        .rst_n          (rst_n),
        .s_arid_i       (s_arid_i),
        .s_araddr_i     (s_araddr_i),
        .s_arburst_i    (s_arburst_i),
        .s_arlen_i      (s_arlen_i),
        .s_arvalid_i    (s_arvalid_i),
        .s_arready_o    (s_arready_o),
        .s_rid_o        (s_rid_o),
        .s_rdata_o      (s_rdata_o),
        .s_rresp_o      (s_rresp_o),
        .s_rlast_o      (s_rlast_o),
        .s_rvalid_o     (s_rvalid_o),
        .s_rready_i     (s_rready_i),
        .m_arid         (m_arid),
        .m_araddr       (m_araddr),
        .m_arburst      (m_arburst),
        .m_arlen        (m_arlen),
        .m_arvalid      (m_arvalid),
        .m_arready      (m_arready),
        .m_rid          (m_rid),
        .m_rdata        (m_rdata),
        .m_rresp        (m_rresp),
        .m_rlast        (m_rlast),
        .m_rvalid       (m_rvalid),
        .m_rready       (m_rready)
    );
end
else begin : SINGLE_REGION_GEN
    // Bypass
    assign m_awid       = s_awid_i;
    assign m_awaddr     = s_awaddr_i;
    assign m_awburst    = s_awburst_i;
    assign m_awlen      = s_awlen_i;
    assign m_awvalid[0] = s_awvalid_i;
    assign s_awready_o  = m_awready[0];

    assign m_wdata      = s_wdata_i;
    assign m_wlast      = s_wlast_i;
    assign m_wvalid[0]  = s_wvalid_i;
    assign s_wready_o   = m_wready[0];

    assign s_bid_o      = m_bid;
    assign s_bresp_o    = m_bresp;
    assign s_bvalid_o   = m_bvalid[0];
    assign m_bready[0]  = s_bready_i;

    assign m_arid       = s_arid_i;
    assign m_araddr     = s_araddr_i;
    assign m_arburst    = s_arburst_i;
    assign m_arlen      = s_arlen_i;
    assign m_arvalid[0] = s_arvalid_i;
    assign s_arready_o  = m_arready[0];

    assign s_rid_o      = m_rid;
    assign s_rdata_o    = m_rdata;
    assign s_rresp_o    = m_rresp;
    assign s_rlast_o    = m_rlast;
    assign s_rvalid_o   = m_rvalid[0];
    assign m_rready[0]  = s_rready_i;
end
endgenerate
endmodule