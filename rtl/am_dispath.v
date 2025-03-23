module am_dispath #(
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
    parameter MEM_SIZE          = 1<<MEM_ADDR_W,    // Memory size
    parameter MEM_LATENCY       = 1,                // Memory latency
    parameter MEM_INIT_FILE     = "",               // Initial value in Memory
    // Memory region 
    parameter NUM_REGION       = 1,
    parameter [NUM_REGION*ATX_ADDR_W-1:0] REGION_BASE_ADDR  = {NUM_REGION{MEM_BASE_ADDR}},
    parameter [NUM_REGION*32-1:0]         REGION_SIZE       = {NUM_REGION{32'd0}},
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
    input                               s_rready_i
    
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
    
endmodule