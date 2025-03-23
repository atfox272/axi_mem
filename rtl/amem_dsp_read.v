module amem_dsp_read #(
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
    // Memory region 
    parameter NUM_REGION        = 1,
    parameter [NUM_REGION*ATX_ADDR_W-1:0] REGION_BASE_ADDR  = {NUM_REGION{MEM_BASE_ADDR}},
    parameter [NUM_REGION*32-1:0]         REGION_SIZE       = {NUM_REGION{32'd0}}
) (    
    // -- Global 
    input                               clk,
    input                               rst_n,
    // -- AR channel         
    input   [ATX_ID_W-1:0]              s_arid_i,
    input   [ATX_ADDR_W-1:0]            s_araddr_i,
    input   [1:0]                       s_arburst_i,
    input   [ATX_LEN_W-1:0]             s_arlen_i,
    input                               s_arvalid_i,
    output                              s_arready_o,
    // -- R channel          
    output  [ATX_ID_W-1:0]              s_rid_o,
    output  [ATX_DATA_W-1:0]            s_rdata_o,
    output  [ATX_RESP_W-1:0]            s_rresp_o,
    output                              s_rlast_o,
    output                              s_rvalid_o,
    input                               s_rready_i,
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
    // Local pararmeters
    localparam AR_INFO_W        = ATX_ID_W + ATX_ADDR_W + 2 + ATX_LEN_W;
    localparam R_INFO_W         = ATX_ID_W + ATX_DATA_W + ATX_RESP_W + 1;
    localparam NUM_REGION_IDX_W = ($clog2(NUM_REGION) > 1) ? $clog2(NUM_REGION) : 1;
    // Internal variables
    genvar region_idx;
    // Internal signal
    wire    [ATX_ID_W-1:0]          s_arid;
    wire    [ATX_ADDR_W-1:0]        s_araddr;
    wire    [1:0]                   s_arburst;        
    wire    [ATX_LEN_W-1:0]         s_arlen;
    wire                            s_arvalid;
    wire                            s_arready;
    wire                            s_arvalid_flt;
    wire                            s_arready_flt;
    wire    [NUM_REGION-1:0]        ar_region_map;
    
    wire    [ATX_ID_W-1:0]          m_rid_dist      [0:NUM_REGION-1];
    wire    [ATX_DATA_W-1:0]        m_rdata_dist    [0:NUM_REGION-1];
    wire    [ATX_RESP_W-1:0]        m_rresp_dist    [0:NUM_REGION-1];
    wire    [NUM_REGION-1:0]        m_rlast_dist;
    wire    [NUM_REGION-1:0]        m_rvalid_dist;
    wire    [NUM_REGION-1:0]        m_rready_dist;
    wire    [NUM_REGION_IDX_W-1:0]  m_rvalid_map;
    // Module instantiation
    // -- AR channel
    skid_buffer #(
        .SBUF_TYPE      (5),    // Half-registered
        .DATA_WIDTH     (AR_INFO_W)
    ) s_ar_sb (
        .clk            (clk),
        .rst_n          (rst_n),
        .bwd_data_i     ({s_arid_i, s_araddr_i, s_arburst_i, s_arlen_i}),
        .bwd_valid_i    (s_arvalid_i),
        .bwd_ready_o    (s_arready_o),
        .fwd_data_o     ({s_arid,   s_araddr,   s_arburst,   s_arlen}),
        .fwd_valid_o    (s_arvalid),
        .fwd_ready_i    (s_arready)
    );
    // -- R channel
generate
for(region_idx = 0; region_idx < NUM_REGION; region_idx = region_idx + 1) begin : R_SB_GEN
    skid_buffer #(
        .SBUF_TYPE      (4),    // Bypass
        .DATA_WIDTH     (R_INFO_W)
    ) s_r_sb (
        .clk            (clk),
        .rst_n          (rst_n),
        .bwd_data_i     ({m_rid[(region_idx+1)*ATX_ID_W-1-:ATX_ID_W],   m_rdata[(region_idx+1)*ATX_DATA_W-1-:ATX_DATA_W],   m_rresp[(region_idx+1)*ATX_RESP_W-1-:ATX_RESP_W],   m_rlast[region_idx]}),
        .bwd_valid_i    (m_rvalid[region_idx]),
        .bwd_ready_o    (m_rready[region_idx]),
        .fwd_data_o     ({m_rid_dist[region_idx],                       m_rdata_dist[region_idx],                           m_rresp_dist[region_idx],                           m_rlast_dist[region_idx]}),
        .fwd_valid_o    (m_rvalid_dist[region_idx]),
        .fwd_ready_i    (m_rready_dist[region_idx])
    );
end
if(NUM_REGION > 1) begin : MULT_REGION
    priority_encoder #(
        .INPUT_W        (NUM_REGION)
    ) r_mapper (
        .i              (m_rvalid_dist),
        .o              (m_rvalid_map)
    );
end
else begin : SINGLE_REGION
    assign m_rvalid_map = 1'b0;
end
endgenerate
    // Combinational logic
    // AR channel
    assign m_arid           = s_arid;
    assign m_araddr         = s_araddr;
    assign m_arburst        = s_arburst;
    assign m_arlen          = s_arlen;
    assign m_arvalid        = s_arvalid_flt;
    assign s_arready_flt    = |(m_arready & ar_region_map); // "|(m_arready & ar_region_map)": mapped arready is valid 
    assign s_arvalid_flt    = s_arvalid & s_arready_flt;
generate
for(region_idx = 0; region_idx < NUM_REGION; region_idx = region_idx + 1) begin : REIGON_MAP_GEN
    // ar_region_map == 1 when (s_addr >= base_addr) && (s_addr < (base_addr + size)) 
    assign ar_region_map[region_idx] = (s_araddr >= REGION_BASE_ADDR[(region_idx+1)*ATX_ADDR_W-1-:ATX_ADDR_W]) && 
                                       (s_araddr < (REGION_BASE_ADDR[(region_idx+1)*ATX_ADDR_W-1-:ATX_ADDR_W] + REGION_SIZE[(region_idx+1)*32-1-:32]));
end
endgenerate
    // R channel
    assign s_rid_o          = m_rid[m_rvalid_map];
    assign s_rdata_o        = m_rdata[m_rvalid_map];
    assign s_rlast_o        = m_rlast[m_rvalid_map];
    assign s_rresp_o        = m_rresp[m_rvalid_map];
    assign s_rvalid_o       = m_rvalid[m_rvalid_map];
generate
for(region_idx = 0; region_idx < NUM_REGION; region_idx = region_idx + 1) begin : M_RREADY_GEN
    assign m_rready[region_idx] = s_rready_i & (region_idx == m_rvalid_map);
end
endgenerate
endmodule
