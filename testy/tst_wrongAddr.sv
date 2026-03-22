`define DRIVER testbench.dv_i2c
`define TARGET testbench.tg_i2c
`define MAIL testbench.dv_i2c.tr_mailbox
`define RAND testbench.dv_i2c.i2c_cfg
`define TRANS testbench.test_tr
module tst_wrongAddr;

// Deklaracje zmiennych

property NACK_AFTER_WRONG_ADDR;
	@(posedge testbench.SCL)
	(`DRIVER.phase == M_ADDR) && (`DRIVER.bit_idx == BIT_ACK) && (`DRIVER.curr_addr != `TARGET.ADDR_TARGET)
	|->
	(`DRIVER.ack_got == 1'b0)
endproperty	

initial begin
	Transaction tr_addr;

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
	tr_addr = new(
        .address(7'b0011111), 
        .rw(0), 
        .data({8'b00000001})
    );

	`MAIL.put(tr_write);
	
	#25us;
	$finish();
end

chk_nackAfterWrongAddr: assert property (NACK_AFTER_WRONG_ADDR) $display("chk_nackAfterWrongAddr PASSED!");
						else $error("chk_nackAfterWrongAddr FAILED!");

endmodule