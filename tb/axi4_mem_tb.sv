`timescale 1ns/1ps

`define DUT_CLK_PERIOD  2
`define RST_DLY_START   3
`define RST_DUR         9

// `define CONF_MODE_ONLY
// `define WR_ST_MODE
// `define RD_ST_MODE 
// `define CUSTOMIZE_MODE

/*  Monitor enable  */ 
`define MONITOR_AW_CHANNEl
// `define MONITOR_W_CHANNEl
`define MONITOR_B_CHANNEl
// `define MONITOR_AR_CHANNEl
// `define MONITOR_R_CHANNEl

`define END_TIME        1000

// Slave device physical timing simulation
`define SLV_DVC_LATENCY 2 // Time unit

module axi4_mem_tb;
    // AXI4 BUS 
    parameter ATX_DATA_W        = 256;
    parameter ATX_ADDR_W        = 32;
    parameter ATX_ID_W          = 5;
    parameter ATX_LEN_W         = 8;
    parameter ATX_SIZE_W        = 3;
    parameter ATX_RESP_W        = 2;
    parameter ATX_OUSTD_NUM     = 1; // Number of outstanding AXI transactions
    // Memory
    parameter MEM_BASE_ADDR     = 32'h0000_0000;    // Address mapping - BASE
    parameter MEM_OFFSET        = 1;                // Address mapping - OFFSET ---> Address (word-access) = (base + offset*n)
    parameter MEM_DATA_W        = ATX_DATA_W;       // Memory's data width
    parameter MEM_ADDR_W        = 8;                // Memory's address width
    parameter MEM_LATENCY       = 1;                // Memory latency
    parameter MEM_INIT_FILE     = "";               // Initial value in Memory
    // Memory region
    parameter NUM_REGION        = 4;
    parameter [NUM_REGION*ATX_ADDR_W-1:0] REGION_BASE_ADDR  = {32'h2300_0000,   32'h2200_0000,  32'h2100_0000,  32'h2000_0000};
    parameter [NUM_REGION*32-1:0]         REGION_SIZE       = {32'd32,          32'd16,         32'h4,          32'd128};

    // Input declaration
    // -- Global 
    logic                           clk;
    logic                           rst_n;
    logic   [ATX_ID_W-1:0]          s_awid_i;
    logic   [ATX_ADDR_W-1:0]        s_awaddr_i;
    logic   [1:0]                   s_awburst_i;        
    logic   [ATX_LEN_W-1:0]         s_awlen_i;
    logic                           s_awvalid_i;
    logic                           s_awready_o;
    logic   [ATX_DATA_W-1:0]        s_wdata_i;
    logic                           s_wlast_i;
    logic                           s_wvalid_i;
    logic                           s_wready_o;
    logic   [ATX_ID_W-1:0]          s_bid_o;
    logic   [ATX_RESP_W-1:0]        s_bresp_o;
    logic                           s_bvalid_o;
    logic                           s_bready_i;
    logic   [ATX_ID_W-1:0]          s_arid_i;
    logic   [ATX_ADDR_W-1:0]        s_araddr_i;
    logic   [1:0]                   s_arburst_i;
    logic   [ATX_LEN_W-1:0]         s_arlen_i;
    logic                           s_arvalid_i;
    logic                           s_arready_o;
    logic   [ATX_ID_W-1:0]          s_rid_o;
    logic   [ATX_DATA_W-1:0]        s_rdata_o;
    logic   [ATX_RESP_W-1:0]        s_rresp_o;
    logic                           s_rlast_o;
    logic                           s_rvalid_o;
    logic                           s_rready_i;

    genvar i;
    int idx;

    int B_cnt;
    int R_cnt;
    int R_tx_cnt;

    // Instantiate the DUT
    axi4_mem #(
        .ATX_DATA_W             (ATX_DATA_W),
        .ATX_ADDR_W             (ATX_ADDR_W),
        .ATX_ID_W               (ATX_ID_W),
        .ATX_LEN_W              (ATX_LEN_W),
        .ATX_SIZE_W             (ATX_SIZE_W),
        .ATX_RESP_W             (ATX_RESP_W),
        .ATX_OUSTD_NUM          (ATX_OUSTD_NUM),
        .MEM_BASE_ADDR          (MEM_BASE_ADDR),
        .MEM_OFFSET             (MEM_OFFSET),
        .MEM_DATA_W             (MEM_DATA_W),
        .MEM_ADDR_W             (MEM_ADDR_W),
        .MEM_LATENCY            (MEM_LATENCY),
        .MEM_INIT_FILE          (MEM_INIT_FILE),
        .NUM_REGION             (NUM_REGION),
        .REGION_BASE_ADDR       (REGION_BASE_ADDR),
        .REGION_SIZE            (REGION_SIZE)
    ) axi4_mem (
        .*
    );
    initial begin
        clk             <= 0;
        rst_n           <= 1;

        s_awid_i        <= 0;
        s_awaddr_i      <= 0;
        s_awvalid_i     <= 0;
        s_awlen_i       <= 0;
        
        s_wdata_i       <= 0;
        s_wlast_i       <= 0;
        s_wvalid_i      <= 0;
        
        s_bready_i      <= 1'b1;
        
        s_awid_i       <= 0;
        s_awaddr_i     <= 0;
        s_awvalid_i    <= 0;
        
        s_bready_i     <= 1'b1;
        
        s_arid_i       <= 0;
        s_araddr_i     <= 0;
        s_arvalid_i    <= 0;

        s_rready_i     <= 1'b1;

        #(`RST_DLY_START)   rst_n <= 0;
        #(`RST_DUR)         rst_n <= 1;
    end
    
    initial begin
        forever #(`DUT_CLK_PERIOD/2) clk <= ~clk;
    end
    
    initial begin : SIM_END
        #`END_TIME;
        $finish;
    end

    initial begin   : SEQUENCER_DRIVER
        #(`RST_DLY_START + `RST_DUR + 1);
        fork 
            begin   : AW_chn
                // Wrong mapping
                s_aw_transfer(.s_awid(5'h00), .s_awaddr(32'h3000_0000), .s_awburst(2'b00), .s_awlen(8'd01));
                // 1st: Request for TX_DATA
                s_aw_transfer(.s_awid(5'h01), .s_awaddr(32'h2100_0001), .s_awburst(2'b01), .s_awlen(8'd06));
                // 2nd: Request for CONF_REG 
                s_aw_transfer(.s_awid(5'h02), .s_awaddr(32'h2000_0000), .s_awburst(2'b01), .s_awlen(8'd03));
                // 3th: Request for TX_DATA 
                s_aw_transfer(.s_awid(5'h03), .s_awaddr(32'h2100_0002), .s_awburst(2'b01), .s_awlen(8'd05));
                // 4th: Request for CONF_REG 
                s_aw_transfer(.s_awid(5'h04), .s_awaddr(32'h2000_0002), .s_awburst(2'b01), .s_awlen(8'd05));
                // 5th: Request for MEM 
                s_aw_transfer(.s_awid(5'h05), .s_awaddr(32'h2300_0002), .s_awburst(2'b01), .s_awlen(8'd05));
                aclk_cl;
                s_awvalid_i <= 1'b0;
            end
            begin   : W_chn
                // Wrong mapping
                s_w_transfer(.s_wdata(32'h08), .s_wlast(1'b0)); 
                s_w_transfer(.s_wdata(32'h08), .s_wlast(1'b1));  
                // 1st
                s_w_transfer(.s_wdata(32'h11), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(32'h12), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(32'h13), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(32'h14), .s_wlast(1'b0));   
                s_w_transfer(.s_wdata(32'h15), .s_wlast(1'b0));   
                s_w_transfer(.s_wdata(32'h16), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(32'h17), .s_wlast(1'b1));
                // 2nd
                s_w_transfer(.s_wdata(8'h00), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h01), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h02), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h03), .s_wlast(1'b1));
                // 3th
                s_w_transfer(.s_wdata(8'h1A), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h1A), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h1A), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h1A), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h1A), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h1A), .s_wlast(1'b1));
                // 4th
                s_w_transfer(.s_wdata(8'h02), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h03), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h04), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h05), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h06), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h07), .s_wlast(1'b1));
                // 5th
                s_w_transfer(.s_wdata(8'h32), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h33), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h34), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h35), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h36), .s_wlast(1'b0));
                s_w_transfer(.s_wdata(8'h37), .s_wlast(1'b1));
                aclk_cl;
                s_wvalid_i <= 1'b0;
            end
            begin   : AR_chn
                repeat(40) aclk_cl;

                // 0th: Request for Wrong address
                s_ar_transfer(.s_arid(5'h1f), .s_araddr(32'h3200_0001), .s_arburst(2'b00), .s_arlen(8'd02));
                // 1st: Request for RX_DATA[1]
                s_ar_transfer(.s_arid(5'h03), .s_araddr(32'h2300_0001), .s_arburst(2'b01), .s_arlen(8'd03));
                aclk_cl;
                s_arvalid_i <= 1'b0;
                
                repeat(30) aclk_cl;

                // 2nd: Request for RX_DATA[0]
                s_ar_transfer(.s_arid(5'h01), .s_araddr(32'h2100_0000), .s_arburst(2'b01), .s_arlen(8'd05));
                // 3rd: Request for MEM
                s_ar_transfer(.s_arid(5'h00), .s_araddr(32'h2000_0000), .s_arburst(2'b01), .s_arlen(8'd08));
                // 4th: Request for MEM
                s_ar_transfer(.s_arid(5'h01), .s_araddr(32'h2100_0003), .s_arburst(2'b01), .s_arlen(8'd05));
                aclk_cl;
                s_arvalid_i <= 1'b0;

                repeat(30) aclk_cl;
            end
            begin: R_chn
                int cnt;
                repeat(40) aclk_cl;

                // TODO: monitor the response data
                while(1'b1) begin
                    s_rready_i <= 1'b1;
                    wait(s_rready_i & s_rvalid_o); #0.1;  // R hanshaking
                    aclk_cl;
                    if(cnt == 1) begin
                        cnt = 0;
                        s_rready_i <= 1'b0;
                        aclk_cl;
                    end
                    else begin
                        cnt++;
                    end
                end
            end
        join_none
    end


    /*          AXI4 monitor            */
    initial begin   : AXI4_MONITOR
        #(`RST_DLY_START + `RST_DUR + 1);
        fork 
`ifdef MONITOR_AW_CHANNEl
            begin   : AW_chn
                while(1'b1) begin
                    wait(s_awready_o & s_awvalid_i); #0.1;  // AW hanshaking
                    $display("\n---------- AW channel ----------");
                    $display("AWID:     0x%8h", s_awid_i);
                    $display("AWADDR:   0x%8h", s_awaddr_i);
                    $display("AWLEN:    0x%8h", s_awlen_i);
                    $display("-------------------------------");
                    aclk_cl;  aclk_hcl;
                end
            end
`endif
`ifdef MONITOR_W_CHANNEl
            begin   : W_chn
                while(1'b1) begin
                    wait(s_wready_o & s_wvalid_i); #0.1;  // W hanshaking
                    $display("\n---------- W channel ----------");
                    $display("WDATA:    0x%8h", s_wdata_i);
                    $display("WLAST:    0x%8h", s_wlast_i);
                    $display("-------------------------------");
                    aclk_cl;  aclk_hcl;
                end
            end
`endif
`ifdef MONITOR_B_CHANNEl
            begin   : B_chn
                B_cnt = 0;
                while(1'b1) begin
                    aclk_hcl;
                    wait(s_bready_i & s_bvalid_o); #0.1;  // B hanshaking
                    $display("\n\t\t\t\t\t\t\t\t\t\t\t\t---------- B channel [%1d] ----------", B_cnt);
                    $display("\t\t\t\t\t\t\t\t\t\t\t\tBID:      0x%8h", s_bid_o);
                    $display("\t\t\t\t\t\t\t\t\t\t\t\tBRESP:    0x%8h", s_bresp_o);
                    $display("\t\t\t\t\t\t\t\t\t\t\t\t---------------------------------------");
                    B_cnt++;
                    aclk_cl;
                end
            end
`endif
`ifdef MONITOR_AR_CHANNEl
            begin   : AR_chn
                while(1'b1) begin
                    #0.1;
                    wait(s_arready_o & s_arvalid_i); #0.1;  // AR hanshaking
                    $display("\n---------- AR channel ----------");
                    $display("ARID:     0x%8h", s_arid_i);
                    $display("ARADDR:   0x%8h", s_araddr_i);
                    $display("ARLEN:    0x%8h", s_arlen_i);
                    $display("-------------------------------");
                    aclk_cl; aclk_hcl;
                end
            end
`endif
`ifdef MONITOR_R_CHANNEl
            begin   : R_chn
                R_cnt = 0;
                R_tx_cnt = 0;
                while(1'b1) begin
                    aclk_hcl;
                    wait(s_rready_i & s_rvalid_o); #0.1;  // R hanshaking
                    $display("\n\t\t\t\t\t\t\t\t\t\t\t\t---------- R channel [%1d][%1d] ----------", R_tx_cnt, R_cnt);
                    $display("\t\t\t\t\t\t\t\t\t\t\t\tRID:      0x%8h", s_rid_o);
                    $display("\t\t\t\t\t\t\t\t\t\t\t\tRDATA:    0x%8h", s_rdata_o);
                    $display("\t\t\t\t\t\t\t\t\t\t\t\tRRESP:    0x%8h", s_rresp_o);
                    $display("\t\t\t\t\t\t\t\t\t\t\t\tRLAST:    0x%8h", s_rlast_o);
                    $display("\t\t\t\t\t\t\t\t\t\t\t\t--------------------------------------------");
                    R_cnt++;
                    if(s_rlast_o) begin
                        R_cnt = 0;   
                        R_tx_cnt++;
                    end
                    aclk_cl;
                end
            end
`endif
        join_none
    end
    /*          AXI4 monitor            */

   /* DeepCode */
    task automatic s_aw_transfer(
        input [ATX_ID_W-1:0]    s_awid,
        input [ATX_ADDR_W-1:0]  s_awaddr,
        input [1:0]             s_awburst,
        input [ATX_LEN_W-1:0]   s_awlen
    );
        aclk_cl;
        s_awid_i            <= s_awid;
        s_awaddr_i          <= s_awaddr;
        s_awburst_i         <= s_awburst;
        s_awlen_i           <= s_awlen;
        s_awvalid_i         <= 1'b1;
        // Handshake occur
        wait(s_awready_o == 1'b1); #0.1;
    endtask

    task automatic s_w_transfer (
        input [ATX_DATA_W-1:0]  s_wdata,
        input                   s_wlast
    );
        aclk_cl;
        s_wdata_i           <= s_wdata;
        s_wvalid_i          <= 1'b1;
        s_wlast_i           <= s_wlast;
        // Handshake occur
        wait(s_wready_o == 1'b1); #0.1;
    endtask

    task automatic s_ar_transfer(
        input [ATX_ID_W-1:0]    s_arid,
        input [ATX_ADDR_W-1:0]  s_araddr,
        input [1:0]             s_arburst,
        input [ATX_LEN_W-1:0]   s_arlen
    );
        aclk_cl;
        s_arid_i            <= s_arid;
        s_araddr_i          <= s_araddr;
        s_arburst_i         <= s_arburst;
        s_arlen_i           <= s_arlen;
        s_arvalid_i         <= 1'b1;
        // Handshake occur
        wait(s_arready_o == 1'b1); #0.1;
    endtask


    task automatic aclk_cl;
        @(posedge clk);
        #0.2; 
    endtask
    task automatic aclk_hcl;    // Half cycle
        @(clk);
        #0.2; 
    endtask
endmodule