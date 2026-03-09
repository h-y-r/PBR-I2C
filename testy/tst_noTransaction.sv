`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.dv_i2c.i2c_cfg
`define TRANS testbench.test_tr
module tst_noTransaction;

// Deklaracje zmiennych
bit TARGET_START = 1;
bit FREE_BUS;

event assert_chk_freeBusIsHigh;
event assert_chk_targetDoesNotGenerateStart;

initial begin
	RAND = new();
	if (!RAND.randomize()) begin
	$error("blad");
	end
	DRIVER.HIGH_PERIOD_SCL = RAND.high_period;
	DRIVER.LOW_PERIOD_SCL  = RAND.low_period;
	DRIVER.DATA_SETUP_TIME = RAND.setup_time;
	DRIVER.RAND_STOP_BIT = RAND.rand_bit;
	DRIVER.START_SETUP_TIME = RAND.start_setup_time;
	DRIVER.START_HOLD_TIME = RAND.start_hold_time;
	DRIVER.STOP_SETUP_TIME = RAND.stop_setup_time;
	DRIVER.DATA_HOLD_TIME = DRIVER.LOW_PERIOD_SCL - DRIVER.DATA_SETUP_TIME;	
	#100ns;
	FREE_BUS = testbench.SDA && testbench.SCL;
	-> assert_chk_freeBusIsHigh;
	
	#200us;
	-> assert_chk_targetDoesNotGenerateStart;
	$finish();
end

always @(negedge testbench.SDA) TARGET_START = 0;

always @(assert_chk_freeBusIsHigh) begin
	chk_freeBusIsHigh : assert(FREE_BUS) $display("chk_freeBusIsHigh PASSED");
						else $error("chk_freeBusIsHigh FAILED");
end

always @(assert_chk_targetDoesNotGenerateStart) begin
	chk_targetDoesNotGenerateStart : assert(TARGET_START) $display("chk_targetDoesNotGenerateStart PASSED");
									else $error("chk_targetDoesNotGenerateStart FAILED");
end

endmodule