module am_dsp_write #(
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
);  
    // Local pararmeters
    localparam AW_INFO_W = ATX_ID_W + ATX_ADDR_W + 2 + ATX_LEN_W;
    localparam W_INFO_W  = ATX_DATA_W + 1;
    localparam B_INFO_W  = ATX_ID_W + ATX_RESP_W;
    // Internal variables
    genvar region_idx;
    // Internal signal
    wire    [ATX_ID_W-1:0]          s_awid;
    wire    [ATX_ADDR_W-1:0]        s_awaddr;
    wire    [1:0]                   s_awburst;        
    wire    [ATX_LEN_W-1:0]         s_awlen;
    wire                            s_awvalid;
    wire                            s_awready;
    wire                            s_awvalid_flt;
    wire                            s_awready_flt;
    wire    [NUM_REGION-1:0]        aw_region_map;
    wire                            aw_order_wready;
    wire    [NUM_REGION-1:0]        w_region_map;
    wire                            w_order_rready;
    wire                            w_order_rvalid;

    
    wire    [ATX_DATA_W-1:0]        s_wdata;
    wire                            s_wlast;
    wire                            s_wvalid;
    wire                            s_wready;
    
    wire    [ATX_ID_W-1:0]          m_bid_dist      [0:NUM_REGION-1];
    wire    [ATX_RESP_W-1:0]        m_bresp_dist    [0:NUM_REGION-1];
    wire                            m_bvalid_dist   [0:NUM_REGION-1];
    wire                            m_bready_dist   [0:NUM_REGION-1];

    // Module instantiation
    // -- AW channel
    skid_buffer #(
        .SBUF_TYPE      (5),    // Half-registered
        .DATA_WIDTH     (AW_INFO_W)
    ) s_aw_sb (
        .clk            (clk),
        .rst_n          (rst_n),
        .bwd_data_i     ({s_awid_i, s_awaddr_i, s_awburst_i, s_awlen_i}),
        .bwd_valid_i    (s_awvalid_i),
        .bwd_ready_o    (s_awready_o),
        .fwd_data_o     ({s_awid,   s_awaddr,   s_awburst,   s_awlen}),
        .fwd_valid_o    (s_awvalid),
        .fwd_ready_i    (s_awready)
    );
    sync_fifo #(
        .FIFO_TYPE      (1),    // Norma;
        .DATA_WIDTH     (NUM_REGION),
        .FIFO_DEPTH     (ATX_OUSTD_NUM),
    ) s_aw_order (
        .clk            (clk),
        .data_i         (aw_region_map),
        .wr_valid_i     (s_awvalid_flt),
        .wr_ready_o     (aw_order_wready),
        .data_o         (w_region_map),
        .rd_ready_o     (w_order_rready),
        .rd_valid_i     (w_order_rvalid),
        .empty_o        (),
        .full_o         (),
        .almost_empty_o (),
        .almost_full_o  (),
        .counter        (),
        .rst_n          (rst_n)
    );
    // -- W channel
    skid_buffer #(
        .SBUF_TYPE      (5),    // Half-registered
        .DATA_WIDTH     (W_INFO_W)
    ) s_w_sb (
        .clk            (clk),
        .rst_n          (rst_n),
        .bwd_data_i     ({m_bid, m_bresp}),
        .bwd_valid_i    (m_bvalid),
        .bwd_ready_o    (m_bready),
        .fwd_data_o     ({s_wdata,   s_wlast}),
        .fwd_valid_o    (s_wvalid),
        .fwd_ready_i    (s_wready)
    );
    // -- B channel
generate
for(region_idx = 0; region_idx < NUM_REGION; region_idx = region_idx + 1) begin : B_SB_GEN
    skid_buffer #(
        .SBUF_TYPE      (4),    // Bypass
        .DATA_WIDTH     (B_INFO_W)
    ) s_b_sb (
        .clk            (clk),
        .rst_n          (rst_n),
        .bwd_data_i     ({m_bid[(region_idx+1)*ATX_ID_W-1-:ATX_ID_W],   m_bresp[(region_idx+1)*ATX_RESP_W-1-:ATX_RESP_W]}),
        .bwd_valid_i    (m_bvalid[region_idx]),
        .bwd_ready_o    (m_bready[region_idx]),
        .fwd_data_o     ({m_bid_dist[region_idx],                       m_bresp_dist[region_idx]}),
        .fwd_valid_o    (m_bvalid_dist[region_idx]),
        .fwd_ready_i    (m_bready_dist[region_idx])
    );
end
endgenerate
    // Combinational logic
    // AW channel
    assign m_awid           = s_awid;
    assign m_awaddr         = s_awaddr;
    assign m_awburst        = s_awburst;
    assign m_awlen          = s_awlen;
    assign m_awvalid        = s_awvalid_flt;
    assign s_awready_flt    = |(m_awready & aw_region_map) & aw_order_wready; // "|(m_awready & aw_region_map)": mapped awready is valid 
    assign s_awvalid_flt    = s_awvalid & s_awready_flt;
generate
for(region_idx = 0; region_idx < NUM_REGION; region_idx = region_idx + 1) begin : REIGON_MAP_GEN
    // aw_region_map == 1 when (s_addr >= base_addr) && (s_addr < (base_addr + size)) 
    assign aw_region_map[region_idx] = (s_awaddr >= REGION_BASE_ADDR[(region_idx+1)*ATX_ADDR_W-1-:ATX_ADDR_W]) && 
                                       (s_awaddr < (REGION_BASE_ADDR[(region_idx+1)*ATX_ADDR_W-1-:ATX_ADDR_W] + REGION_SIZE[(region_idx+1)*32-1-:32]));
end
endgenerate
    // W channel
    assign m_wdata          = s_wdata;
    assign m_wlast          = s_wlast;
    assign m_wvalid         = {NUM_REGION{w_order_rready & s_wvalid}} & w_region_map; // Mask the corresponding m_wvalid bit
    assign s_wready         = m_wready & m_wvalid; // Mask the corresponding m_wready bit by using bit mask in m_wvalid
    assign w_order_rvalid   = s_wready & s_wlast;
    // B channel

endmodule