`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.i2c_cfg
`define TRANS testbench.test_tr
module tst_noTransaction;

// Deklaracje zmiennych
bit TARGET_START = 1;
bit FREE_BUS;

event assert_chk_freeBusIsHigh;
event assert_chk_targetDoesNotGenerateStart;

parameter int NUM_TRANSACTIONS = 20;

initial begin
	`RAND = new();
	if (!`RAND.randomize()) begin
	$error("blad");
	end
	`DRIVER.HIGH_PERIOD_SCL = `RAND.high_period;
	`DRIVER.LOW_PERIOD_SCL  = `RAND.low_period;
	`DRIVER.DATA_SETUP_TIME = `RAND.setup_time;
	`DRIVER.RAND_STOP_BIT = `RAND.rand_bit;
	`DRIVER.START_SETUP_TIME = `RAND.start_setup_time;
	`DRIVER.START_HOLD_TIME = `RAND.start_hold_time;
	`DRIVER.STOP_SETUP_TIME = `RAND.stop_setup_time;
	`DRIVER.DATA_HOLD_TIME = `DRIVER.LOW_PERIOD_SCL - `DRIVER.DATA_SETUP_TIME;	
	#100ns;

	for (int i = 0; i < NUM_TRANSACTIONS; i++) begin
		FREE_BUS = 1;
		TARGET_START = 1;
		#100ns;
		-> assert_chk_freeBusIsHigh;
		-> assert_chk_targetDoesNotGenerateStart;
	end

	$finish();
end

always @(negedge testbench.SDA) begin 
	TARGET_START = 0;
	FREE_BUS = 0;
end

always @(negedge testbench.SCL) begin 
	FREE_BUS = 0;
end

always @(assert_chk_freeBusIsHigh) begin
	chk_freeBusIsHigh : assert(FREE_BUS) $display("chk_freeBusIsHigh PASSED");
						else $error("chk_freeBusIsHigh FAILED");
end

always @(assert_chk_targetDoesNotGenerateStart) begin
	chk_targetDoesNotGenerateStart : assert(TARGET_START) $display("chk_targetDoesNotGenerateStart PASSED");
									else $error("chk_targetDoesNotGenerateStart FAILED");
end

endmodule